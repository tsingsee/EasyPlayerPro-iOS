
#import "PlayViewController.h"
#import <VideoToolbox/VideoToolbox.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CommonCrypto/CommonDigest.h>
#import <QuartzCore/QuartzCore.h>
#import "MBProgressHUD.h"
#import "ToolBar.h"
#import "CustomAlertView.h"

PlayViewController *pvc = nil;

@interface PlayViewController()<UIAlertViewDelegate> {
    
    NSTimer* _toolbarTimer;
    NSTimer *_fpsTimer;
    NSTimer *netSpeedTime;
    
    float speed;
    BOOL _isMediaSliderBeingDragged;
}

@property (nonatomic, strong) MBProgressHUD *startHUD;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UIButton *fullBtn;
@property (nonatomic, strong) UISlider *mediaProgressSlider;

@end

@implementation PlayViewController

#pragma mark - init

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.title = @"视频播放";
    
    self.startHUD = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    self.startHUD.label.text = @"0Kb/s";
    self.startHUD.bezelView.color = [UIColor clearColor];
    self.startHUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    self.startHUD.userInteractionEnabled = NO;
    self.startHUD.backgroundView.color = [UIColor colorWithWhite:0.f alpha:.4f];
    self.startHUD.contentColor = [UIColor whiteColor];
    self.startHUD.label.font = [UIFont systemFontOfSize:13];
    
#ifdef DEBUG
    [IJKFFMoviePlayerController setLogReport:YES];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_DEBUG];
#else
    [IJKFFMoviePlayerController setLogReport:NO];
    [IJKFFMoviePlayerController setLogLevel:k_IJK_LOG_INFO];
#endif
    
    [IJKFFMoviePlayerController checkIfFFmpegVersionMatch:YES];
    
    IJKFFOptions *options = [IJKFFOptions optionsByDefault];
    NSString *transport = [[NSUserDefaults standardUserDefaults] objectForKey:@"transport"];
    [options setFormatOptionValue:transport forKey:@"rtsp_transport"];
    [options setFormatOptionIntValue:1000000 forKey:@"analyzeduration"];    // 21s
    [options setFormatOptionIntValue:2048 forKey:@"probesize"];
//    [options setFormatOptionIntValue:204800 forKey:@"probesize"];
    [options setFormatOptionIntValue:0 forKey:@"auto_convert"];
    [options setFormatOptionIntValue:1 forKey:@"reconnect"];
    [options setFormatOptionIntValue:10 forKey:@"timeout"];
    [options setPlayerOptionIntValue:0 forKey:@"packet-buffering"];
    [options setFormatOptionValue:@"nobuffer" forKey:@"fflags"];
