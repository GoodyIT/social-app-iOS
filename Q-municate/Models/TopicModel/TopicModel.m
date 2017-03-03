//
//  TopicModel.m
//  Reach-iOS
//
//  Created by AlexFill on 02.02.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "TopicModel.h"
#import "CommentModel.h"


@implementation TopicModel

+ (TopicModel *)getTopicFromResponse:(NSDictionary *)response {
    TopicModel *topic = [TopicModel new];
    
    topic.topicID = [response valueForKey:@"id"];
    topic.author = [UserModel getUserWithResponce:[response valueForKey:@"author"]];
    topic.topicText = [response valueForKey:@"text"];
    topic.permission = [response valueForKey:@"permission"];
    topic.date = [response valueForKey:@"date"];
    
    NSString* fullDate = [response objectForKey:@"date"];
    //////
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss yyyy:MM:dd"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:[[NSTimeZone localTimeZone] secondsFromGMT]/3600]];//[NSTimeZone timeZoneForSecondsFromGMT:2]];//[/[NSTimeZone systemTimeZone]];
    //[formatter setLocale:[NSLocale currentLocale]];
    
    NSDate *creationDate = [formatter dateFromString:fullDate];
    
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    unsigned int unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitSecond | NSCalendarUnitYear;
    NSDateComponents *conversionInfo = [sysCalendar components:unitFlags fromDate:creationDate  toDate:[NSDate date] options:0];
    
    //16:55:32 2016:03:16
    //postInfo.
    //self.postTimeLabel.text
    if (conversionInfo.year > 0) {
        topic.date = [NSString stringWithFormat:@"%ld years", (long)conversionInfo.year];
    } else if (conversionInfo.month > 0) {
        topic.date = [NSString stringWithFormat:@"%ld months", (long)conversionInfo.month];
    } else if (conversionInfo.day > 0) {
        topic.date = [NSString stringWithFormat:@"%ld days", (long)conversionInfo.day];
    } else if (conversionInfo.hour > 0) {
        topic.date = [NSString stringWithFormat:@"%ld hours", (long)conversionInfo.hour];
    } else if (conversionInfo.minute ) {
        topic.date = [NSString stringWithFormat:@"%ld minutes", (long)conversionInfo.minute ];
    } else  if (conversionInfo.second ){
        topic.date = [NSString stringWithFormat:@"%ld seconds", (long)conversionInfo.second ];
    } else {
        topic.date = @"Now";
    }
    
    topic.replies = [CommentModel getCommentsListFromResponse:[response valueForKey:@"replies"]];
    
    return topic;
}

+ (NSArray *)getTopicListFromResponse:(NSDictionary *)response {
    NSMutableArray *topics = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dictionary in response) {
        [topics addObject:[TopicModel getTopicFromResponse:dictionary]];
    }
    
    return topics;
}



@end
