//
//  FileListViewController.m
//  EasyPlayer
//
//  Created by yingengyue on 2017/9/15.
//  Copyright © 2017年 duowan. All rights reserved.
//

#import "FileListViewController.h"
#import "VideoListViewController.h"
#import "ScreenShotListViewController.h"

#define FILEPATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

@interface FileListViewController () {
    NSArray *fileNameArray;
}

@end

@implementation FileListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"文件";
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    fileNameArray = [[NSArray alloc] initWithArray:[fileManager contentsOfDirectoryAtPath:FILEPATH error:nil]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return fileNameArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIden = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIden];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIden];
    }
    cell.textLabel.text = fileNameArray[indexPath.row];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"record"]) {
        VideoListViewController *easyVc = [[VideoListViewController alloc] init];
        [self.navigationController pushViewController:easyVc animated:YES];
    } else {
        ScreenShotListViewController *easyVc = [[ScreenShotListViewController alloc] init];
        [self.navigationController pushViewController:easyVc animated:YES];
    }
}

@end
