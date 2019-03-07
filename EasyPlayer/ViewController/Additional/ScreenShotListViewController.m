//
//  ScreenShotListViewController.m
//  EasyPlayer
//
//  Created by liyy on 2017/12/30.
//  Copyright © 2017年 cs. All rights reserved.
//

#import "ScreenShotListViewController.h"
#import "ScreenShotListCell.h"

static NSString *collectionCellIdentifier = @"collectionCellIdentifier";

@interface ScreenShotListViewController ()

@property (nonatomic, retain) NSArray *images;

@end

@implementation ScreenShotListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"截图记录";
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *_dir = [documentsDirectory stringByAppendingPathComponent:@"snapshot"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    _images = [[NSArray alloc] initWithArray:[fileManager contentsOfDirectoryAtPath:_dir error:nil]];
}

#pragma mark - UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _images.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* _dir = [documentsDirectory stringByAppendingPathComponent:@"snapshot"];
    NSString *appFile =[_dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", _images[indexPath.row]]];
    
    ScreenShotListCell *cell = [ScreenShotListCell cellWithTableView:tableView];
    cell.infoIV.backgroundColor = [UIColor blackColor];
    NSString *file = appFile;
    cell.infoIV.image = [UIImage imageWithContentsOfFile:file];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 180;
}

@end