//    [options setFormatOptionIntValue:1 forKey:@"opensles"];
//    [options setFormatOptionIntValue:1 forKey:@"mediacodec"];
//    [options setFormatOptionIntValue:1 forKey:@"mediacodec-auto-rotate"];
//    [options setFormatOptionIntValue:1 forKey:@"mediacodec-handle-resolution-change"];
    
    // RTSP的话,iformat是rtsp,rtmp是flv,m3u8是hls
    if ([[self.urlStr substringToIndex:4] isEqualToString:@"rtmp"]) {
        [options setFormatOptionValue:@"flv" forKey:@"iformat"];
    } else if ([[self.urlStr substringToIndex:4] isEqualToString:@"m3u8"]) {
        [options setFormatOptionValue:@"hls" forKey:@"iformat"];
    } else {
        [options setFormatOptionValue:@"rtsp" forKey:@"iformat"];
    }
    
    NSURL *url = [NSURL URLWithString:self.urlStr];
    self.player = [[IJKFFMoviePlayerController alloc] initWithContentURL:url withOptions:options key:@"6468753866662B32734B77415A6E6C4E736F5A39652F4A4659584E35554778686557567955484A76567778576F4F4E373430566863336C4559584A33615735555A57467453584E55614756435A584E30514449774D54686C59584E35"];
    
    if (self.player) {
        self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.player.view.frame = self.view.bounds;
        self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
        //    self.player.shouldAutoplay = YES;
        self.view.autoresizesSubviews = YES;
        [self.view addSubview:self.player.view];
    } else {
        [[CustomAlertView shareCustimView] showWithCustomWithTitle:@"" andMessage:@"Key不合法或者已过期"];
    }
    
    _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _backBtn.frame = CGRectMake(0, Statusbar_Height, 44, 44);
    _backBtn.backgroundColor = [UIColor clearColor];
    _backBtn.showsTouchWhenHighlighted = YES;
    [_backBtn setBackgroundImage:[UIImage imageNamed:@"BackVideo"] forState:UIControlStateNormal];
    [_backBtn addTarget:self action:@selector(backBtnDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_backBtn];
    
    // bottomView
    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenHeight - TOOLBAR_HEIGHT - 80, ScreenWidth, TOOLBAR_HEIGHT + 80)];
    self.bottomView.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:self.bottomView];
    
    self.fullBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fullBtn.frame = CGRectMake(ScreenWidth - TOOLBAR_HEIGHT, 0, TOOLBAR_HEIGHT, TOOLBAR_HEIGHT);
    self.fullBtn.backgroundColor = [UIColor clearColor];
    self.fullBtn.showsTouchWhenHighlighted = YES;
    [self.fullBtn setBackgroundImage:[UIImage imageNamed:@"LandspaceVideo"] forState:UIControlStateNormal];
    [self.fullBtn setBackgroundImage:[UIImage imageNamed:@"PortraitVideo"] forState:UIControlStateSelected];
    [self.fullBtn addTarget:self action:@selector(fullBtnDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:_fullBtn];
    
    speed = 1.0;
    
    _titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth - TOOLBAR_HEIGHT, TOOLBAR_HEIGHT + 80)];
    _titleView.tag = 3001;
    
    UIButton *recordBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 40.0, 32.0, 32.0)];
    [recordBtn setImage:[UIImage imageNamed:@"ic_action_record_idle"] forState:UIControlStateNormal];
    [recordBtn setImage:[UIImage imageNamed:@"ic_action_record_active"] forState:UIControlStateSelected];
    recordBtn.tag = 6001;
    if (_isLocal) {
        recordBtn.hidden = YES;
    }
    [recordBtn addTarget:self action:@selector(handleVideo:) forControlEvents:UIControlEventTouchUpInside];
    [_titleView addSubview:recordBtn];
    
    UIButton *screenShotBtn = [[UIButton alloc] initWithFrame:CGRectMake(55, 40.0, 32.0, 32.0)];
    [screenShotBtn addTarget:self action:@selector(screenShot) forControlEvents:UIControlEventTouchUpInside];
    [screenShotBtn setImage:[UIImage imageNamed:@"ic_action_take_picture"] forState:UIControlStateNormal];
    screenShotBtn.tag = 6002;
    [_titleView addSubview:screenShotBtn];
    
    UIButton *scaleBtn = [[UIButton alloc] initWithFrame:CGRectMake(92, 40.0, 32.0, 32.0)];
    [scaleBtn setImage:[UIImage imageNamed:@"ic_action_playmode"] forState:UIControlStateNormal];
    scaleBtn.tag = 6003;
    [scaleBtn addTarget:self action:@selector(zoomEvent) forControlEvents:UIControlEventTouchUpInside];
    [_titleView addSubview:scaleBtn];
    
    UILabel *fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(130, 46.0, 70.0, 21.0)];
    fpsLabel.text = @"0FPS";
    fpsLabel.font = [UIFont systemFontOfSize:13];
    fpsLabel.textColor = [UIColor whiteColor];
    fpsLabel.tag = 4001;
    if (_isLocal) {
        fpsLabel.hidden = YES;
    }
    [_titleView addSubview:fpsLabel];
    
    UIButton *slowBtn = [[UIButton alloc] initWithFrame:CGRectMake(_titleView.frame.size.width/2 + 40, 0, 40, 30)];
    slowBtn.tag = 2001;
    [slowBtn setTitle:@"慢速" forState:UIControlStateNormal];
    slowBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [slowBtn addTarget:self action:@selector(slowPlay) forControlEvents:UIControlEventTouchUpInside];
    [_titleView addSubview:slowBtn];
    
    UIButton *fastBtn = [[UIButton alloc] initWithFrame:CGRectMake(_titleView.frame.size.width/2 + 100, 0, 40, 30)];
    fastBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [fastBtn setTitle:@"快速" forState:UIControlStateNormal];
    [fastBtn addTarget:self action:@selector(fastPlay) forControlEvents:UIControlEventTouchUpInside];
    fastBtn.tag = 2002;
    [_titleView addSubview:fastBtn];
    
    UILabel *spendLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 84, 40, 21.0)];
    spendLabel.text = @"00:00";
    spendLabel.textColor = [UIColor whiteColor];
    spendLabel.tag = 1001;
    spendLabel.font = [UIFont systemFontOfSize:12.0];
    [_titleView addSubview:spendLabel];
    
    UILabel *totalLabel = [[UILabel alloc] initWithFrame:CGRectMake(_titleView.frame.size.width - 40, 84, 40, 21.0)];
    totalLabel.text = @"00:00";
    totalLabel.textColor = [UIColor whiteColor];
    totalLabel.tag = 1002;
    totalLabel.textAlignment = NSTextAlignmentRight;
    totalLabel.font = [UIFont systemFontOfSize:12.0];
    [_titleView addSubview:totalLabel];
    
    [self refreshMediaControl];
    
    UIButton *forwardBtn = [[UIButton alloc] initWithFrame:CGRectMake(20.0, 0, 32, 32)];
    [forwardBtn setImage:[UIImage imageNamed:@"ic_media_rew"] forState:UIControlStateNormal];
    [forwardBtn addTarget:self action:@selector(forward) forControlEvents:UIControlEventTouchDown];
    forwardBtn.tag = 9001;
    [_titleView addSubview:forwardBtn];
    
    UIButton *playAndStopBtn = [[UIButton alloc] initWithFrame:CGRectMake(62.0, 0, 32, 32)];
    [playAndStopBtn setImage:[UIImage imageNamed:@"ic_media_pause"] forState:UIControlStateNormal];
    [playAndStopBtn setImage:[UIImage imageNamed:@"ic_media_play"] forState:UIControlStateSelected];
    [playAndStopBtn addTarget:self action:@selector(playAndStop:) forControlEvents:UIControlEventTouchUpInside];
    playAndStopBtn.tag = 9002;
    [_titleView addSubview:playAndStopBtn];
    
    UIButton *nextBtn = [[UIButton alloc] initWithFrame:CGRectMake(104.0, 0, 32, 32)];
    [nextBtn setImage:[UIImage imageNamed:@"ic_media_ff"] forState:UIControlStateNormal];
    [nextBtn addTarget:self action:@selector(next) forControlEvents:UIControlEventTouchDown];
    nextBtn.tag = 9003;
    [_titleView addSubview:nextBtn];
    
    [_bottomView addSubview:_titleView];
    
    _mediaProgressSlider = [[UISlider alloc] initWithFrame:CGRectMake(62.0, 93, _titleView.frame.size.width - 110, 2.0)];
    _mediaProgressSlider.tag = 8001;
    [_mediaProgressSlider addTarget:self action:@selector(beginDragMediaSlider) forControlEvents:UIControlEventTouchDown];
    [_mediaProgressSlider addTarget:self action:@selector(endDragMediaSlider) forControlEvents:UIControlEventTouchCancel];
    [_mediaProgressSlider addTarget:self action:@selector(didSliderTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [_mediaProgressSlider addTarget:self action:@selector(didSliderTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
    [_mediaProgressSlider addTarget:self action:@selector(continueDragMediaSlider) forControlEvents:UIControlEventValueChanged];
    [_titleView addSubview:_mediaProgressSlider];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    [self startfpsTimer];
    [self startSpeedTimer];
    
    pvc = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self installMovieNotificationObservers];
    [self.player prepareToPlay];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self stopSpeedTime];
    [self.startHUD hideAnimated:YES];
    if (_toolbarTimer) {
        [_toolbarTimer invalidate];
        _toolbarTimer = nil;
    }
    
    if (_fpsTimer) {
        [_fpsTimer invalidate];
        _fpsTimer = nil;
    }
    
    if (!self.isVideoSquare) {
        UIImage *temp = [self.player thumbnailImageAtCurrentTime];
        [pvc writeImage:temp toFileAtPath:pvc.imagePath];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
    [self.player shutdown];
    [self removeMovieNotificationObservers];
    [self.player.view removeFromSuperview];
    self.player = nil;
}

#pragma mark - private method

-(void)removeMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/* Register observers for the various movie object notifications. */
-(void)installMovieNotificationObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadStateDidChange:)
                                                 name:IJKMPMoviePlayerLoadStateDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:IJKMPMoviePlayerPlaybackDidFinishNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaIsPreparedToPlayDidChange:)
                                                 name:IJKMPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackStateDidChange:)
                                                 name:IJKMPMoviePlayerPlaybackStateDidChangeNotification
                                               object:_player];
}

