 		//
//  AppDelegate.m
//  Q-municate
//
//  Created by Igor Alefirenko on 13/02/2014.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMAppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "QMCore.h"
#import "QMImages.h"
#import "QMHelpers.h"
#import "QMNetworkManager.h"
#import "DataManager.h"
#import "QMSplashViewController.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <DigitsKit/DigitsKit.h>
#import <Flurry.h>
#import <SVProgressHUD.h>
#import "OnboardingViewController.h"
#import "OnboardingContentViewController.h"
#import "MainAnimViewController.h"

static NSString * const kUserHasOnboardedKey = @"user_has_onboarded";

#define DEVELOPMENT 1

#if DEVELOPMENT == 1


// Production
static const NSUInteger kQMApplicationID = 52393;
static NSString * const kQMAuthorizationKey = @"cbL3q5BvSS2AWUH";
static NSString * const kQMAuthorizationSecret = @"rMtJW5gyH4YWMVZ";
static NSString * const kQMAccountKey = @"C8mpRE2Cs5qSfFBzxJ7Z";

#else

// Development
static const NSUInteger kQMApplicationID = 54473;
static NSString * const kQMAuthorizationKey = @"s5gmeUn9Vm5uyYx";
static NSString * const kQMAuthorizationSecret = @"xZRURTG8yQYPxRz";
static NSString * const kQMAccountKey = @"WiLzxzDjicsTfbu4vqhs";

#endif

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface QMAppDelegate () <QMPushNotificationManagerDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation QMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    BOOL userHasOnboarded = [[NSUserDefaults standardUserDefaults] boolForKey:kUserHasOnboardedKey];
    
    application.applicationIconBadgeNumber = 0;
    // Quickblox settings
    [QBSettings setApplicationID:kQMApplicationID];
    [QBSettings setAuthKey:kQMAuthorizationKey];
    [QBSettings setAuthSecret:kQMAuthorizationSecret];
    [QBSettings setAccountKey:kQMAccountKey];
    
    [QBSettings setAutoReconnectEnabled:YES];
    [QBSettings setCarbonsEnabled:YES];
    
#if DEVELOPMENT == 0
    [QBSettings setLogLevel:QBLogLevelNothing];
    [QBSettings disableXMPPLogging];
    [QMServicesManager enableLogging:NO];
#else
    [QBSettings setLogLevel:QBLogLevelDebug];
    [QBSettings enableXMPPLogging];
    [QMServicesManager enableLogging:YES];
#endif
    // QuickbloxWebRTC settings
    [QBRTCClient initializeRTC];
    [QBRTCConfig setICEServers:[[QMCore instance].callManager quickbloxICE]];
    [QBRTCConfig mediaStreamConfiguration].audioCodec = QBRTCAudioCodecISAC;
    [QBRTCConfig setStatsReportTimeInterval:0.0f]; // set to 1.0f to enable stats report
    
    // self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    // Configuring app appearance
    UIColor *mainTintColor = [UIColor colorWithRed:0.0866 green:0.6965 blue:0.9986 alpha:1.0];
    UIColor *tabBarTintColor = [UIColor colorWithRed:2 green:25 blue:33 alpha:1.0];
    UIImage *NavigationPortraitBackground = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    [[UINavigationBar appearance] setBackgroundImage:NavigationPortraitBackground forBarMetrics:UIBarMetricsDefault];
    [[UISearchBar appearance] setTintColor:mainTintColor];
    [[UITabBar appearance] setTintColor:tabBarTintColor];
    
    // Configuring searchbar appearance
    [[UISearchBar appearance] setSearchBarStyle:UISearchBarStyleMinimal];
    [[UISearchBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UISearchBar appearance] setBackgroundImage:QMStatusBarBackgroundImage() forBarPosition:0 barMetrics:UIBarMetricsDefault];
    
    [SVProgressHUD setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0.92f]];
    
    // Configuring external frameworks
    [Fabric with:@[CrashlyticsKit, DigitsKit, [Answers class]]];
    
    // Mixpanel
    [Mixpanel sharedInstanceWithToken:@"c18a386dd9a5f4f6c2a776905f2013b5"];

