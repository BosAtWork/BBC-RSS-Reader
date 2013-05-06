//
//  ItemViewController.m
//  RssReader
//
//  Created by Frank Bos on 5/4/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import "ItemViewController.h"

@interface ItemViewController ()

@end

@implementation ItemViewController {
    NSString *_longDateString;
    NSString *_shortDateString;
}

@synthesize imageView = _imageView;
@synthesize dateTextView = _dateTextView;
@synthesize contentTextView = _contentTextView;

- (id)initWithRSSItem:(RSSItem *)rssItem {
    self = [super init];
    if (self) {
        _rssItem = rssItem;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set right title and we will replace it with titleLabel but than the next block of code is more generic
    [self setTitle:_rssItem.title];
    
    //create UILabel that will autosize its font instead of cutting of the title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 40)];
    titleLabel.text = self.navigationItem.title;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.backgroundColor  = [UIColor clearColor];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    self.navigationItem.titleView = titleLabel;
    
    //get images from this rssItem and sort them on the size
    NSSet *images = [_rssItem images];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"width" ascending:NO];
    [images sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    //get the biggest image that is available
    Image *image = [[images allObjects] lastObject];
    
    [self.imageView setImageWithURL:[NSURL URLWithString:image.src]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE, dd MMMM yyyy"];
    _longDateString = [dateFormatter stringFromDate:_rssItem.date];
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    _shortDateString = [dateFormatter stringFromDate:_rssItem.date];
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        [self.dateTextView setText:_longDateString];
    } else {
        [self.dateTextView setText:_shortDateString];
    }
    
    [self.contentTextView setText:_rssItem.text];
}

- (IBAction)visitFullArticle:(id)sender {
    //TODO cant reproduce but some urls would give weird encoding (encoding url will lead to corrupt url)
    NSString *webStringURL = _rssItem.link;
    //Init FullArticleViewController which contains a UIWebView so we can visit the page
    FullArticleViewController *fullArticleViewController = [[FullArticleViewController alloc] initWithUrl:[NSURL URLWithString:webStringURL]];
    
    [self.navigationController pushViewController:fullArticleViewController animated:YES];
}

- (IBAction)shareOnSocialMedia:(id)sender {
    //if we have the following class it means we have ios6 or higher
    if (NSClassFromString(@"UIActivityViewController") ) {
        //share on different social media, email etc
        NSArray *activityItems = @[_rssItem.title, [NSURL URLWithString:_rssItem.link]];
        
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        [self presentViewController:activityController animated:YES completion:nil];
    } else {
        //TODO replace alert with code that will use different old-shool framework for twitter and facebook sharing
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry iOS 5 or lower doesn't have social media integrations" message:@"Upgrade to iOS 6 or higher to share this article." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //Set the correct datestring long or short according to the space we have
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ||
        toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        [self.dateTextView setText:_longDateString];
    } else if (toInterfaceOrientation == UIInterfaceOrientationPortrait ||
               toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        [self.dateTextView setText:_shortDateString];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
