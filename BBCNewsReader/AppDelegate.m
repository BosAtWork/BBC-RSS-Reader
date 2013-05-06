//
//  AppDelegate.m
//  RssReader
//
//  Created by Frank Bos on 5/4/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate {
    //define the two base controllers 
    RSSFeedController *_rssFeedController;
    RSSFeedListViewController *_rssFeedListController;
    //define ui tab bar controller that will be the first view controller
    UITabBarController *_uiTabBarController;
}

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    //Create the rss controller that will show us the rss feed data
    _rssFeedController = [[RSSFeedController alloc] init];
    _rssFeedController.persistentStoreCoordinator = [self persistentStoreCoordinator];
    UINavigationController *rssFeedNavigationController = [[UINavigationController alloc] initWithRootViewController:_rssFeedController];
    
    //create rss feed list controller so we can adjust which feeds to combine
    _rssFeedListController = [[RSSFeedListViewController alloc] init];
    
    //Using literal syntax to define array of both controllers
    NSArray *controllers = @[rssFeedNavigationController, _rssFeedListController];
    
    _uiTabBarController = [[UITabBarController alloc] init];
    _uiTabBarController.viewControllers = controllers;
    
    [self.window setRootViewController:_uiTabBarController];
    
    //if there is an update on NSManagedObjectContext from a different thread react accordingly
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contextChanged:) name:NSManagedObjectContextDidSaveNotification object:nil];
    
    //keep getting noticed of reachability changes
    [self checkReachability];
    
    return YES;
}

- (void)checkReachability {
    //AFNetworking has the setReachabilityStatus class that will notify if the reachability to bbc is changed so we can notify the user of lost internet connection
    //Core Data will still be available for offline use
    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://www.bbc.co.uk/"]];
    [httpClient setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusNotReachable) {
            UIAlertView *errorView;
            errorView = [[UIAlertView alloc] initWithTitle:@"Network error" message:@"Your internet connection is lost" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
            [errorView show];
        }
    }];
}

//Block of code copied from the Internet because of its frequent use
//Will update this NSMangagedObjectContext from NSManagedObjectContext other threads
- (void)contextChanged:(NSNotification *)notification {
    //if it is the main managedObjectContext dont update itself on itself
    if ([notification object] == self.managedObjectContext) {
        return;
    }
    //if we are getting called from an other thread (probally) call it on the main thread
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(contextChanged:) withObject:notification waitUntilDone:YES];
        return;
    }
    //merge changes
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {}

- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application {}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            //TODO if we go production change it with proper error handling
            //Note for self : http://stackoverflow.com/questions/2262704/iphone-core-data-production-error-handling
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel {
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"BBCNewsReader" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"RssReader.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        //TODO if we go production change it with proper error handling
        //Note for self : http://stackoverflow.com/questions/2262704/iphone-core-data-production-error-handling
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