//    [[Mixpanel sharedInstance] track:@"Plan selected"
//         properties:@{ @"Plan": @"Premium" }];
    
    [Flurry startSession:@"CD6BBRJHMJ6PF6MHS5CG"];
//    [Flurry setBackgroundSessionEnabled:YES];
//    [Flurry setEventLoggingEnabled:YES];
//    [Flurry setLogLevel:FlurryLogLevelAll];
//    [Flurry logEvent:@"connect_to_chat" withParameters:@{@"app_id" : [NSString stringWithFormat:@"%tu", kQMApplicationID],
//                                                         @"chat_endpoint" : [QBSettings chatEndpoint]}];
    // Handling push notifications if needed
    if (launchOptions != nil) {
        NSDictionary *pushNotification = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        [QMCore instance].pushNotificationManager.pushNotification = pushNotification;
    }
    
    if (userHasOnboarded) {
        [self setupNormalRootViewController];
    }
    else {
        self.window.rootViewController = [self generateMovieOnboardingVC];
        
    }

    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}

- (void)setupNormalRootViewController {
    [self startUpdatingCurrentLocation];
     [self registerForNotification];
   QMSplashViewController* splashViewController = [[UIStoryboard storyboardWithName:@"Start" bundle:nil] instantiateViewControllerWithIdentifier:@"QMSplashViewController"];
    

    
    self.window.rootViewController = splashViewController;
}

- (void)handleOnboardingCompletion {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserHasOnboardedKey];
    
    // transition to the main application
    
    [self setupNormalRootViewController];
}

