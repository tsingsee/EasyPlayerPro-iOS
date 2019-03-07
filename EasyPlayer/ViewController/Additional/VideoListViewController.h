//
//  VideoListViewController.h
//  EasyPlayer
//
//  Created by yingengyue on 2017/9/16.
//  Copyright © 2017年 duowan. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 录像列表
 */
@interface VideoListViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *myTabel;

@end
