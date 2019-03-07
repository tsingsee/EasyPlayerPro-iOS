
#import "RootViewController.h"
#import "PlayViewController.h"
#import "FileListViewController.h"
#import "VideoCell.h"
#import <CommonCrypto/CommonDigest.h>
#import "EasyInfoViewController.h"
#import "EasySetingViewController.h"
#import "MBProgressHUD.h"
#import "UIImageView+WebCache.h"
#import "AFNetworking.h"

@interface RootViewController()<UICollectionViewDelegate, UICollectionViewDataSource, UIActionSheetDelegate> {
    UIAlertView *_alertView;
    UIAlertView *_deleteAlertView;
    
    UIActionSheet *_actionSheet;
    
    UICollectionViewFlowLayout *layout;
    
    NSInteger currentPage;
    NSArray *videoSquareArray;
}

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationController.navigationBarHidden = YES;
    [self navigationSetting];
    
    currentPage = 0;
    layout = [[UICollectionViewFlowLayout alloc]init];
    //定义每个UICollectionView 横向的间距
    layout.minimumLineSpacing = 5;
    //定义每个UICollectionView 纵向的间距
    layout.minimumInteritemSpacing = 5;
    //定义每个UICollectionView 的边距距
    layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);//上左下右
    
    CGFloat y = Statusbar_Height + 44;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, y, ScreenWidth, ScreenHeight - 40 - y) collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    [self.collectionView registerClass:[VideoCell class] forCellWithReuseIdentifier:@"VideoCellSquare"];
    [self.collectionView registerClass:[VideoCell class] forCellWithReuseIdentifier:@"VideoCell"];
    [self.view addSubview:self.collectionView];
    NSMutableArray *urls = [[NSUserDefaults standardUserDefaults] objectForKey:@"videoUrls"];
    if(urls) {
        _dataArray = [urls mutableCopy];
    } else {
        _dataArray = [NSMutableArray array];
    }
    
    _alertView = [[UIAlertView alloc] initWithTitle:@"请输入播放地址" message: nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [_alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [_alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeURL;
    
    _deleteAlertView = [[UIAlertView alloc] initWithTitle:@"确定删除?" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    
    _actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"删除" otherButtonTitles:@"修改", nil];
    
    self.collectionView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(doReload)];
    [self setTabButton];
    [self pullSquareData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    [self.collectionView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBarHidden = NO;
}

- (void)setTabButton {
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"视频广场", @"播放器"]];
    seg.frame = CGRectMake(-4, ScreenHeight - 40, ScreenWidth + 8, 40.0);
    seg.selectedSegmentIndex = 0;
    [self.view addSubview:seg];
    [seg addTarget:self action:@selector(chageView:) forControlEvents:UIControlEventValueChanged];
    
//    NSArray *titleArray = @[@"视频广场",@"点播"];
//    for (int i = 0; i < 2; i ++) {
//        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(i*ScreenWidth/2, ScreenHeight - 104.0, ScreenWidth/2, 40.0)];
//        [btn setTitle:titleArray[i] forState:UIControlStateNormal];
//        [self.view addSubview:btn];
//        btn.backgroundColor = [UIColor redColor];
//        [self.view bringSubviewToFront:btn];
//    }
}

- (void)chageView:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
//        layout = [[UICollectionViewFlowLayout alloc] init];
        //定义每个UICollectionView 横向的间距
        layout.minimumLineSpacing = 5;
        //定义每个UICollectionView 纵向的间距
        layout.minimumInteritemSpacing = 5;
        //定义每个UICollectionView 的边距距
        layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);//上左下右
        self.collectionView.collectionViewLayout = layout;
        [self pullSquareData];
    } else {
//        layout = [[UICollectionViewFlowLayout alloc] init];
        //定义每个UICollectionView 横向的间距
        layout.minimumLineSpacing = 10;
        //定义每个UICollectionView 纵向的间距
        layout.minimumInteritemSpacing = 10;
        //定义每个UICollectionView 的边距距
        layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);//上左下右
        self.collectionView.collectionViewLayout = layout;
        [self.collectionView reloadData];
    }
    currentPage = sender.selectedSegmentIndex;
}