- (OnboardingViewController *)generateMovieOnboardingVC {
    OnboardingContentViewController *firstPage = [[OnboardingContentViewController alloc] initWithTitle:@"Welcome to Reach!" body:@"Never fight your problems on your own again. Join our vast community of positive influencers that are here for you." image:[UIImage imageNamed:@"logo-splash"] buttonText:nil action:nil];
    firstPage.topPadding = 70;
    firstPage.iconWidth = firstPage.view.frame.size.width*0.45;
    firstPage.iconHeight = firstPage.view.frame.size.width*0.45*182/219;
    firstPage.underTitlePadding = 70;
    firstPage.titleLabel.textColor = [UIColor whiteColor];
    firstPage.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:31.0];
    firstPage.bodyLabel.textColor = [UIColor whiteColor];
    firstPage.bodyLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:22.0];
    
    OnboardingContentViewController *secondPage = [[OnboardingContentViewController alloc] initWithTitle:@"Post your issue anonymously and help others!" body:@"Share your own post anonymously and get instant feedback." image:[UIImage imageNamed:@"logo-splash"] buttonText:nil action:nil];
    secondPage.viewDidAppearBlock = ^{
        [self startUpdatingCurrentLocation];
    };
    secondPage.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:29.0];
    secondPage.underTitlePadding = 60;
    secondPage.topPadding = 70;
    secondPage.iconWidth = firstPage.view.frame.size.width*0.45;
    secondPage.iconHeight = firstPage.view.frame.size.width*0.45*182/219;
    secondPage.titleLabel.textColor = [UIColor whiteColor];
    secondPage.bodyLabel.textColor = [UIColor whiteColor];
    secondPage.bodyLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:22.0];
    
    OnboardingContentViewController *thirdPage = [[OnboardingContentViewController alloc] initWithTitle:@"Chat with users in real time" body:@"Use our all in one chat system. Instant message or call positive people through our app. No phone numbers needed!" image:[UIImage imageNamed:@"logo-splash"] buttonText:nil action:nil];
    thirdPage.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:29.0];
    thirdPage.underTitlePadding = 60;
    thirdPage.topPadding = 70;
    thirdPage.iconWidth = firstPage.view.frame.size.width*0.45;
    thirdPage.iconHeight = firstPage.view.frame.size.width*0.45*182/219;
    thirdPage.titleLabel.textColor = [UIColor whiteColor];
    thirdPage.bodyLabel.textColor = [UIColor whiteColor];
    thirdPage.bodyLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:22.0];
    
    OnboardingContentViewController *forthPage = [[OnboardingContentViewController alloc] initWithTitle:@"Join Group Discussions" body:@"Find groups that interest you or create one yourself! Join and get notified if there are new posts." image:[UIImage imageNamed:@"logo-splash"] buttonText:nil action:nil];
    forthPage.topPadding = 70;
    forthPage.underTitlePadding = 70;
    forthPage.iconWidth = firstPage.view.frame.size.width*0.45;
    forthPage.iconHeight = firstPage.view.frame.size.width*0.45*182/219;
    forthPage.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:31.0];
    forthPage.titleLabel.textColor = [UIColor whiteColor];
    forthPage.bodyLabel.textColor = [UIColor whiteColor];
    forthPage.bodyLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:22.0];
    
    OnboardingContentViewController *fifthPage = [[OnboardingContentViewController alloc] initWithTitle:@"Positive People Only" body:@"Don't be a bully. Millions of people suffer daily; we are here to put an end to it. We must help one another." image:[UIImage imageNamed:@"logo-splash"] buttonText:@"Start" action:^{
        [self handleOnboardingCompletion];
    }];
    fifthPage.viewDidAppearBlock = ^{
        // Registering for remote notifications
        [self registerForNotification];
    };
    fifthPage.titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:31.0];
    fifthPage.underTitlePadding = 60;
    fifthPage.topPadding = 70;
    fifthPage.iconWidth = firstPage.view.frame.size.width*0.45;
    fifthPage.iconHeight = firstPage.view.frame.size.width*0.45*182/219;
    fifthPage.titleLabel.textColor = [UIColor whiteColor];
    fifthPage.bodyLabel.textColor = [UIColor whiteColor];
    fifthPage.bodyLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:22.0];
    fifthPage.actionButton.layer.borderColor = [UIColor whiteColor].CGColor;
    fifthPage.actionButton.layer.borderWidth = 2;
    fifthPage.actionButton.layer.cornerRadius = 4;
    fifthPage.actionButton.clipsToBounds = YES;
    
    [fifthPage.actionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@100);
        make.centerX.equalTo(fifthPage.view.mas_centerX);
        make.top.equalTo(fifthPage.bodyLabel.mas_bottom).offset(50);
    }];
    
    NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:@"Start" attributes:@{NSFontAttributeName :[UIFont fontWithName:@"AvenirNext-DemiBold" size:25.0],                                                                                                                                  NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [fifthPage.actionButton setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *moviePath = [bundle pathForResource:@"River" ofType:@"mp4"];
    NSURL *movieURL = [NSURL fileURLWithPath:moviePath];
    
    OnboardingViewController *onboardingVC = [[OnboardingViewController alloc] initWithBackgroundVideoURL:movieURL contents:@[firstPage, secondPage, thirdPage, forthPage, fifthPage]];
    onboardingVC.shouldFadeTransitions = YES;
    onboardingVC.shouldMaskBackground = YES;
    onboardingVC.pageControl.currentPageIndicatorTintColor = [UIColor babyBule];
    onboardingVC.pageControl.pageIndicatorTintColor = [UIColor whiteColor];
    
    return onboardingVC;
}

- (void)startUpdatingCurrentLocation
{
    if ([CLLocationManager locationServicesEnabled] == NO) {
        [self showDeniedLocation];
        return;
    }
    
    // if location services are restricted do nothing
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted)
    {
        return;
    }
    
    // if locationManager does not currently exist, create it
    if (self.locationManager == nil)
    {
        _locationManager = [[CLLocationManager alloc] init];
        (self.locationManager).delegate = self;
        self.locationManager.distanceFilter = 10.0f; // we don't need to be any more accurate than 10m
    }
    
    // for iOS 8 and later, specific user level permission is required,
    // "when-in-use" authorization grants access to the user's location
    //
    // important: be sure to include NSLocationWhenInUseUsageDescription along with its
    // explanation string in your Info.plist or startUpdatingLocation will not work.
    //
    [self.locationManager requestWhenInUseAuthorization];
    
    [self.locationManager startUpdatingLocation];
}

