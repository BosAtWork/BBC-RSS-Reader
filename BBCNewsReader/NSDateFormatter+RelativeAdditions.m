//
//  NSDateFormatter+NSDateFormatterRelativeAdditions.m
//  RssReader
//
//  Created by Frank Bos on 5/4/13.
//  Copyright (c) 2013 automaticoo. All rights reserved.
//

#import "NSDateFormatter+RelativeAdditions.h"

@implementation NSDateFormatter (RelativeAdditions)

//C-objective implementation of Stack Overflow relativity
//Implementation found on http://stackoverflow.com/questions/11/how-do-i-calculate-relative-time
- (NSString *)relativeStringFromDate:(NSDate *)date {
    const int SECOND = 1;
    const int MINUTE = 60 * SECOND;
    const int HOUR = 60 * MINUTE;
    const int DAY = 24 * HOUR;
    //const int MONTH = 30 * DAY;
    
    NSDate *now = [NSDate date];
    NSTimeInterval delta = [date timeIntervalSinceDate:now] * -1.0;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger units = (NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit);
    NSDateComponents *components = [calendar components:units fromDate:date toDate:now options:0];
    
    NSString *dateString;
    
    if (delta < 0) {
        dateString = @"not yet";
    } else if (delta < 1 * MINUTE) {
        dateString = (components.second == 1) ? @"one second ago" : [NSString stringWithFormat:@"%d seconds ago", components.second];
    } else if (delta < 2 * MINUTE) {
        dateString =  @"a minute ago";
    } else if (delta < 45 * MINUTE) {
        dateString = [NSString stringWithFormat:@"%d minutes ago", components.minute];
    } else if (delta < 90 * MINUTE) {
        dateString = @"an hour ago";
    } else if (delta < 24 * HOUR) {
        dateString = [NSString stringWithFormat:@"%d hours ago", components.hour];
    } else if (delta < 48 * HOUR) {
        dateString = @"yesterday";
    } else if (delta < 30 * DAY) {
        dateString = [NSString stringWithFormat:@"%d days ago", components.day];
    } else {
        //here we do a different approach than stackoverflow because we want a hard date after a month
        dateString = [self stringFromDate:date];
    }
    
    return dateString;
}

@end
