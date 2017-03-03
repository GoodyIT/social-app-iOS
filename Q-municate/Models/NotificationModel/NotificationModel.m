//
//  NotificationModel.m
//  Reach-iOS
//
//  Created by Oleksandr Burla on 4/4/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "NotificationModel.h"

@implementation NotificationModel


+ (NSArray *)getNotificationListFromResponse:(NSDictionary *)response {
    NSMutableArray *notifications = [[NSMutableArray alloc] init];
    
    for (NSDictionary *notificationDictionary in [response valueForKey:@"feed"]) {
        NotificationModel* notificationModel = [NotificationModel getNotificationInfoFromResponse:notificationDictionary];
        if  (notificationModel != nil)
        {
             [notifications addObject:notificationModel];
        }
    }
    
    return notifications;
}

+ (NotificationModel *)getNotificationInfoFromResponse:(NSDictionary *)response {
    NotificationModel *notification = [NotificationModel new];
    
    notification.objectOfResponse = [response objectForKey:@"object"];
    
    notification.requestID = [[response objectForKey:@"object"] objectForKey:@"id"];
    notification.notificationID = [response objectForKey:@"id"];
    NSDictionary* actionUser = [response objectForKey:@"action_user"];
    notification.userID = [actionUser objectForKey:@"id"];
    notification.username = [actionUser objectForKey:@"username"];
    notification.image = [[actionUser objectForKey:@"info"] objectForKey:@"avatar"];
    notification.action = [response objectForKey:@"action"];
    
    notification.readState = [response objectForKey:@"read"];
    
    if  ([notification.action isEqualToString:@"PostCommentComment"] || [notification.action isEqualToString:@"PostComment"] || [notification.action isEqualToString:@"UpVote"] || [notification.action isEqualToString:@"DownVote"])
    {
        notification.commentText = [response objectForKey:@"comment_comment"];
    } 
    
    NSString* fullDate = [response objectForKey:@"date"];
    NSString* timeString = [fullDate substringToIndex:5];
    NSRange range = NSMakeRange(8, 11);
    NSString* dateString = [fullDate substringWithRange:range];
    dateString = [dateString stringByReplacingOccurrencesOfString:@":" withString:@"."];

    notification.date = [NSString stringWithFormat:@"%@ at %@", dateString, timeString];
    
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
        notification.date = [NSString stringWithFormat:@"%ld year(s)", (long)conversionInfo.year];
    } else if (conversionInfo.month > 0) {
        notification.date = [NSString stringWithFormat:@"%ld month(s)", (long)conversionInfo.month];
    } else if (conversionInfo.day > 0) {
        notification.date = [NSString stringWithFormat:@"%ld day(s)", (long)conversionInfo.day];
    } else if (conversionInfo.hour > 0) {
       notification.date = [NSString stringWithFormat:@"%ld hours", (long)conversionInfo.hour];
    } else if (conversionInfo.minute ) {
        notification.date = [NSString stringWithFormat:@"%ld minutes", (long)conversionInfo.minute ];
    } else  if (conversionInfo.second ){
        notification.date = [NSString stringWithFormat:@"%ld seconds", (long)conversionInfo.second ];
    } else {
        notification.date = @"Now";
    }
    

   
    return notification;
}

@end