- (void)pullSquareData {
    AFHTTPSessionManager * manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"html/text",@"text/plain", nil];
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    __weak typeof(self)weakSelf = self;
    __block MBProgressHUD *startHUD = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    startHUD.label.text = @"正在获取广场视频...";
    startHUD.bezelView.color = [UIColor clearColor];
    startHUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    startHUD.backgroundView.color = [UIColor colorWithWhite:0.f alpha:.4f];
    startHUD.contentColor = [UIColor whiteColor];
    startHUD.label.font = [UIFont systemFontOfSize:13];
    [manager GET:@"http://www.easydarwin.org/public/json/squarelist.json" parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [startHUD hideAnimated:YES];
        NSDictionary *easyDic = [responseObject objectForKey:@"EasyDarwin"];
        NSDictionary *headerDic =  [easyDic objectForKey:@"Header"];
        NSDictionary *bodyDic =  [easyDic objectForKey:@"Body"];
        if ([[headerDic objectForKey:@"ErrorNum"] isEqualToString:@"200"]) {
            videoSquareArray = bodyDic[@"Lives"];
            [weakSelf.collectionView reloadData];
        } else {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.label.text = [NSString stringWithFormat:@"%@ %@", [headerDic objectForKey:@"ErrorNum"],[headerDic objectForKey:@"ErrorString"]];;
            hud.removeFromSuperViewOnHide = YES;
            [hud hideAnimated:YES afterDelay:3];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [startHUD hideAnimated:YES];
    }];
}

- (void)doReload {
    if (currentPage == 0) {
        [self pullSquareData];
    } else {
        [self.collectionView reloadData];
    }
    
    [self.collectionView.mj_header endRefreshing];
}

// 导航栏设置
- (void)navigationSetting {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, Statusbar_Height+44)];
    view.backgroundColor = MAIN_COLOR;
    [self.view addSubview:view];
    
    CGFloat y = Statusbar_Height + 7;
    CGFloat size = 30;
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 130, 30)];
    [label setText:@"EasyPlayer Pro"];
    label.font = [UIFont systemFontOfSize:14.0];
    [label setTextColor:[UIColor whiteColor]];
    [view addSubview:label];
    
    UIButton *infoBtn = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth - (10 + size) * 1, y, size, size)];
    [infoBtn setBackgroundImage:[UIImage imageNamed:@"info"] forState:UIControlStateNormal];
    [infoBtn addTarget:self action:@selector(infoView) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:infoBtn];
    
    UIButton *setBtn = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth - (10 + size) * 2, y, size, size)];
    [setBtn setBackgroundImage:[UIImage imageNamed:@"set"] forState:UIControlStateNormal];
    [setBtn addTarget:self action:@selector(showSetView) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:setBtn];
    
    UIButton *addBtn = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth - (10 + size) * 3, y, size, size)];
    [addBtn setBackgroundImage:[UIImage imageNamed:@"ic_action_add"] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(clickAddBtn) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:addBtn];
    
    UIButton *fileButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth - (10 + size) * 4, y, size, size)];
    [fileButton setBackgroundImage:[UIImage imageNamed:@"ic_action_folder"] forState:UIControlStateNormal];
    [fileButton addTarget:self action:@selector(showFileList) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:fileButton];
}

- (void)showFileList {
    FileListViewController *easyVc = [[FileListViewController alloc] init];
    [self.navigationController pushViewController:easyVc animated:YES];
}

- (void)showSetView {
    EasySetingViewController *easyVc = [[EasySetingViewController alloc] init];
    [self.navigationController pushViewController:easyVc animated:YES];
}

- (void)infoView {
    EasyInfoViewController *easyVc = [[EasyInfoViewController alloc] init];
    [self.navigationController pushViewController:easyVc animated:YES];
}

