//
//  VideoListViewController.m
//  EasyPlayer
//
//  Created by yingengyue on 2017/9/16.
//  Copyright © 2017年 duowan. All rights reserved.
//

#import "VideoListViewController.h"
#import "PlayViewController.h"

@interface VideoListViewController () {
     NSArray *fileNameArray;
}

@end

@implementation VideoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"录像";
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *_dir = [documentsDirectory stringByAppendingPathComponent:@"record"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    fileNameArray = [[NSArray alloc] initWithArray:[fileManager contentsOfDirectoryAtPath:_dir error:nil]];
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
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* _dir = [documentsDirectory stringByAppendingPathComponent:@"record"];
    NSString *appFile =[_dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",cell.textLabel.text]];
    if ([appFile.pathExtension isEqualToString:@"mp4"]) {
        PlayViewController *play = [[PlayViewController alloc] init];
        play.urlStr = appFile;
        play.isVideoSquare = YES;
        play.isLocal = YES;
        [self presentViewController:play animated:YES completion:nil];
    }
}

@end