- (void)loadStateDidChange:(NSNotification*)notification {
    IJKMPMovieLoadState loadState = _player.loadState;
    if ((loadState & IJKMPMovieLoadStatePlaythroughOK) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStatePlaythroughOK: %d\n", (int)loadState);
        [self.startHUD hideAnimated:YES];
    } else if ((loadState & IJKMPMovieLoadStateStalled) != 0) {
        NSLog(@"loadStateDidChange: IJKMPMovieLoadStateStalled: %d\n", (int)loadState);
//        [self.player stop];
//        [self.player play];
//        [self.mediaControl refreshMediaControl];
    } else {
        NSLog(@"loadStateDidChange: ???: %d\n", (int)loadState);
    }
}

- (void)stopSpeedTime {
    if (netSpeedTime) {
        [netSpeedTime invalidate];
        netSpeedTime = nil;
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification {
    int reason = [[[notification userInfo] valueForKey:IJKMPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue];
    switch (reason) {
        case IJKMPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackEnded: %d\n", reason);
            [self stopSpeedTime];
            [self.startHUD hideAnimated:YES];
            break;
        case IJKMPMovieFinishReasonUserExited:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonUserExited: %d\n", reason);
            [self stopSpeedTime];
            [self.startHUD hideAnimated:YES];
            break;
        case IJKMPMovieFinishReasonPlaybackError:
            NSLog(@"playbackStateDidChange: IJKMPMovieFinishReasonPlaybackError: %d\n", reason);
            [self stopSpeedTime];
            self.startHUD.bezelView.color = [UIColor whiteColor];
            self.startHUD.label.font = [UIFont systemFontOfSize:16];
            self.startHUD.contentColor = [UIColor darkGrayColor];
            self.startHUD.label.text = @"视频无法播放";
            self.startHUD.mode = MBProgressHUDModeText;
            break;
        default:
            NSLog(@"playbackPlayBackDidFinish: ???: %d\n", reason);
            break;
    }
}

- (void)mediaIsPreparedToPlayDidChange:(NSNotification*)notification {
    NSLog(@"mediaIsPreparedToPlayDidChange\n");
}

- (void)moviePlayBackStateDidChange:(NSNotification*)notification {
    switch (_player.playbackState) {
        case IJKMPMoviePlaybackStateStopped: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: stoped", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePlaying: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: playing", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStatePaused: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: paused", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateInterrupted: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: interrupted", (int)_player.playbackState);
            break;
        }
        case IJKMPMoviePlaybackStateSeekingForward:
        case IJKMPMoviePlaybackStateSeekingBackward: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: seeking", (int)_player.playbackState);
            break;
        }
        default: {
            NSLog(@"IJKMPMoviePlayBackStateDidChange %d: unknown", (int)_player.playbackState);
            break;
        }
    }
}

