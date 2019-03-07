//
//  EasySetingViewController.m
//  EasyPlayer
//
//  Created by yingengyue on 2017/3/4.
//  Copyright © 2017年 duowan. All rights reserved.
//

#import "EasySetingViewController.h"
#import "MBProgressHUD.h"

@interface EasySetingViewController () {
    BOOL isSelect;
}

@end

@implementation EasySetingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"设置";
    
    NSString *transState = [[NSUserDefaults standardUserDefaults] objectForKey:@"transport"];
    if ([transState isEqualToString:@"udp"]) {
        self.transBtn.selected = YES;
    }
}

- (IBAction)btnEvent:(UIButton *)sender {
    sender.selected = !sender.selected;
    isSelect = sender.selected;
}

- (IBAction)configModify:(id)sender {
    if (isSelect) {
        [[NSUserDefaults standardUserDefaults] setObject:@"udp" forKey:@"transport"];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:@"tcp" forKey:@"transport"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = @"修改成功";
    [hud hideAnimated:YES afterDelay:3];
}

@end
