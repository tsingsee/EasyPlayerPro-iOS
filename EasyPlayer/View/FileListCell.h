//
//  FileListCell.h
//  BTG
//
//  Created by liyy on 2017/11/6.
//  Copyright © 2017年 HRG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileListCell : UITableViewCell

@property (nonatomic, retain) UILabel *label;

+ (instancetype)cellWithTableView:(UITableView *)tableView;

@end
