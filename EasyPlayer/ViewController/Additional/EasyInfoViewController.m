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
}

@end
