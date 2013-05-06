//
//  RSSFeedController.m
//  RssReader
//
//  Created by Frank Bos on 5/4/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import "RSSFeedController.h"

@interface RSSFeedController ()

@end

@implementation RSSFeedController {
    NSMutableArray *_rssItems;
    RSSFeedsLoader *_rssFeedsLoader;
    BOOL _reloadOnViewDidAppear;
}

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMore tag:1];
    
    self.title = @"News feed";
    
    _rssFeedsLoader = [[RSSFeedsLoader alloc] init];
    _rssFeedsLoader.persistentStoreCoordinator = self.persistentStoreCoordinator;
    _rssFeedsLoader.delegate = self;
    
    if (NSClassFromString(@"UIRefreshControl")) {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refreshControl;
    } else {
        //TODO make sure UIRefreshControl also works on iOS 5 otherwise we cant refresh
        //For the sake of keeping this project simple to build I will not include external static libraries otherwise I would have included https://github.com/instructure/CKRefreshControl to mimic UIRefreshControl without changes to the api
    }
    [_rssFeedsLoader refresh];
}

//Tell rssFeedsLoader we would prefer a refresh of the data
- (void)refreshData:(UIRefreshControl *)sender {
    [_rssFeedsLoader refresh];    
}

- (void)rssFeedDidFinishedParsing:(NSArray *)rssItems {
    //copy all items and sort them correctly on the date (data model doesnt care about order just data)
    _rssItems = [rssItems mutableCopy];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [_rssItems sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    //dont waste cpu updateing this view when it isnt visible
    if (self.isViewLoaded && self.view.window) {
        [self.tableView reloadData];
    } else {
        //reload on view did appear so we can still refresh the table
        _reloadOnViewDidAppear = YES;
    }
    //tell refresh icon to stop twirling
    [self.refreshControl endRefreshing];
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
    return [_rssItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Get unused cells and reuse them
    static NSString *CellIdentifier = @"RSSFeedControllerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    //if we cant reuse a cell create a new one
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    //get the correct rssItem we can fill the cell with
    RSSItem *rssItem = [_rssItems objectAtIndex:[indexPath row]];
    
    [[cell textLabel] setText:rssItem.title];
    
    //format date relative to now according to the stackoverflow algoritme specified in category
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
    NSString *dateString = [dateFormatter relativeStringFromDate:rssItem.date];
    [[cell detailTextLabel] setText:dateString];
    
    //create a empty imageView so we dont need to do it in a thread
    [[cell imageView] setImage:[[UIImage alloc] initWithCIImage:nil]];
    
    //sort images based on size to get the smalest
    NSMutableArray *images = [NSMutableArray arrayWithArray:[[rssItem images] allObjects]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"width" ascending:NO];
    [images sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    //make a weak reference to image if we try to point to the Core Data object we can get multi-thread errors because otherwise we get a error accesing coredata in other thread (We want to prevent retain cycles)
    __weak NSString *weakImageSrc = [[images objectAtIndex:0] src];
    
    //TODO replace next block with UIImageView categogry in AFNetworking. But for sake of showing how GCD works without external libraries leave it here 
    
    //using GCD to prevent loading images to block main thread
    //Use a serial queu because it it will not overload the application by trying to load all images at the same time    
    dispatch_queue_t downloadPhotoQueu = dispatch_queue_create("nl.automaticoo.photoqueue", NULL);
    dispatch_async(downloadPhotoQueu, ^{
        //load data
        NSData *data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:weakImageSrc]];
        UIImage *uiImage = [UIImage imageWithData:data];
        //after we loaded data get back to main thread (Always do ui updates in main thread to prevent multithread collisions)
        dispatch_async(dispatch_get_main_queue(), ^{
            UITableViewCell *cellToUpdate = [self.tableView cellForRowAtIndexPath:indexPath];
            if (cellToUpdate != nil) {
                [cellToUpdate.imageView setImage:uiImage];
                [cellToUpdate setNeedsLayout];
            }
        });
    });
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ItemViewController *itemViewController = [[ItemViewController alloc] initWithRSSItem:[_rssItems objectAtIndex:[indexPath row]]];
    
    [self.navigationController pushViewController:itemViewController animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	if(_reloadOnViewDidAppear) {
        _reloadOnViewDidAppear = NO;
        [self.tableView reloadData];
    }
}

@end
