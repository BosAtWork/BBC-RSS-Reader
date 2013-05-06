//
//  RSSIdentifier.h
//  BBCNewsReader
//
//  Created by Frank Bos on 5/6/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RSSItem;

@interface RSSIdentifier : NSManagedObject

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) RSSItem *rssItem;

@end