- (void)startSpeedTimer {
    if ([[NSThread currentThread] isMainThread]) {
        netSpeedTime = [NSTimer scheduledTimerWithTimeInterval:.5f
                                                        target:self
                                                      selector:@selector(refreshSpeedView)
                                                      userInfo:nil
                                                       repeats:YES];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startSpeedTimer];
        });
    }
}

- (void)refreshSpeedView {
//    IJKFFMoviePlayerController *player = self.player;
//    NSString *speedStr = [player transferSpeed];
//    UIView *_titleView = [_titleBar customView];
//    UILabel *speedLabel = (UILabel *)[_titleView viewWithTag:4002];
    
//    speedLabel.text = speedStr;
}

#pragma mark - click event

- (void)fullBtnDidTouch:(id)sender {
    if (!self.fullBtn.selected) {
        [UIView animateWithDuration:0.5 animations:^{
            self.view.transform =CGAffineTransformMakeRotation(M_PI_2);
            self.view.bounds = CGRectMake(0, 0, ScreenHeight, ScreenWidth);
            
            self.backBtn.frame = CGRectMake(Statusbar_Height, self.backBtn.frame.origin.y, 44, 44);
            self.bottomView.frame = CGRectMake(0, ScreenWidth - TOOLBAR_HEIGHT - 80, ScreenHeight, TOOLBAR_HEIGHT + 80);
            self.bottomView.backgroundColor = [UIColor darkGrayColor];
            
            self.titleView.frame = CGRectMake(0, 0, ScreenHeight - TOOLBAR_HEIGHT, TOOLBAR_HEIGHT + 80);
            self.mediaProgressSlider.frame = CGRectMake(122.0, 93, self.titleView.frame.size.width - 170, 2.0);
            
            UIButton *slowBtn = (UIButton *)[self.titleView viewWithTag:2001];
            slowBtn.frame = CGRectMake(self.titleView.frame.size.width - 80, 0, 40, 30);
            UIButton *fastBtn = (UIButton *)[self.titleView viewWithTag:2002];
            fastBtn.frame = CGRectMake(self.titleView.frame.size.width - 40, 0, 40, 30);
            UIButton *forwardBtn = (UIButton *)[self.titleView viewWithTag:9001];
            forwardBtn.frame = CGRectMake(self.titleView.frame.size.width/2 - 58, 0, 32, 32);
            UIButton *playAndStopBtn = (UIButton *)[self.titleView viewWithTag:9002];
            playAndStopBtn.frame = CGRectMake(self.titleView.frame.size.width/2 - 16, 0, 32, 32);
            UIButton *nextBtn = (UIButton *)[self.titleView viewWithTag:9003];
            nextBtn.frame = CGRectMake(self.titleView.frame.size.width/2 + 58, 0, 32, 32);
            UILabel *totalLabel = (UILabel *)[self.titleView viewWithTag:1002];
            totalLabel.frame = CGRectMake(self.titleView.frame.size.width - 40, 84, 40, 21.0);
            UILabel *spendLabel = (UILabel *)[self.titleView viewWithTag:1001];
            spendLabel.frame = CGRectMake(80, 84, 40, 21.0);
            
            UIButton *recordBtn = (UIButton *)[self.titleView viewWithTag:6001];
            recordBtn.frame = CGRectMake(80, 40.0, 32.0, 32.0);
            UIButton *screenShotBtn = (UIButton *)[self.titleView viewWithTag:6002];
            screenShotBtn.frame = CGRectMake(160, 40.0, 32.0, 32.0);
            UIButton *scaleBtn =(UIButton *)[self.titleView viewWithTag:6003];
            scaleBtn.frame = CGRectMake(240, 40.0, 32.0, 32.0);
            
            UILabel *fpsLabel = (UILabel *)[self.titleView viewWithTag:4001];
            fpsLabel.frame = CGRectMake(320, 46.0, 70.0, 21.0);
            
            UILabel *speedLabel = (UILabel *)[self.titleView viewWithTag:4002];
            speedLabel.frame = CGRectMake(400, 46.0, 70.0, 21.0);
            
            self.startHUD.transform = CGAffineTransformMakeRotation(M_PI_2);
            
            self.fullBtn.selected = YES;
            self.fullBtn.frame = CGRectMake(ScreenHeight- TOOLBAR_HEIGHT, 0, TOOLBAR_HEIGHT, TOOLBAR_HEIGHT);
        }];
    } else {
        [UIView animateWithDuration:0.5 animations:^{
            self.view.transform = CGAffineTransformIdentity;
            self.view.bounds = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
            
            self.backBtn.frame = CGRectMake(0, self.backBtn.frame.origin.y, 44, 44);
            self.bottomView.frame = CGRectMake(0, ScreenHeight - TOOLBAR_HEIGHT - 80, ScreenWidth, TOOLBAR_HEIGHT + 80);
            self.bottomView.backgroundColor = [UIColor darkGrayColor];
            
            self.startHUD.transform = CGAffineTransformIdentity;
            
            self.titleView.frame = CGRectMake(0, 0, ScreenWidth - TOOLBAR_HEIGHT, TOOLBAR_HEIGHT + 80);
            UIButton *slowBtn = (UIButton *)[self.titleView viewWithTag:2001];
            slowBtn.frame = CGRectMake(self.titleView.frame.size.width/2 + 40, 0, 40, 30);
            
            UIButton *fastBtn = (UIButton *)[self.titleView viewWithTag:2002];
            fastBtn.frame = CGRectMake(self.titleView.frame.size.width/2 +100, 0, 40, 30);
            self.mediaProgressSlider.frame = CGRectMake(62.0, 93, self.titleView.frame.size.width - 110, 2.0);
            UIButton *forwardBtn = (UIButton *)[self.titleView viewWithTag:9001];
            forwardBtn.frame = CGRectMake(20.0, 0, 32, 32);
            UIButton *playAndStopBtn = (UIButton *)[self.titleView viewWithTag:9002];
            playAndStopBtn.frame = CGRectMake(62.0, 0, 32, 32);
            UIButton *nextBtn = (UIButton *)[self.titleView viewWithTag:9003];
            nextBtn.frame = CGRectMake(104.0, 0, 32, 32);
            UILabel *totalLabel = (UILabel *)[self.titleView viewWithTag:1002];
            totalLabel.frame = CGRectMake(self.titleView.frame.size.width - 40, 84, 40, 21.0);
            UILabel *spendLabel = (UILabel *)[self.titleView viewWithTag:1001];
            spendLabel.frame = CGRectMake(20, 84, 40, 21.0);
            
            UIButton *recordBtn = (UIButton *)[self.titleView viewWithTag:6001];
            recordBtn.frame = CGRectMake(20, 40.0, 32.0, 32.0);
            UIButton *screenShotBtn = (UIButton *)[self.titleView viewWithTag:6002];
            screenShotBtn.frame = CGRectMake(55, 40.0, 32.0, 32.0);
            UIButton *scaleBtn =(UIButton *)[self.titleView viewWithTag:6003];
            scaleBtn.frame = CGRectMake(92, 40.0, 32.0, 32.0);
            
            UILabel *fpsLabel = (UILabel *)[self.titleView viewWithTag:4001];
            fpsLabel.frame = CGRectMake(130, 46.0, 70.0, 21.0);
            
            UILabel *speedLabel = (UILabel *)[self.titleView viewWithTag:4002];
            speedLabel.frame = CGRectMake(self.titleView.frame.size.width - 70, 46.0, 70.0, 21.0);
            
            self.fullBtn.selected = NO;
            self.fullBtn.frame = CGRectMake(ScreenWidth - TOOLBAR_HEIGHT, 0, TOOLBAR_HEIGHT, TOOLBAR_HEIGHT);
        }];
    }
    [self restartToolbarTimer];
}

