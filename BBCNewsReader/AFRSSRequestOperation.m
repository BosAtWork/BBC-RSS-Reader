//
//  RSSParser.m
//  RssReader
//
//  Created by Frank Bos on 5/4/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import "AFRSSRequestOperation.h"

@implementation AFRSSRequestOperation {
    NSFetchRequest *_fetchRequest;
    NSMutableDictionary *_rssItemData;
    NSMutableArray *_imagesData;
    NSMutableString *_tempString;
    NSDictionary *_attributeDict;
    NSManagedObjectContext *_managedObjectContext;
}

@synthesize rssItems = _rssItems;
@synthesize successBlock = _successBlock;
@synthesize persistantStoreCoordinator = _persistantStoreCoordinator;
@synthesize rssIdentifier = _rssIdentifier;

- (id) init {
    self = [super init];
    if(self) {
        _rssItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id) initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if(self) {
        _rssItems = [[NSMutableArray alloc] init];        
    }
    return self;
}


+ (AFRSSRequestOperation*)RSSRequestOperationWithRequest:(NSURLRequest *)urlRequest
                               success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSArray *rssItems))success
                               failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
{
    //static factory method that will create a request and set the completion and failure blocks
    AFRSSRequestOperation *requestOperation = [(AFRSSRequestOperation *)[self alloc] initWithRequest:urlRequest];
    [requestOperation setSuccessBlock:[success copy]];
    
    //AFRSSRequestOperation extends from AFXMLRequestOperation so we can load the xml in NSXMLParser and the continue parsing the xml to split in rss items.
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, NSXMLParser *xmlParser) {
        if (success) {         
            xmlParser.delegate = (AFRSSRequestOperation*)operation;
            [xmlParser parse];                       
            //parse xml fast and than do a success call
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error);
        }
    }];
    
    return requestOperation;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
    //create a managedObjectContext if we didnt already have one (we need to recreate it on the parser thread)
    //Every threads need a different NSManagedObjectContext to prevent thread collisions see http://developer.apple.com/library/ios/#documentation/cocoa/conceptual/CoreData/Articles/cdConcurrency.html for more information
    if(_managedObjectContext == nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:self.persistantStoreCoordinator];
    }
    
    //if we start reading a item tag initialize temporary data containers
    //We could also directly write in Core Data objects but that will create a huge overhead and problems to avoid duplicates so this is a better approuch for lots of duplicates
    if ([elementName isEqualToString:@"item"]) {
        _rssItemData = [[NSMutableDictionary alloc] init];
        _imagesData = [[NSMutableArray alloc] init];
    }
    
    _tempString = [[NSMutableString alloc] init];
    _attributeDict = attributeDict;
}

