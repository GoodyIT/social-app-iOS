//
//  NotificationModel.m
//  Reach-iOS
//
//  Created by Oleksandr Burla on 4/4/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "GroupNotificationModel.h"

@implementation GroupNotificationModel


+ (NSArray *)getNotificationListFromResponse:(NSDictionary *)response {
    NSMutableArray *notifications = [[NSMutableArray alloc] init];
    
    for (NSDictionary *notificationDictionary in [response valueForKey:@"notifications"]) {
        GroupNotificationModel* notificationModel = [GroupNotificationModel getNotificationInfoFromResponse:notificationDictionary];
        if  (notificationModel != nil)
        {
            [notifications addObject:notificationModel];
        }
    }
    
    return notifications;
}

+ (GroupNotificationModel *)getNotificationInfoFromResponse:(NSDictionary *)response {
    GroupNotificationModel *notification = [GroupNotificationModel new];
    
    notification.notificationID = [response objectForKey:@"id"];
    notification.groupID = [response objectForKey:@"circle"];
    NSDictionary* otherUser = [response objectForKey:@"otheruser"];
    notification.userID = [otherUser objectForKey:@"id"];
    notification.username = [otherUser objectForKey:@"username"];
    notification.readState = [response objectForKey:@"read"];
    
    NSString* fullDate = [response objectForKey:@"date"];
    NSString* timeString = [fullDate substringToIndex:5];
    NSRange range = NSMakeRange(8, 11);
    NSString* dateString = [fullDate substringWithRange:range];
    dateString = [dateString stringByReplacingOccurrencesOfString:@":" withString:@"."];

    notification.date = [NSString stringWithFormat:@"%@ at %@", dateString, timeString];
    
    
    //////
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss MM/dd/yyyy"];
    NSLog(@"Time Zone :%ld", (long)[[NSTimeZone localTimeZone] secondsFromGMT]);
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
        notification.date = [NSString stringWithFormat:@"%ld year(s) ago", (long)conversionInfo.year];
    } else if (conversionInfo.month > 0) {
        notification.date = [NSString stringWithFormat:@"%ld month ago", (long)conversionInfo.month];
    } else if (conversionInfo.day > 0) {
        notification.date = [NSString stringWithFormat:@"%ld day(s) ago", (long)conversionInfo.day];
    } else if (conversionInfo.hour > 0) {
       notification.date = [NSString stringWithFormat:@"%ld hours ago", (long)conversionInfo.hour];
    } else if (conversionInfo.minute ) {
        notification.date = [NSString stringWithFormat:@"%ld minutes ago", (long)conversionInfo.minute];
    } else  if (conversionInfo.second ){
        notification.date = [NSString stringWithFormat:@"%ld seconds ago", (long)conversionInfo.second ];
    } else {
        notification.date = @"Now";
    }
    
    notification.image = [[otherUser objectForKey:@"info"] objectForKey:@"avatar"];
    notification.notitype = [response objectForKey:@"notitype"];
    notification.detail = [response objectForKey:@"detail"];
    notification.topic = [response objectForKey:@"topic"];
    
    return notification;
}

@end
