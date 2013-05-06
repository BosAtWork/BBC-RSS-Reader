//
//  RSSParser.h
//  RssReader
//
//  Created by Frank Bos on 5/4/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import "AFXMLRequestOperation.h"
#import "RSSItem.h"
#import "Image.h"
#import "RSSIdentifier.h"

//There is a AFNetworking RSS library availabel on github : http://www.suushmedia.com/simple-rss-reader-with-afnetworking/
//But I didnt like the implementation because it didnt follow the standard of the AFNetworking framework and it gives me more room to show implementations of different techniques
@interface AFRSSRequestOperation : AFXMLRequestOperation <NSXMLParserDelegate>

@property (nonatomic, retain) NSString *rssIdentifier;
@property (nonatomic, retain) NSPersistentStoreCoordinator *persistantStoreCoordinator;
@property (nonatomic, retain) NSMutableArray *rssItems;

@property (nonatomic, strong) void (^successBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSArray *rssItems);

+ (AFRSSRequestOperation*)RSSRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                     success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSArray *rssItems))success
                                     failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure;

@end
