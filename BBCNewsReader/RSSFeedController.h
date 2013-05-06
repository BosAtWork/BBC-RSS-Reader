//
//  RSSFeedController.h
//  RssReader
//
//  Created by Frank Bos on 5/4/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFRSSRequestOperation.h"
#import "NSDateFormatter+RelativeAdditions.h"
#import "ItemViewController.h"
#import "RSSFeedsLoader.h"

@interface RSSFeedController : UITableViewController <RSSFeedsLoaderNotifications>

@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
