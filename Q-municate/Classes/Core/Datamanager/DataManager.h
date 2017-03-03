//
//  DataManager.h
//  Reach-iOS
//
//  Created by AlexFill on 23.02.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataManager : NSObject

+ (DataManager *)sharedManager;

@property (assign, nonatomic) NSString *notificationToken;
@property (copy, atomic) NSString *activeUserID;
@property (copy, atomic) NSString *username;
@property (copy, atomic) NSString *email;
@property (copy, atomic) NSString *password;
@property (strong, atomic) NSDictionary *messages;
@property (copy, atomic) NSString *avatar;
@property (strong, atomic) NSNumber *isCallRing;
@property (strong, atomic) NSNumber *isCallVibrate;

@property (assign, atomic) NSInteger chatContactBadge;
@property (assign, atomic) NSInteger chatDialogBadge;
@property (assign, atomic) NSInteger newsFeedBadge;
@property (assign, atomic) NSInteger GroupsBadge;
@property (assign, atomic) NSArray *myFriends;

@end
