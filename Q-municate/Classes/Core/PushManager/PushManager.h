//
//  PushManager.h
//  reach-ios
//
//  Created by Admin on 2017-01-10.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ReachServiceDelegate;

@interface PushManager : NSObject

+ (PushManager*) instance;

- (void)addDelegate:(id<ReachServiceDelegate>)delegate;
- (void)removeDelegate:(id<ReachServiceDelegate>)delegate;

- (void) connectWithID:(NSNumber*) ID title:(NSString*) title message:(NSString*) messageText avatar:(NSString*) avatar;

@end

@protocol ReachServiceDelegate
- (void) didRecieveReachPushNotification:(PushManager*) manager ID:(NSNumber*)ID title:(NSString*) title message:(NSString*) messageText avatar:(NSString*) avatar;
@end


