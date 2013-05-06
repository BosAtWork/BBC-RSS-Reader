//
//  FullArticleViewController.m
//  RssReader
//
//  Created by Frank Bos on 5/4/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import "FullArticleViewController.h"

@interface FullArticleViewController ()

@end

@implementation FullArticleViewController

@synthesize url = _url;

- (id)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //create a webview of the full size of this screen
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [webView setScalesPageToFit:YES];
    [webView loadRequest:[NSURLRequest requestWithURL:[self url]]];
    
    //Attach autosize rule to autosize if we rotate the iPhone to landscape or portrait
    [webView setAutoresizesSubviews:YES];
    [webView setAutoresizingMask:
     UIViewAutoresizingFlexibleWidth |
     UIViewAutoresizingFlexibleHeight];
    
    [self.view addSubview:webView];
}

@end
