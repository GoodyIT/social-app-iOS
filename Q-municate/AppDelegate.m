//
//  AppDelegate.m
//  Q-municate
//
//  Created by Igor Alefirenko on 13/02/2014.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "AppDelegate.h"
#import "REAlertView+QMSuccess.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "QMChatVC.h"
#import "QMCore.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <DigitsKit/DigitsKit.h>
#import <Flurry.h>


#define DEVELOPMENT 1

#if DEVELOPMENT == 0

// Production
const NSUInteger kQMApplicationID = 13318;
NSString *const kQMAuthorizationKey = @"WzrAY7vrGmbgFfP";
NSString *const kQMAuthorizationSecret = @"xS2uerEveGHmEun";
NSString *const kQMAccountKey = @"6Qyiz3pZfNsex1Enqnp7";

#else

// Development
const NSUInteger kQMApplicationID = 36125;
NSString *const kQMAuthorizationKey = @"gOGVNO4L9cBwkPE";
NSString *const kQMAuthorizationSecret = @"JdqsMHCjHVYkVxV";
NSString *const kQMAccountKey = @"6Qyiz3pZfNsex1Enqnp7";

#endif

@interface AppDelegate () <QMPushNotificationManagerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    application.applicationIconBadgeNumber = 0;
    
    // Quickblox settings
    [QBSettings setApplicationID:kQMApplicationID];
    [QBSettings setAuthKey:kQMAuthorizationKey];
    [QBSettings setAuthSecret:kQMAuthorizationSecret];
    [QBSettings setAccountKey:kQMAccountKey];
    
    [QBSettings setChatDNSLookupCacheEnabled:YES];
    [QBSettings setAutoReconnectEnabled:YES];
    [QBSettings setCarbonsEnabled:YES];
    
#if DEVELOPMENT == 0
    [QBSettings setLogLevel:QBLogLevelNothing];
    [QBSettings disableXMPPLogging];
#else
    [QBSettings setLogLevel:QBLogLevelDebug];
    [QBSettings enableXMPPLogging];
#endif
    
    // QuickbloxWebRTC settings
    [QBRTCClient initializeRTC];
    [QBRTCConfig setICEServers:[[QMCore instance].callManager quickbloxICE]];
    [QBRTCConfig mediaStreamConfiguration].audioCodec = QBRTCAudioCodecISAC;
    [QBRTCConfig setStatsReportTimeInterval:0.0f]; // set to 1.0f to enable stats report
    
    // Registering for remote notifications
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    // Configuring app appearance
    UIColor *mainTintColor = [UIColor colorWithRed:13.0f/255.0f green:112.0f/255.0f blue:179.0f/255.0f alpha:1.0f];
    [[UINavigationBar appearance] setTintColor:mainTintColor];
    [[UISearchBar appearance] setTintColor:mainTintColor];
    [[UITabBar appearance] setTintColor:mainTintColor];
    
    // Configuring external frameworks
    [Fabric with:@[CrashlyticsKit, DigitsKit]];
    [Flurry startSession:@"P8NWM9PBFCK2CWC8KZ59"];
    
    // Handling push notifications if needed
    if (launchOptions != nil) {
        
        NSDictionary *pushNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        [QMCore instance].pushNotificationManager.pushNotification = pushNotification;
    }
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    if (application.applicationState == UIApplicationStateInactive) {
        
        NSString *dialogID = userInfo[kQMPushNotificationDialogIDKey];
        NSString *activeDialogID = [QMCore instance].activeDialogID;
        if ([dialogID isEqualToString:activeDialogID]) {
            // dialog is already active
            return;
        }
        
        [QMCore instance].pushNotificationManager.pushNotification = userInfo;
        
        // calling dispatch async for push notification handling to have priority in main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[QMCore instance].pushNotificationManager handlePushNotificationWithDelegate:self];
        });
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    application.applicationIconBadgeNumber = 0;
    [[QMCore instance].chatManager disconnectFromChatIfNeeded];
}

- (void)applicationWillEnterForeground:(UIApplication *)__unused application {
    
    if ([QMCore instance].currentProfile.userData && ![QBChat instance].isConnected) {
        
        [[QMCore instance].chatService connect];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)__unused application {
    
    [FBSDKAppEvents activateApp];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    BOOL urlWasIntendedForFacebook = [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                                    openURL:url
                                                                          sourceApplication:sourceApplication
                                                                                 annotation:annotation];
    
    return urlWasIntendedForFacebook;
}


#pragma mark - PUSH NOTIFICATIONS REGISTRATION

- (void)application:(UIApplication *)__unused application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    [QMCore instance].pushNotificationManager.deviceToken = deviceToken;
}

#pragma mark - QMPushNotificationManagerDelegate protocol

- (void)pushNotificationManager:(QMPushNotificationManager *)__unused pushNotificationManager didSucceedFetchingDialog:(QBChatDialog *)chatDialog {
    
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    
    NSString *activeDialogID = [QMCore instance].activeDialogID;
    if ([chatDialog.ID isEqualToString:activeDialogID]) {
        // dialog is already active
        return;
    }
    
    QMChatVC *chatVC = [QMChatVC chatViewControllerWithChatDialog:chatDialog];
    [navigationController pushViewController:chatVC animated:YES];
}

@end
