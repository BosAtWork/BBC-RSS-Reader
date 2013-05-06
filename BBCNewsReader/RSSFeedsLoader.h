//
//  RSSFeedsLoader.h
//  BBCNewsReader
//
//  Created by Frank Bos on 5/5/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFRSSRequestOperation.h"

@protocol RSSFeedsLoaderNotifications <NSObject>
- (void)rssFeedDidFinishedParsing:(NSArray *)rssItems;
@end;

@interface RSSFeedsLoader : NSObject

@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, weak) id <RSSFeedsLoaderNotifications> delegate;

- (void)refresh;

@end
