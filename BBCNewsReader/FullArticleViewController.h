//
//  FullArticleViewController.h
//  RssReader
//
//  Created by Frank Bos on 5/4/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FullArticleViewController : UIViewController;

@property (nonatomic, retain) NSURL *url;

- (id)initWithUrl:(NSURL *)url;

@end
