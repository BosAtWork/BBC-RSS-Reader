//
//  RSSFeedListViewController.m
//  BBCNewsReader
//
//  Created by Frank Bos on 5/5/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import "RSSFeedListViewController.h"

@interface RSSFeedListViewController ()

@end

@implementation RSSFeedListViewController {
    NSMutableArray *_rssFeeds;
    NSString *_path;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFavorites tag:1];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    _path = [_path stringByAppendingPathComponent:@"rssfeeds.plist"];
    
    //Copy plist to writable location if it didnt already exists there
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:_path]) {
        NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"rssfeeds" ofType:@"plist"];
        [fileManager copyItemAtPath:sourcePath toPath:_path error:nil];
    }
    
    //load plist into local variable 
    _rssFeeds = [NSMutableArray arrayWithContentsOfFile:_path];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return _rssFeeds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //reuse cell if it is possible
    static NSString *CellIdentifier = @"RSSFeedListViewControllerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    //there is no cell create a new one
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *rssFeed = [_rssFeeds objectAtIndex:indexPath.row];
    
    //configure cell
    [cell.textLabel setText:[rssFeed objectForKey:@"name"]];
    
    //prevent cell selection
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //make a uiswitch on alle cells to make rssfeeds active or non-active
    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
    cell.accessoryView = switchView;
    [switchView setOn:[[rssFeed objectForKey:@"active"] boolValue] animated:NO];
    [switchView addTarget:self action:@selector(rssFeedSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    
    return cell;
}

- (void)rssFeedSwitchChanged:(id)sender {
    UISwitch *switchControl = sender;
    UITableViewCell *parentCell = (UITableViewCell *)switchControl.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:parentCell];
    
    NSMutableDictionary *rssFeed = [_rssFeeds objectAtIndex:indexPath.row];
    
    //convert bool because dictionaries only accept Objects
    [rssFeed setObject:[NSNumber numberWithBool:switchControl.on] forKey:@"active"];
    
    //update plist
    [_rssFeeds writeToFile:_path atomically:YES];
    
    //notify all other classes of the change in the rssFeedList
    //TODO we could also create new rss feeds from custom input and all classes would stil work
    [[NSNotificationCenter defaultCenter] postNotificationName:RSSFeedListChanged object:self];
}

@end
