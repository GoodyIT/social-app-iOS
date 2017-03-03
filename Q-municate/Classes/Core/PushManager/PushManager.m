//
//  PushManager.m
//  reach-ios
//
//  Created by Admin on 2017-01-10.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import "PushManager.h"

@interface PushManager()
{
    NSHashTable *delegates;
}

@end

@implementation PushManager

+ (instancetype)instance {
    
    static PushManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        manager = [[self alloc] init];
    });
    
    return manager;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        delegates = [NSHashTable weakObjectsHashTable];
    }
    
    return self;
}

- (void) connectWithID:(NSNumber*) ID title:(NSString*) title message:(NSString*) messageText avatar:(NSString*) avatar
{
    if (delegates.count > 1) {
        for (id delegate in delegates) {
            if(/*![delegate isKindOfClass:[UITabBarController class]] && */[delegate respondsToSelector:@selector(didRecieveReachPushNotification:ID:title:message:avatar:)])
            {
                [delegate didRecieveReachPushNotification:nil ID:ID title:title message:messageText avatar:avatar];
            }
        }
    } else {
        for (id delegate in delegates) {
            if( [delegate respondsToSelector:@selector(didRecieveReachPushNotification:ID:title:message:avatar:)])
            {
                [delegate didRecieveReachPushNotification:nil ID:ID title:title message:messageText avatar:avatar];
                
            }
        }
    }
}

#pragma mark - Add / Remove Multicast delegate

- (void)addDelegate:(id<ReachServiceDelegate>)delegate {
    
    [delegates addObject:delegate];
}

- (void)removeDelegate:(id<ReachServiceDelegate>)__unused delegate {
    
    [delegates removeObject:delegate];
}

@end
