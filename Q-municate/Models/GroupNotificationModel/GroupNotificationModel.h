//
//  NotificationModel.h
//  Reach-iOS
//
//  Created by Oleksandr Burla on 4/4/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GroupNotificationModel : NSObject


@property (strong, nonatomic) NSNumber *notificationID;
@property (strong, nonatomic) NSNumber *groupID;
@property (strong, nonatomic) NSNumber *userID;
@property (copy, nonatomic) NSString *username;
@property (copy, nonatomic) NSString *date;
@property (copy, nonatomic) NSString *image;
@property (copy, nonatomic) NSNumber *notitype;
@property (copy, nonatomic) NSString* detail;
@property (copy, nonatomic) NSString* topic;
@property (strong, nonatomic) NSNumber *readState;

+ (GroupNotificationModel *)getNotificationInfoFromResponse:(NSDictionary *)response;
+ (NSArray *)getNotificationListFromResponse:(NSDictionary *)response;

@end
