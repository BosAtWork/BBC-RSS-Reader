//
//  Image.h
//  BBCNewsReader
//
//  Created by Frank Bos on 5/6/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RSSItem;

@interface Image : NSManagedObject

@property (nonatomic, retain) NSNumber *height;
@property (nonatomic, retain) NSString *src;
@property (nonatomic, retain) NSNumber *width;
@property (nonatomic, retain) RSSItem *rssItem;

@end