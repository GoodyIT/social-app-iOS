//
//  NotificationModel.h
//  Reach-iOS
//
//  Created by Oleksandr Burla on 4/4/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NotificationModel : NSObject


@property (strong, nonatomic) NSNumber *notificationID;
@property (strong, nonatomic) NSNumber *userID;
@property (copy, nonatomic) NSString *username;
@property (copy, nonatomic) NSString *date;
@property (copy, nonatomic) NSString *image;
@property (copy, nonatomic) NSString *action;
@property (copy, nonatomic) NSString *commentText;
@property (strong, nonatomic) NSNumber *requestID;
@property (strong, nonatomic) NSNumber *readState;

@property (strong, nonatomic) NSDictionary *objectOfResponse;  // использовать для передачи поста по segue

+ (NotificationModel *)getNotificationInfoFromResponse:(NSDictionary *)response;
+ (NSArray *)getNotificationListFromResponse:(NSDictionary *)response;

@end