- (void) showDeniedLocation {
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    NSString *title;
    title = (status == kCLAuthorizationStatusDenied) ? @"Location services are off" : @"Location is not enabled";
    NSString *message = @"To use location you must turn on 'While Using the App' in the Location Services Settings";
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* Ok = [UIAlertAction
                         actionWithTitle:@"Continue"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * __unused action)
                         {
                             if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]  options:@{}
                                                          completionHandler:nil];
                             } else {
                                 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                             }
                             
                         }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancel"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * __unused action)
                             {
                                 
                             }];
    
    [alert addAction:Ok];
    [alert addAction:cancel];
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alert animated:YES completion:nil];
}

- (void) performPushfromNewsFeedAndGroups:(NSDictionary *)userInfo
{
    NSNumber* ID = userInfo[@"post_id"];
    NSString* title = @"Post";
    NSString* messageText = userInfo[@"aps"][@"alert"];
    NSString* avatar = userInfo[@"avatar"];
    if (ID == nil)
    {
        ID = userInfo[@"circle_id"];
        title = @"Group";
    }
    
    if  (ID == nil)
    {
        return;
    }
    
    [[PushManager instance] connectWithID:ID title:title message:messageText avatar:avatar];
}

- (void) gotoNewsFeedAndGroups:(NSDictionary *)userInfo
{
    NSNumber* ID = userInfo[@"post_id"];
    NSString* title = @"Post";
    if (ID == nil)
    {
        ID = userInfo[@"circle_id"];
        title = @"Group";
    }
    
    if  (ID == nil)
    {
        self.shouldShowNotification = @"";
        return;
    }
    
    self.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MainAnimNavigation"];
    
    UINavigationController* mainViewNavController = (UINavigationController*) self.window.rootViewController;
    UIViewController* mainController = mainViewNavController.topViewController;

    self.shouldShowNotification = title;
    if([title isEqualToString:@"Post"])
    {
       if(![mainController.presentedViewController.restorationIdentifier isEqualToString:@"NewsFeedMainNavigation"])
       {
           [mainController performSegueWithIdentifier:@"SceneSegueNews" sender:title];
       }
    } else {
        if(![mainController.presentedViewController.restorationIdentifier isEqualToString:@"GroupDetailNavigation"])
        {
             [mainController performSegueWithIdentifier:@"groups_segue" sender:title];
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"%ld", (long)application.applicationIconBadgeNumber);
    
//    NSInteger badgeNumber = application.applicationIconBadgeNumber;
//    
//    application.applicationIconBadgeNumber = badgeNumber + [[[userInfo objectForKey:@"aps"] objectForKey:@"badge"] intValue];
    
    NSLog(@"%ld", (long)application.applicationIconBadgeNumber);
    
    if (application.applicationState == UIApplicationStateInactive) {
        
        NSString *dialogID = userInfo[kQMPushNotificationDialogIDKey];
        if  (dialogID == nil){
            [self gotoNewsFeedAndGroups:userInfo];
            return;
        } else {
            NSString *activeDialogID = [QMCore instance].activeDialogID;
            if ([dialogID isEqualToString:activeDialogID] || dialogID == nil) {
                // dialog is already active
                return;
            }
            
            self.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MainAnimNavigation"];
            
            [QMCore instance].pushNotificationManager.pushNotification = userInfo;
            
            // calling dispatch async for push notification handling to have priority in main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                [[QMCore instance].pushNotificationManager handlePushNotificationWithDelegate:self];
            });
        }
    }
    
    if  (application.applicationState == UIApplicationStateActive)
    {
        [self performPushfromNewsFeedAndGroups:userInfo];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)__unused application {
    
    self.badgeNumber = [DataManager sharedManager].chatContactBadge + [DataManager sharedManager].chatDialogBadge + [DataManager sharedManager].newsFeedBadge + [DataManager sharedManager].GroupsBadge;
    application.applicationIconBadgeNumber = self.badgeNumber;
    
    [self.timer invalidate];
    [[QMCore instance].chatManager disconnectFromChatIfNeeded];
}

