//
//  MyPagerViewController.m
//  reach-ios
//
//  Created by Admin on 2016-12-26.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "MyPagerViewController.h"
#import "MyPostViewController.h"
#import "NotificationViewController.h"

@interface MyPagerViewController ()
{
    NSInteger   selectedIndex;
    NSRange     rangeDisplay;
}

@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSArray* viewControllers;
@property (strong, nonatomic) NSArray* viewControllerIdentifiers;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tabIndicatorLeading;
@property (weak, nonatomic) IBOutlet UIView *myPageViwer;
@property (nonatomic, retain) XPageManager *                pageManager;

@end

@implementation MyPagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initializeData];
    [self prepareUI];
    [self gotoNotification:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)onBackAction:(id) __unused  sender {
    [self.view endEditing:YES];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void) initializeData
{
    self.viewControllerIdentifiers = @[@"NotificationViewController", @"MyPostViewContoller"];
    NotificationViewController* notificationController = [[UIStoryboard storyboardWithName:@"News" bundle:nil] instantiateViewControllerWithIdentifier:self.viewControllerIdentifiers[0]];
    MyPostViewController *myPostViewController = [[UIStoryboard storyboardWithName:@"News" bundle:nil] instantiateViewControllerWithIdentifier:self.viewControllerIdentifiers[1]];
    self.viewControllers = @[notificationController, myPostViewController];
    rangeDisplay = NSMakeRange(0, self.viewControllers.count);
    selectedIndex = 0;
    
    [self.navigationController tabBarItem].badgeValue = nil;
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

- (void) prepareUI
{
    UIImage *NavigationPortraitBackground = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    [[UINavigationBar appearance] setBackgroundImage:NavigationPortraitBackground forBarMetrics:UIBarMetricsDefault];
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

- (IBAction)gotoMyPost:(id) __unused sender {
    self.navigationItem.title = @"My Post";
    selectedIndex = 1;
    
    [self addView:self.viewControllers[1]];
    [self removeView:self.viewControllers[0]];
    
    [self updateTabStateWithAnimate:1];
}

- (IBAction)gotoNotification:(id) __unused sender {
    self.navigationItem.title = @"Notification";
    selectedIndex = 0;
    
    [self addView:self.viewControllers[0]];
    [self removeView:self.viewControllers[1]];
    [self updateTabStateWithAnimate:0];
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
