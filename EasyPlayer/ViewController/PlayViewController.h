
#import <UIKit/UIKit.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <IJKMediaFramework/IJKMediaFramework.h>

@interface PlayViewController : UIViewController

@property (nonatomic, strong) NSString *urlStr;
@property (nonatomic, strong) NSString *imagePath;

@property (nonatomic, assign) BOOL isVideoSquare;
@property (nonatomic, assign) BOOL isLocal;

@property (atomic, retain) id<IJKMediaPlayback> player;

@end
