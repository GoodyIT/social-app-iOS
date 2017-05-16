//
//  AppDelegate.h
//  Q-municate
//
//  Created by Igor Alefirenko on 13/02/2014.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

@interface QMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) id rootViewController;

@property (strong,nonatomic) NSNumber *newMessages;
@property (strong,nonatomic) NSNumber *notifationsCount;
@property (assign,nonatomic) NSInteger badgeNumber;
@property (strong,nonatomic) NSString*  shouldShowNotification;
@property (nonatomic) NSTimer *timer;

- (NSNumber*) newMessages __attribute__((objc_method_family(none)));
-(void) setNewMessages:(NSNumber *)newMessages;

- (void) setNotifationsCount:(NSNumber *)notifationsCount;

- (void) setBadgeNumber:(NSInteger)badgeNumber;

- (void) setApplicationBadgeNumber: (NSInteger) appBadgeNumber;

- (void) startUpdatingCurrentLocation;

@end
