//
//  AppDelegate.h
//  RssReader
//
//  Created by Frank Bos on 5/4/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSSFeedController.h"
#import "RSSFeedListViewController.h"
#import "AFHTTPClient.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, retain) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (void)checkReachability;
- (NSURL *)applicationDocumentsDirectory;

@end
