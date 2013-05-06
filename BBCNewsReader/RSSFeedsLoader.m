//
//  RSSFeedsLoader.m
//  BBCNewsReader
//
//  Created by Frank Bos on 5/5/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import "RSSFeedsLoader.h"

@implementation RSSFeedsLoader {
    NSMutableArray *_rssFeeds;
    NSInteger *_rssFeedsStillLoading;
    NSMutableArray *_rssItems;
    NSManagedObjectContext *_managedObjectContext;
    BOOL _queueRefresh;
}

@synthesize items = _items;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize delegate = _delegate;

- (id)init {
    self = [super init];
    if (self) {
        _queueRefresh = NO;
        
        _items = [[NSMutableArray alloc] init];
        //listen to notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rssFeedsChanged) name:RSSFeedListChanged object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:nil];
        [self loadRSSList];
    }
    return self;
}

- (void)rssFeedsChanged {
    //reload plist and refresh data
    [self loadRSSList];
    [self refresh];
}

- (void)loadRSSList {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    path = [path stringByAppendingPathComponent:@"rssfeeds.plist"];
    
    //copy plist if it doesnt exist yet (rare situation but can happen)
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:path]) {
        NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"rssfeeds" ofType:@"plist"];
        [fileManager copyItemAtPath:sourcePath toPath:path error:nil];
    }
    //read plist
    _rssFeeds = [NSMutableArray arrayWithContentsOfFile:path];
}
//update _managedObjectContext if Core Data database is updated in an other thread
- (void)contextChanged:(NSNotification *)notification {
    if ([notification object] == _managedObjectContext) {
        return;
    }
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(contextChanged:) withObject:notification waitUntilDone:YES];
        return;
    }
    
    [_managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

- (void)refresh {
    //keep one NSManagedObjectContext for this thread and keep it to prevent memory hogging
    if (_managedObjectContext == nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    
    //if we want to refresh but we are still busy loading all rss feeds dont stack them this will lead to unexpected errors. So we queue the refresh and will refresh as soon as we are done
    if (_rssFeedsStillLoading > 0) {
        _queueRefresh = YES; //TODO maybe a better name would be _shouldRefreshAgain?
        return;
    }
    _items = [[NSMutableArray alloc] init];
    _rssFeedsStillLoading = 0;
    for (id object in _rssFeeds) {
        if ([[object objectForKey:@"active"] boolValue] == YES) {
            //only load active rss feeds
            _rssFeedsStillLoading += 1;
            [self loadSingleRSSFeed:object];
        }
    }
}

- (void)filterRSSFeedItems {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RSSItem" inManagedObjectContext:_managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    //fetch all rss items that contain one or more of the identifiers (urls)
    NSPredicate *predicate;
    NSMutableArray *compoundPredicateArray = [[NSMutableArray alloc] init];
    for (id object in _rssFeeds) {
        if ([[object objectForKey:@"active"] boolValue]) {
            predicate = [NSPredicate predicateWithFormat:@"rssIdentifiers.identifier CONTAINS[cd] %@", [object objectForKey:@"url"]];
            [compoundPredicateArray addObject:predicate];
        }
    }
    //make compound predicates simular to OR in sql
    predicate = [NSCompoundPredicate orPredicateWithSubpredicates:compoundPredicateArray];
    
    [request setPredicate:predicate];
    
    [request setEntity:entity];
    
    NSError *error;
    NSArray *results = [_managedObjectContext executeFetchRequest:request error:&error];
    
    if (!results) {
        NSLog(@"%@", error);
    }
    
    
    [_items addObjectsFromArray:results];
    
    results = nil;
    
    //if we have a queuRefresh waiting refresh again
    if (_queueRefresh) {
        _queueRefresh = NO;
        [self refresh];
    }
}

- (void)loadSingleRSSFeed:(NSDictionary *)rssData {
    NSURL *url = [NSURL URLWithString:[rssData objectForKey:@"url"]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:30];
    
    AFRSSRequestOperation *operation = [AFRSSRequestOperation RSSRequestOperationWithRequest:request
         success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSArray *rssItems) {             
             _rssFeedsStillLoading -= 1;
             if (_rssFeedsStillLoading == 0) {
                 //NOTE I tried to process the CoreData on different thread but it gave more problems than it solved (left code for debug checking later)
                 /*__weak RSSFeedsLoader *weakSelf = self;
                  dispatch_queue_t parseRssFeeds = dispatch_queue_create("nl.automaticoo.parserss", NULL);
                  dispatch_async(parseRssFeeds, ^{
                  [weakSelf filterRSSFeedItems];
                  dispatch_async(dispatch_get_main_queue(), ^{
                  [self.delegate rssFeedDidFinishedParsing:_items];
                  });
                  });*/
                 //Filter rrs feed items and then give items to delegate
                 [self filterRSSFeedItems];
                 [self.delegate rssFeedDidFinishedParsing:_items];
             }
         }

         failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
             //we failed and we need to check for reachability
             NSLog(@"%@", error);
         }
    ];
    
    [operation setRssIdentifier:[rssData objectForKey:@"url"]];
    [operation setPersistantStoreCoordinator:_persistentStoreCoordinator];
    [operation start];
}

@end