- (void)beginDragMediaSlider {
    _isMediaSliderBeingDragged = YES;
}

- (void)endDragMediaSlider {
    _isMediaSliderBeingDragged = NO;
}

- (IBAction)didSliderTouchUpOutside {
    [self endDragMediaSlider];
}

- (IBAction)didSliderTouchUpInside {
    self.player.currentPlaybackTime = self.mediaProgressSlider.value;
    [self endDragMediaSlider];
}

- (void)continueDragMediaSlider {
    [self refreshMediaControl];
}

- (void)refreshMediaControl {
//    IJKFFMoviePlayerController *player = self.player;
    
    UILabel *totalDurationLabel = [_titleView viewWithTag:1002];
//    NSString *speedStr = [player transferSpeed];
//    UILabel *speedLabel = (UILabel *)[_titleView viewWithTag:4002];
    if ([[NSThread currentThread] isMainThread]) {
//        speedLabel.text = speedStr;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
//            speedLabel.text = speedStr;
        });
    }
    
    NSTimeInterval duration = self.player.duration;
    NSInteger intDuration = duration + 0.5;
    UISlider *slider = (UISlider *)[_titleView viewWithTag:8001];
    if (intDuration > 0) {
        slider.maximumValue = duration;
        totalDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intDuration / 60), (int)(intDuration % 60)];
    }
    
    NSTimeInterval position;
    if (_isMediaSliderBeingDragged) {
        position = self.mediaProgressSlider.value;
    } else {
        position = self.player.currentPlaybackTime;
    }
    
    NSInteger intPosition = position + 0.5;
    if (intDuration > 0) {
        self.mediaProgressSlider.value = position;
    } else {
        self.mediaProgressSlider.value = 0.0f;
    }
    
    UILabel *currentTimeLabel = [_titleView viewWithTag:1001];
    currentTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int)(intPosition / 60), (int)(intPosition % 60)];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(refreshMediaControl) object:nil];
    [self performSelector:@selector(refreshMediaControl) withObject:nil afterDelay:0.5];
}

