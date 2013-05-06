//
//  ItemViewController.h
//  RssReader
//
//  Created by Frank Bos on 5/4/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSSItem.h"
#import "FullArticleViewController.h"
#import <Social/Social.h>
#import "Image.h"
#import "UIImageView+AFNetworking.h"

@interface ItemViewController : UIViewController

@property (nonatomic, retain) RSSItem *rssItem;

//Interface Builder link variables to UIElements
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UITextView *dateTextView;
@property (nonatomic, retain) IBOutlet UITextView *contentTextView;

- (id)initWithRSSItem:(RSSItem *)rssItem;
- (IBAction)visitFullArticle:(id)sender;
- (IBAction)shareOnSocialMedia:(id)sender;


@end