//TODO I should split this function into different functions for each section (Saving to coredate and parsing xml)
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    //if the item element ended we need to convert the temporary data to Core Data objects (and prevent duplicates)
    if ([elementName isEqualToString:@"item"]) {
        NSError *error;
        
        //we create one fetchRequest that we can reuse for all items this will prevent huge memory uses
        if(!_fetchRequest) {
            _fetchRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"RSSItem" inManagedObjectContext:_managedObjectContext];
            [_fetchRequest setEntity:entity];
        }
        
        //check if the item object from the rss feed is already in the Core Data storage
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"guid == %@", [_rssItemData objectForKey:@"guid"]];
        [_fetchRequest setPredicate:predicate];
        
        RSSItem *rssItem = [[_managedObjectContext executeFetchRequest:_fetchRequest error:&error] lastObject];
        
        //if we dont have a rssItem already we create a new one
        if(!rssItem) {
            rssItem = [NSEntityDescription insertNewObjectForEntityForName:@"RSSItem" inManagedObjectContext:_managedObjectContext];
        }
        
        //update the rssItem according to the temporary data from the xml nodes
        [rssItem setValuesForKeysWithDictionary:_rssItemData];
        
        //bind all images to the object (if bbc wants to hook more that 2 images to each article it will be possible)
        for(id object in _imagesData)
        {
            BOOL shouldSaveImage = YES;
            NSSet *images = [rssItem images];
            for(Image *image in images) {
                if([image.src isEqualToString:[object objectForKey:@"src"]]) {
                    shouldSaveImage = NO; //if the image is already attached to RSSItem dont create a duplicated one
                }
            }
            if(shouldSaveImage == YES) {
                Image *image = [NSEntityDescription insertNewObjectForEntityForName:@"Image" inManagedObjectContext:_managedObjectContext];
                //attach the image to the dicationary
                [image setValuesForKeysWithDictionary:object];
                [rssItem addImagesObject:image];
            }            
        }
        
        //The identifiers will specify which rss feed url is coupled with this rssitem so we can filter according different feeds
        NSSet *rssIdentifiers = [rssItem rssIdentifiers];
        BOOL rssItemHasRSSIdentifier = NO;
        //check if we are RSSItem already got the current _rssIdentifier attached it it
        for(RSSIdentifier *rssIdentifier in rssIdentifiers) {
            if([rssIdentifier.identifier isEqualToString:_rssIdentifier]) {
                rssItemHasRSSIdentifier = YES;
            }
        }
        if(rssItemHasRSSIdentifier == NO)
        {
            //create a new RSSIdentifier
            RSSIdentifier *rssIdentifier = [NSEntityDescription insertNewObjectForEntityForName:@"RSSIdentifier"inManagedObjectContext:_managedObjectContext];
            [rssIdentifier setIdentifier:_rssIdentifier];
            [rssItem addRssIdentifiersObject:rssIdentifier];
        }

        //save it to local array (Maybe for later use?)
        [self.rssItems addObject:rssItem];
        
        if(![_managedObjectContext save:&error]){
            NSLog(@"%@", error);
        }
    }
    if (_rssItemData != nil && _tempString != nil) {
        
        if ([elementName isEqualToString:@"title"]) {
            [_rssItemData setObject:_tempString forKey:@"title"];
        }        
        if ([elementName isEqualToString:@"description"]) {
            [_rssItemData setObject:_tempString forKey:@"text"];
        }        
        if ([elementName isEqualToString:@"link"]) {
            [_rssItemData setObject:[[NSURL URLWithString:_tempString] absoluteString] forKey:@"link"];
        }
        if ([elementName isEqualToString:@"guid"]) {
            [_rssItemData setObject:_tempString forKey:@"guid"];
        }
        if ([elementName isEqualToString:@"pubDate"]) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            
            NSLocale *local = [[NSLocale alloc] initWithLocaleIdentifier:@"en_EN"];
            [formatter setLocale:local];
            
            [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
            [_rssItemData setObject:[formatter dateFromString:_tempString] forKey:@"date"];
        }
        if ([elementName isEqualToString:@"media:thumbnail"]) {            
            NSMutableDictionary *imageData = [[NSMutableDictionary alloc] init];
            //TODO improve to use a numberformatter. But for now I am sure that it will be simple int values that will be converted to NSNumber using lexical syntax
            [imageData setObject:@([[_attributeDict objectForKey:@"width"] intValue]) forKey:@"width"];
            [imageData setObject:@([[_attributeDict objectForKey:@"height"] intValue]) forKey:@"height"];
            [imageData setObject:[_attributeDict objectForKey:@"url"] forKey:@"src"];
            
            [_imagesData addObject:imageData];
        }       
    }
    
    if ([elementName isEqualToString:@"rss"]) {
        //call succesBlock if we ended parsing the xml
        self.successBlock(self.request, self.response, self.rssItems);
    }
    
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    [_tempString appendString:string];
    
}

#pragma mark AFNetworking AFXMLRequestOperation acceptable Content-Type overwriting

+ (NSSet *)defaultAcceptableContentTypes {
    return [NSSet setWithObjects:@"application/xml", @"text/xml",@"application/rss+xml", nil];
}
+ (NSSet *)acceptableContentTypes {
    return [self defaultAcceptableContentTypes];
}

@end