- (void)backBtnDidTouch:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)playAndStop:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.player pause];
    } else {
        [self.player play];
    }
}

// 截屏
- (void)screenShot {
    NSDate *date = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMddhhmmss"];
    NSString *DateTime = [formatter stringFromDate:date];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* _dir = [documentsDirectory stringByAppendingPathComponent:@"snapshot"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:_dir]){
        [[NSFileManager defaultManager] createDirectoryAtPath:_dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *appFile = [_dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",DateTime]];
    UIImage* temp = [self.player thumbnailImageAtCurrentTime];
    [pvc writeImage:temp toFileAtPath:appFile];
    
    MBProgressHUD *hud  = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"图片已保存";
    [hud hideAnimated:YES afterDelay:1];
}

// 录像
- (void)handleVideo:(UIButton *)sender {
    sender.selected = !sender.selected;
    if ([self.player isKindOfClass:[IJKFFMoviePlayerController class]]) {
        IJKFFMoviePlayerController *player = self.player;
        if (sender.selected) {
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString* _dir = [documentsDirectory stringByAppendingPathComponent:@"record"];
            if(![[NSFileManager defaultManager] fileExistsAtPath:_dir]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:_dir withIntermediateDirectories:YES attributes:nil error:nil];
            }
            
            NSDate *date = [NSDate date];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"YYYYMMddhhmmss"];
            NSString *DateTime = [formatter stringFromDate:date];
            NSString *appFile = [_dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", DateTime]];
            
            [player recordFilePath:(char *)[appFile UTF8String] second:60 * 30];
        } else {
            [player recordFilePath:NULL second:0];
        }
    }
}

// 慢速播放
- (void)slowPlay {
    speed *= 0.5f;
    if (speed < 0.25) {
        speed = 0.25;
    }
    
    if ([self.player isKindOfClass:[IJKFFMoviePlayerController class]]) {
        IJKFFMoviePlayerController *player = self.player;
        player.playbackRate = speed;
    }
}

// 快速播放
- (void)fastPlay {
    speed *= 2.0f;
    if (speed > 4) {
        speed = 4;
    }
    if ([self.player isKindOfClass:[IJKFFMoviePlayerController class]]) {
        IJKFFMoviePlayerController *player = self.player;
        player.playbackRate = speed;
    }
}

// 快退
- (void) forward {
    self.player.currentPlaybackTime -= 5;
    
    [self refreshMediaControl];
}

// 快进
- (void) next {
    self.player.currentPlaybackTime += 5;
    
    [self refreshMediaControl];
}

// 显示FPS参数
- (void)startfpsTimer {
    if ([[NSThread currentThread] isMainThread]) {
        _fpsTimer = [NSTimer scheduledTimerWithTimeInterval:.5f
                                                     target:self
                                                   selector:@selector(refreshfpsView)
                                                   userInfo:nil
                                                    repeats:YES];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startfpsTimer];
        });
    }
}

