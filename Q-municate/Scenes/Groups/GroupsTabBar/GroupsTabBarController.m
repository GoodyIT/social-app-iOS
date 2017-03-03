//
//  GroupsTabBarController.m
//  reach-ios
//
//  Created by Admin on 2016-12-27.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "GroupsTabBarController.h"
#import "MyGroupPagerController.h"
#import "GroupNotificationController.h"

@interface GroupsTabBarController ()

@end

@implementation GroupsTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self prepareUI];
    [self updateBadge:NO];
    
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
    if([@"Group" isEqualToString: self.pushType])
    {
        self.selectedIndex = 2;
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self changeToNotification];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateBadge:(BOOL)fromPush
{
    [super updateBadge:fromPush];
    
    if (fromPush) {
        [DataManager sharedManager].GroupsBadge += 1;
    }
    
    UINavigationController *notificationNavigationController = (UINavigationController *)[self.childViewControllers objectAtIndex:2];

    if ([DataManager sharedManager].GroupsBadge == 0) {
        notificationNavigationController.tabBarItem.badgeValue = nil;
    } else {
        notificationNavigationController.tabBarItem.badgeValue =  [NSString stringWithFormat:@"%ld", (long)[DataManager sharedManager].GroupsBadge];
    }
}

#pragma mark - Private

- (void)prepareUI {
    UIImage *NavigationPortraitBackground = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    [[UINavigationBar appearance] setBackgroundImage:NavigationPortraitBackground forBarMetrics:UIBarMetricsDefault];
    
    UIColor *tabBarTintColor = [UIColor colorWithRed:2 green:25 blue:33 alpha:1.0];
    [[UITabBar appearance] setTintColor:tabBarTintColor];
    
    self.navigationController.navigationBarHidden = YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
