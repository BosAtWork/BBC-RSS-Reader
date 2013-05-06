//
//  RSSItem.h
//  BBCNewsReader
//
//  Created by Frank Bos on 5/6/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Image;

@interface RSSItem : NSManagedObject

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *guid;
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSSet *images;
@property (nonatomic, retain) NSSet *rssIdentifiers;
@end

@interface RSSItem (CoreDataGeneratedAccessors)

- (void)addImagesObject:(Image *)value;
- (void)removeImagesObject:(Image *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

- (void)addRssIdentifiersObject:(NSManagedObject *)value;
- (void)removeRssIdentifiersObject:(NSManagedObject *)value;
- (void)addRssIdentifiers:(NSSet *)values;
- (void)removeRssIdentifiers:(NSSet *)values;

@end