- (void)refreshfpsView {
    if ([self.player isKindOfClass:[IJKFFMoviePlayerController class]]) {
        IJKFFMoviePlayerController *player = self.player;
        UILabel *fpsLabel = [_titleView viewWithTag:4001];
        
        fpsLabel.text = [NSString stringWithFormat:@"%.0fFPS", player.fpsAtOutput];
    }
}

- (void)zoomEvent {
    if (self.player.scalingMode == 0) {
        self.player.scalingMode = IJKMPMovieScalingModeAspectFit;
    } else if (self.player.scalingMode == 1) {
        self.player.scalingMode = IJKMPMovieScalingModeAspectFill;
    } else if (self.player.scalingMode == 2) {
        self.player.scalingMode = IJKMPMovieScalingModeFill;
    } else {
        self.player.scalingMode = IJKMPMovieScalingModeNone;
    }
}

#pragma mark - gesture event

- (void)handleTap {
    CGFloat _alpha = 1 - self.backBtn.alpha;
    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone animations:^{
        self.backBtn.alpha = _alpha;
        self.bottomView.alpha = _alpha;
    } completion:nil];
    
    if(_alpha > 0) {
        [self restartToolbarTimer];
    } else {
        [self stopToolbarTimer];
    }
}

#pragma mark - private method

