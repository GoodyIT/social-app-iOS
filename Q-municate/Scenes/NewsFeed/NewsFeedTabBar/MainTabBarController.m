//
//  MainTabBarController.m
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/21/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import "MainTabBarController.h"
#import "NotificationViewController.h"
#import "TokenModel.h"

@interface MainTabBarController ()

@property (weak, nonatomic) BFTask *task;

@end

@implementation MainTabBarController

- (void)viewDidLoad {
    NSLog(@"MainTabBarController");
    
    [super viewDidLoad];
    
    if ([[TokenModel sharedInstance].token isEqualToString:@""]) {
        [self pushToStartViewController];
    }
    
    [self updateBadge:NO];
    [self prepareUI];
    
    @weakify(self)
    // adding notification for showing chat connection
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationWillEnterForegroundNotification
     object:nil
     queue:nil
     usingBlock:^(NSNotification * _Nonnull __unused note) {
         @strongify(self);
          [self changeToNotification];
     }];
}

- (void) changeToNotification
{
    if([@"Post" isEqualToString: self.pushType])
    {
        self.selectedIndex = 2;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self changeToNotification];
    [self.navigationController setNavigationBarHidden:YES];
}

#pragma mark - Private

- (void)prepareUI {
    UIImage *NavigationPortraitBackground = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    [[UINavigationBar appearance] setBackgroundImage:NavigationPortraitBackground forBarMetrics:UIBarMetricsDefault];
}

- (void)pushToStartViewController {
    UINavigationController *mainController = [self.storyboard instantiateViewControllerWithIdentifier:@"QMSplashViewController"];
    [UIView transitionWithView:[[UIApplication sharedApplication] delegate].window
                      duration:0.5
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        [[[UIApplication sharedApplication] delegate].window setRootViewController:mainController];
                    }
                    completion:nil];
}

- (void)updateBadge: (BOOL) fromPush {
    [super updateBadge: fromPush];
    
    if (fromPush) {
        [DataManager sharedManager].newsFeedBadge += 1;
    }
    
    NSLog(@"news feed badge %ld", (long)[DataManager sharedManager].newsFeedBadge);
    
    UINavigationController *notificationViewController = (UINavigationController *)[self.childViewControllers objectAtIndex:2];
    notificationViewController.tabBarItem.badgeValue =  [NSString stringWithFormat:@"%ld", (long)[DataManager sharedManager].newsFeedBadge];
    
    if ([DataManager sharedManager].newsFeedBadge == 0) {
        notificationViewController.tabBarItem.badgeValue = nil;
    }
}

@end
