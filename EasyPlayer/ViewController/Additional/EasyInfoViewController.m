//
//  EasyInfoViewController.m
//  EasyPlayer
//
//  Created by yingengyue on 2017/2/9.
//  Copyright © 2017年 duowan. All rights reserved.
//

#import "EasyInfoViewController.h"
#import "UIImageView+WebCache.h"

@interface EasyInfoViewController ()

@end

@implementation EasyInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"关于我们";
    
    [self.iOSEasyRTSPImage sd_setImageWithURL:[NSURL URLWithString:@"http://www.easydarwin.org/github/images/firimeasyplayerios.png"]];
    
    NSString *name = @"EasyPlayerPro-1.2.19.0418";
    NSString *content;
    UIColor *color;
    
    NSInteger activeDays = [[NSUserDefaults standardUserDefaults] integerForKey:@"activeDays"];
    if (activeDays >= 9999) {
        content = @"激活码永久有效";
        color = [UIColor greenColor];
    } else if (activeDays > 0) {
        content = [NSString stringWithFormat:@"激活码还剩%ld天可用", (long)activeDays];
        color = [UIColor yellowColor];
    } else {
        content = [NSString stringWithFormat:@"激活码已过期%ld天", (long)activeDays];
        color = [UIColor redColor];
    }
    
    NSString *str = [NSString stringWithFormat:@"%@(%@)", name, content];
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:str];
    
    NSRange range = [str rangeOfString:content];
    NSDictionary *dict = @{ NSForegroundColorAttributeName:color };
    
    [attr setAttributes:dict range:range];
    
    self.dayLabel.attributedText = attr;
    self.dayLabel.numberOfLines = 0;
}

@end