- (void)restartToolbarTimer {
    if(!_toolbarTimer) {
        _toolbarTimer = [NSTimer scheduledTimerWithTimeInterval:4.
                                                         target:self
                                                       selector:@selector(handleTap)
                                                       userInfo:nil
                                                        repeats:NO];
    }
    [_toolbarTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:4.]];
}

- (void)stopToolbarTimer {
    if(_toolbarTimer){
        [_toolbarTimer invalidate];
        _toolbarTimer = nil;
    }
}

// 截图
- (BOOL)writeImage:(UIImage*)image toFileAtPath:(NSString*)aPath {
    if ((image == nil) || (aPath == nil) || ([aPath isEqualToString:@""]))
        return NO;
    @try {
        NSData *imageData = nil;
        NSString *ext = [aPath pathExtension];
        if ([ext isEqualToString:@"png"]){
            imageData = UIImagePNGRepresentation(image);
        } else {
            imageData = UIImageJPEGRepresentation(image,1);
        }
        if ((imageData == nil) || ([imageData length] <= 0)){
            NSLog(@"image data is empty");
            return NO;
        }
        
        [imageData writeToFile:aPath atomically:YES];
        return YES;
    } @catch (NSException *e) {
        NSLog(@"create thumbnail exception.");
    }
    
    return NO;
}

@end