- (void)applicationWillEnterForeground:(UIApplication *)__unused application {
    
//    application.applicationIconBadgeNumber = 0;
    
    [[QMCore instance] login];
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

#pragma mark - Push notification registration

- (void)registerForNotification {    
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerForRemoteNotifications)])
    {
        UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        UIRemoteNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
    }
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    if (notificationSettings.types != UIUserNotificationTypeNone) {
        NSLog(@"didRegisterUser");
        [application registerForRemoteNotifications];
    }
}

- (void)application:(UIApplication *)__unused application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"%@", error.localizedDescription);
}

- (void)application:(UIApplication *)__unused application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    [QMCore instance].pushNotificationManager.deviceToken = deviceToken;
     [[DataManager sharedManager] setNotificationToken:[[[[NSString stringWithFormat:@"%@", deviceToken] stringByReplacingOccurrencesOfString:@"<" withString:@""] stringByReplacingOccurrencesOfString:@">" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""]];
}

- (void) setApplicationBadgeNumber: (NSInteger) appBadgeNumber
{
    [UIApplication sharedApplication].applicationIconBadgeNumber += appBadgeNumber;
}


#pragma mark - QMPushNotificationManagerDelegate protocol

- (void)pushNotificationManager:(QMPushNotificationManager *)__unused pushNotificationManager didSucceedFetchingDialog:(QBChatDialog *)chatDialog {
 
//    UINavigationController* splitNavController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatNavigation"];
// 
//    
//    UISplitViewController* splitController = [splitNavController viewControllers].firstObject;
//    
//    UITabBarController *tabBarController = [[splitController viewControllers] firstObject];
//    UIViewController *dialogsVC = [[(UINavigationController *)[[tabBarController viewControllers] firstObject] viewControllers] firstObject];
//    
//    NSString *activeDialogID = [QMCore instance].activeDialogID;
//    if ([chatDialog.ID isEqualToString:activeDialogID]) {
//        // dialog is already active
//        return;
//    }
    //   mainController.chatDialogFromPush = chatDialog;
    //    QMChatVC *chatVC = [QMChatVC chatViewControllerWithChatDialog:chatDialog];
    //    [mainViewNavController setNavigationBarHidden:NO];
    //    [mainViewNavController pushViewController:chatVC animated:YES];
    
    UINavigationController* mainViewNavController = (UINavigationController*) self.window.rootViewController;
    UIViewController* mainController = mainViewNavController.topViewController;

    [mainController performSegueWithIdentifier:@"ChatNavigation" sender:chatDialog];
}

#pragma mark LocationManager Delegate
- (void)locationManager:(CLLocationManager *) __unused manager
       didFailWithError:(NSError *)error
{
    NSLog(@"location error %@", error.localizedDescription);
}
-(void)locationManager:(CLLocationManager *)__unused manager didUpdateLocations:(NSArray *)locations{
    if([QMCore instance].currentProfile.userData == nil || [[TokenModel sharedInstance].token isEqualToString:@""]) return;
    
    CLLocation* location = [locations lastObject];
    
    NSDate* eventDate = location.timestamp;
    
    NSTimeInterval howRecent = [eventDate timeIntervalSinceDate:[QMNetworkManager sharedManager].lastLoggedDateTime];
    if (fabs(howRecent) > 15.0 || [[QMNetworkManager sharedManager].cityName isEqualToString:@""]) {
        NSLog(@"=====mangeer cityname %@, time%f=====", [QMNetworkManager sharedManager].cityName, howRecent);
        [QMNetworkManager sharedManager].lastLoggedDateTime = eventDate;
        
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
         {
             if(error) {
                 return;
             }
             CLPlacemark *placemark = [placemarks objectAtIndex:0];
             if([placemark.country length] != 0) {
                 [QMNetworkManager sharedManager].countryName = placemark.country;
             } else {
                 [QMNetworkManager sharedManager].countryName = @"";
             }
             if([placemark.locality length] != 0) {
                 [QMNetworkManager sharedManager].cityName = placemark.locality;
             } if([placemark.administrativeArea length] != 0) {
                 [QMNetworkManager sharedManager].stateName = placemark.administrativeArea;
             }
             else {
                 [QMNetworkManager sharedManager].cityName = @"";
             }
             
             
             [[QMNetworkManager sharedManager] updateLocate];
         }];
    }
 }

@end
