//
//  DataManager.m
//  Reach-iOS
//
//  Created by AlexFill on 23.02.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "DataManager.h"

@implementation DataManager

+ (DataManager *)sharedManager {
    static DataManager *manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DataManager alloc] init];
    });
    
    return manager;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.newsFeedBadge = 0;
        self.chatDialogBadge = 0;
        self.chatContactBadge = 0;
        self.GroupsBadge = 0;
    }
    
    return self;
}

- (void)setNotificationToken:(NSString *)notificationToken {
    [[NSUserDefaults standardUserDefaults] setObject:notificationToken forKey:@"notificationToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)notificationToken {
    return [[[[NSString stringWithFormat:@"%@", [QMCore instance].pushNotificationManager.deviceToken]  stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (void)setActiveUserID:(NSString *)activeUserID {
    [[NSUserDefaults standardUserDefaults] setObject:activeUserID forKey:@"activeUserID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)activeUserID {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"activeUserID"];
}

- (void) setPassword:(NSString *)password
{
    [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*) password {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
}

- (void) setUsername:(NSString *)username
{
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*) username
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
}

- (void) setEmail:(NSString *)email
{
    [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"username"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*) email
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
}

- (void)setMessages:(NSMutableDictionary *)messages {
    [[NSUserDefaults standardUserDefaults] setObject:messages forKey:@"messages"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDictionary *)messages {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"messages"];
}

- (void)setIsCallRing:(NSNumber *)isCallRing {
    [[NSUserDefaults standardUserDefaults] setObject:isCallRing forKey:@"isCallRing"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumber *)isCallRing {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"isCallRing"];
}

- (void)setIsCallVibrate:(NSNumber *)isCallVibrate {
    [[NSUserDefaults standardUserDefaults] setObject:isCallVibrate forKey:@"isCallVibrate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumber *)isCallVibrate {
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"isCallVibrate"];
}

@end