- (void)clickAddBtn {
    [_alertView textFieldAtIndex:0].placeholder = @"RTSP/RTMP/HTTP/HLS地址";
    [_alertView textFieldAtIndex:0].text = @"rtmp://live.hkstv.hk.lxdns.com/live/hks";
    _alertView.tag = -1;
    [_alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView == _alertView && buttonIndex == 1){
        UITextField *tf = [_alertView textFieldAtIndex:0];
        NSString* url = [tf.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if(_alertView.tag < 0){//new
            [_dataArray insertObject:url atIndex:0];
        } else {//edit
            [_dataArray removeObjectAtIndex:_alertView.tag];
            [_dataArray insertObject:url atIndex:_alertView.tag];
        }
        [[NSUserDefaults standardUserDefaults] setObject:_dataArray forKey:@"videoUrls"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.collectionView reloadData];
    }
    
    if(alertView == _deleteAlertView && buttonIndex == 1){
        NSString* url = [_dataArray objectAtIndex:_deleteAlertView.tag];
        const char *cStr = [url UTF8String];
        unsigned char result[16];
        CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
        NSString* strMd5 = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                            result[0], result[1], result[2], result[3],
                            result[4], result[5], result[6], result[7],
                            result[8], result[9], result[10], result[11],
                            result[12], result[13], result[14], result[15]
                            ];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* docDir = [paths objectAtIndex:0];
        NSString* path = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"snapshot/%@.png", strMd5]];
        if([[NSFileManager defaultManager] fileExistsAtPath:path]){
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        [_dataArray removeObjectAtIndex:_deleteAlertView.tag];
        [[NSUserDefaults standardUserDefaults] setObject:_dataArray forKey:@"videoUrls"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.collectionView reloadData];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(actionSheet == _actionSheet){
        switch (buttonIndex) {
            case 0: {
                //delete
                _deleteAlertView.tag = _actionSheet.tag;
                [_deleteAlertView show];
                break;
            }
            case 1: {
                //edit
                _alertView.tag = _actionSheet.tag;
                UITextField *tf = [_alertView textFieldAtIndex:0];
                tf.text = [_dataArray objectAtIndex:_alertView.tag];
                [_alertView show];
                break;
            }
            default:
                break;
        }
    }
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (currentPage == 1) {
        return _dataArray.count;
    } else {
        return videoSquareArray.count;
    }
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (currentPage == 0) {
        int w = (ScreenWidth - 16) /2;
        int h = w * 9 /16;
        return CGSizeMake(w, h + 30);//30 is the bottom title height
    } else {
        int w = ScreenWidth - 20;
        int h = w * 9 /16;
        return CGSizeMake(w, h + VIDEO_TITLE_HEIGHT);//30 is the bottom title height
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (currentPage == 0) {
        VideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCellSquare" forIndexPath:indexPath];
        NSDictionary *dict = videoSquareArray[indexPath.row];
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:dict[@"SnapURL"]]];
        cell.titleLabel.text = [NSString stringWithFormat:@"  %@",dict[@"Name"]];
        return cell;
    } else {
        VideoCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoCell" forIndexPath:indexPath];
        NSString *url = _dataArray[indexPath.row];
        [cell.titleLabel setText:[NSString stringWithFormat:@"  %@",url]];
        
        const char *cStr = [url UTF8String];
        unsigned char result[16];
        CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
        NSString* strMd5 = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                            result[0], result[1], result[2], result[3],
                            result[4], result[5], result[6], result[7],
                            result[8], result[9], result[10], result[11],
                            result[12], result[13], result[14], result[15]
                            ];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* docDir = [paths objectAtIndex:0];
        NSString* path = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"snapshot/%@.png", strMd5]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]){
            cell.imageView.image = [UIImage imageWithContentsOfFile:path];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"ImagePlaceholder"];
        }
        UILongPressGestureRecognizer* longgs=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longpress:)];
        [cell addGestureRecognizer:longgs];
        longgs.minimumPressDuration=0.3;
        longgs.view.tag=indexPath.row;
        return cell;
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PlayViewController* pvc = [[PlayViewController alloc] init];
    if (currentPage == 1) {
        pvc.urlStr = _dataArray[indexPath.row];
        const char *cStr = [pvc.urlStr UTF8String];
        unsigned char result[16];
        CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
        NSString* strMd5 = [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                            result[0], result[1], result[2], result[3],
                            result[4], result[5], result[6], result[7],
                            result[8], result[9], result[10], result[11],
                            result[12], result[13], result[14], result[15]
                            ];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* docDir = [paths objectAtIndex:0];
        NSString* _dir = [docDir stringByAppendingPathComponent:@"snapshot"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:_dir]){
            [[NSFileManager defaultManager] createDirectoryAtPath:_dir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        pvc.imagePath = [_dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",strMd5]];
        pvc.isVideoSquare = NO;
    } else {
        NSDictionary *dict = videoSquareArray[indexPath.row];
        pvc.urlStr = dict[@"PlayUrl"];
        pvc.isVideoSquare = YES;
    }
    
    [self presentViewController:pvc animated:YES completion:nil];
}

-(void)longpress:(UILongPressGestureRecognizer*)ges {
    if (currentPage == 1) {
        CGPoint pointTouch = [ges locationInView:self.collectionView];
        if(ges.state == UIGestureRecognizerStateBegan){
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:pointTouch];
            _actionSheet.tag = indexPath.row;
            [_actionSheet showInView:self.view];
        }
    }
}

@end

