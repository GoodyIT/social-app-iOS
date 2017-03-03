//
//  MyGroupPagerController.m
//  reach-ios
//
//  Created by Admin on 2016-12-28.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "MyGroupPagerController.h"
#import "GroupCell.h"
#import "UserProfileViewController.h"
#import "GroupsViewController.h"
#import "GroupDetailViewController.h"
#import "MyJoinedGroupViewController.h"
#import "MyCreatedGroupViewController.h"

@interface MyGroupPagerController ()
{
    NSInteger   selectedIndex;
    __block BOOL isBottomRefreshing;
    BOOL isFirstLoading;
    NSRange     rangeDisplay;
}

@property (strong, nonatomic) NSArray* viewControllers;
@property (strong, nonatomic) NSArray* viewControllerIdentifiers;
@property (weak, nonatomic) IBOutlet UIView *myPageViwer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tabIndicatorLeading;

@end

@implementation MyGroupPagerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self prepareUI];
    [self initializeData];
    [self gotoMyCreatedGroups:nil];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onBackAction:(id)__unused  sender {
    [self.view endEditing:YES];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void) prepareUI
{
    UIImage *NavigationPortraitBackground = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    [[UINavigationBar appearance] setBackgroundImage:NavigationPortraitBackground forBarMetrics:UIBarMetricsDefault];
}

- (void) initializeData
{
    self.viewControllerIdentifiers = @[@"MyCreatedGroupViewController", @"MyJoinedGroupViewController"];
    MyCreatedGroupViewController * myCreatedGroupVC = [[UIStoryboard storyboardWithName:@"Groups" bundle:nil] instantiateViewControllerWithIdentifier:self.viewControllerIdentifiers[0]];
    MyJoinedGroupViewController *myJoinedGroupVC = [[UIStoryboard storyboardWithName:@"Groups" bundle:nil] instantiateViewControllerWithIdentifier:self.viewControllerIdentifiers[1]];
    self.viewControllers = @[myCreatedGroupVC, myJoinedGroupVC];
    rangeDisplay = NSMakeRange(0, self.viewControllers.count);
    selectedIndex = 0;

    [DataManager sharedManager].newsFeedBadge = 0;
}

- (void) addView: (UIViewController*) viewController
{
    [self addChildViewController:viewController];
    [self.myPageViwer addSubview:viewController.view];
    viewController.view.frame = CGRectMake(0, 0, self.myPageViwer.frame.size.width, self.myPageViwer.frame.size.height);
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [viewController didMoveToParentViewController:self];
}

- (void) removeView: (UIViewController*) viewController
{
    [viewController willMoveToParentViewController:nil];
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
}

- (void) updateTabStateWithAnimate:(NSInteger)index {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [UIView animateWithDuration:0.3f animations:^{
            [self updateTabState:index];
        } completion:^(BOOL __unused finished) {
            
        }];
    });
}

- (void) updateTabState:(NSInteger)tab {
    CGFloat width = CGRectGetWidth(self.view.frame)/2;
    self.tabIndicatorLeading.constant = tab * width;
}

- (IBAction)gotoMyJoinedGroups:(id)  __unused sender {
    self.navigationItem.title = @"Joined Groups";
    selectedIndex = 1;
    
    [self addView:self.viewControllers[1]];
    [self removeView:self.viewControllers[0]];
    
    [self updateTabStateWithAnimate:1];
}

- (IBAction)gotoMyCreatedGroups:(id)  __unused sender {
    self.navigationItem.title = @"Created Groups";
    selectedIndex = 0;
    
    [self addView:self.viewControllers[0]];
    [self removeView:self.viewControllers[1]];
    [self updateTabStateWithAnimate:0];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

@end
