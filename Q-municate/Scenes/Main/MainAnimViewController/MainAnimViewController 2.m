//
//  MainAnimViewController.m
//  Reach-iOS
//
//  Created by VICTOR on 8/28/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "MainAnimViewController.h"
#import "QMAppDelegate.h"
//#import "MainTabBarController.h"
//#import "CallsViewController.h"
//#import "IncomingCallViewController.h"
//#import "OutcomingCallViewController.h"
//#import "PushNotificationManager.h"
//#import "MYChatNavViewController.h"
//#import "MyChatViewController.h"
//#import "ChatRecentViewController.h"
//#import "ChatTabBarController.h"
//#import "ChatRequestViewController.h"
#import "QMTabBarVC.h"
#import "QMNotification.h"
#import "QMCore.h"
#import "QMChatVC.h"
#import "QMSoundManager.h"
#import "QBChatDialog+OpponentID.h"
#import "QMHelpers.h"
#import "QMRequestViewController.h"
#import "QMDialogsViewController.h"
#import "AllPostViewController.h"


#import "UIButton+Badge.h"

@import AVFoundation;
@import AVKit;

static const NSInteger kQMUnAuthorizedErrorCode = -1011;

@interface MainAnimViewController () {
    UIActivityIndicatorView *waitingView;
    NSArray *btn_array;
    NSArray *segue_identifies;
    double delat_x;
    
    NSMutableArray *qbUserArray;
    
    BOOL goToChatFlag;
 //   QBChatDialog *chatDialog;
}

@property (weak, nonatomic) IBOutlet UILabel *chatBadgeLabel;
@property (weak, nonatomic) IBOutlet UIView *chatBadgeView;
@property (weak, nonatomic) IBOutlet UIButton *newsfeedBtn;
@property (weak, nonatomic) IBOutlet UIButton *chatBtn;

@property (weak, nonatomic) IBOutlet UIButton *groupsBtn;

@property (weak, nonatomic) BFTask *loginTask;

@end

@implementation MainAnimViewController
@synthesize newsfeed_top;
@synthesize newsfeed_leading;
@synthesize calls_top;
@synthesize calls_leading;
@synthesize Messages_top;
@synthesize Messages_leading;
@synthesize locate_top;
@synthesize locate_leading;
@synthesize circles_top;
@synthesize circles_leading;
@synthesize setting_top;
@synthesize settting_leading;
@synthesize journal_top;
@synthesize journal_leading;
@synthesize group_top;
@synthesize group_leading;
@synthesize mainView;
@synthesize newsView;
@synthesize callsView;
@synthesize messagesView;
@synthesize locateView;
@synthesize circleView;
@synthesize settingView;
@synthesize journalView;
@synthesize groupView;

static MainAnimViewController *instance = nil;
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self performAutoLoginAndFetchData];
    
    @weakify(self)
    // adding notification for showing chat connection
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationWillEnterForegroundNotification
     object:nil
     queue:nil
     usingBlock:^(NSNotification * _Nonnull __unused note) {
         @strongify(self);
         [self updateChatBadge];
         [self updateNewsFeedBadge];
         [self updateGroupsBadge];
     }];
    
    // Do nay additional setup
    UIImage *NavigationPortraitBackground = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    [[UINavigationBar appearance] setBackgroundImage:NavigationPortraitBackground forBarMetrics:UIBarMetricsDefault];
    
     instance = self;
    // Do any additional setup after loading the view.
    
    [self initializeData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL) animated {
//    [((QMAppDelegate*)[UIApplication sharedApplication]) startUpdatingCurrentLocation];
    [super viewWillAppear:animated];
    [self updateGroupsBadge];
    
//    [self updateChatBadge];
//    [self updateNewsFeedBadge];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)performAutoLoginAndFetchData {
    if (self.loginTask != nil)
    {
        return;
    }

    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    @weakify(self);
  self.loginTask =  [[[[QMCore instance] login] continueWithBlock:^id _Nullable(BFTask * _Nonnull task) {
      [SVProgressHUD dismiss];
      
        if (task.isFaulted) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            if (task.error.code == kQMUnAuthorizedErrorCode
                || (task.error.code == kBFMultipleErrorsError
                    && ([task.error.userInfo[BFTaskMultipleErrorsUserInfoKey][0] code] == kQMUnAuthorizedErrorCode
                        || [task.error.userInfo[BFTaskMultipleErrorsUserInfoKey][1] code] == kQMUnAuthorizedErrorCode))) {
                        
                        return [[QMCore instance] logout];
                    }
        }
        
        return [BFTask cancelledTask];
        
    }] continueWithBlock:^id _Nullable(BFTask * _Nonnull task) {
        @strongify(self);
        [SVProgressHUD dismiss];
        if (!task.isCancelled) {
            
            [self performSegueWithIdentifier:kQMSceneSegueAuth sender:nil];
        }
        
        return nil;
    }];
}

- (void)initializeData {
    // init values.
  //  [GlobalVars sharedInstance].mainAnimViewController = self;
    NSArray *top_array = @[locate_top, Messages_top, group_top, setting_top, journal_top];
    NSArray *leading_array = @[locate_leading, Messages_leading, group_leading, settting_leading, journal_leading];
    btn_array = @[locateView, messagesView, groupView, settingView, journalView];
    segue_identifies = @[kQMSceneSegueNews, @"messages_segue", @"groups_segue", kQMSceneSegueSetting, @"journal_segue"];
    
    
    // init views
    for(NSUInteger i = 0; i < [top_array count]; i ++) {
        double w = self.view.frame.size.width;
        double r = w / 2 - w / 6;
        double angle = 360 / 6 * i;
        //        float angle = 36 / 6;
        double view_w = cosf(angle / 180 * M_PI) * r;
        double view_h = sinf(angle / 180 * M_PI) * r;
        UIView *control = btn_array[i];
        NSLayoutConstraint *top_constraint = top_array[i];
        NSLayoutConstraint *leading_constraint = leading_array[i];
        top_constraint.constant = w / 2 - view_h - control.frame.size.width / 2;
        leading_constraint.constant = w / 2 - view_w - control.frame.size.width / 2;
        if(i == 0)
            delat_x = w / 2 - view_w;
        // update views
        [control updateConstraintsIfNeeded];
        [self.view layoutIfNeeded];
        [control layoutIfNeeded];
    }
    
  [self getUserInfo];
}

- (void)getUserInfo {
    [self visibleControls];
}

- (void)visibleControls {
    for (NSUInteger i = 0; i < [btn_array count] ; i ++) {
        ((UIView *)btn_array[i]).hidden = NO;
    }
}

- (void) runSpinAnimationOnView:(UIView*)view duration:(CGFloat)duration rotations:(CGFloat) __unused rotations repeat:(float)repeat Name:(NSString *)name
{
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithDouble: M_PI * 2 ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = repeat;

    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    [view.layer addAnimation:rotationAnimation forKey:name];
    
    [UIView animateKeyframesWithDuration:duration delay:0.f options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat animations:^{
        [view setTransform:CGAffineTransformRotate(view.transform, M_PI_2)];
    } completion:nil];
}

- (void)pathAnimation{    
    for(NSUInteger i = 0; i < [btn_array count]; i ++) {
        UIView *view = btn_array[i];
    
        // Set up path movement
        CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        pathAnimation.calculationMode = kCAAnimationPaced;
        pathAnimation.fillMode = kCAFillModeForwards;
        pathAnimation.removedOnCompletion = NO;
        pathAnimation.repeatCount = INFINITY;
        pathAnimation.beginTime = 5 * (i + 1);
        //pathAnimation.rotationMode = @"auto";
        pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        pathAnimation.duration = 30;
        
        // Create a circle path
        double x, y, r;
        x = delat_x;
        y = x;
        r = self.view.bounds.size.width - x * 2;
        CGMutablePathRef curvedPath = CGPathCreateMutable();
        CGRect circleContainer = CGRectMake(x, y, r, r); // create a circle from this square, it could be the frame of an UIView
        CGPathAddEllipseInRect(curvedPath, NULL, circleContainer);
        
        pathAnimation.path = curvedPath;
        CGPathRelease(curvedPath);
    
        [view.layer addAnimation:pathAnimation forKey:@"myCircleAnimation"];
        
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)__unused event {
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:self.view];
    double delta = (self.view.bounds.size.height - self.view.bounds.size.width) / 2;
    touchLocation.y -= delta;
    for(NSUInteger i = 0; i < [btn_array count]; i ++){
        UIView *view = btn_array[i];
        if([view.layer.presentationLayer hitTest:touchLocation]) {
            [self performSegueWithIdentifier:segue_identifies[i] sender:self];
        }
    }
}
- (IBAction)onNewsFeedAction:(id) __unused sender {
    if (![[QMCore instance] isInternetConnected]) {
        
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
        return ;
    }
    [self performSegueWithIdentifier:segue_identifies[0] sender:self];
}

- (IBAction)onChatAction:(id)__unused sender {
    if (![[QMCore instance] isInternetConnected]) {
        
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
        return ;
    }
    [self performSegueWithIdentifier:segue_identifies[1] sender:nil];
}

//- (IBAction)onLocateAction:(id) __unused sender {
//    [self performSegueWithIdentifier:segue_identifies[2] sender:self];
//}

- (IBAction)onSettingAction:(id) __unused sender {
    [self performSegueWithIdentifier:segue_identifies[3] sender:self];
}

- (IBAction)onJournalAction:(id) __unused sender {
    [self performSegueWithIdentifier:segue_identifies[4] sender:self];
}

- (IBAction)onGroupAction:(id) __unused sender {
    if (![[QMCore instance] isInternetConnected]) {
        
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
        return ;
    }
    [self performSegueWithIdentifier:segue_identifies[2] sender:self];
}

- (void) updateChatBadge
{
    self.chatBtn.shouldHideBadgeAtZero = YES;
    self.chatBtn.shouldAnimateBadge = YES;
    self.chatBtn.badgePadding = 5.0;
    self.chatBtn.badgeFont = [UIFont fontWithName:@"AvenirNext-Regular" size:17];
    NSArray* unreadDialogs = [[[QMCore instance].chatService.dialogsMemoryStorage unreadDialogs] mutableCopy];
    int contactBadges = 0;
    
    for (QBChatDialog* __unused temp in unreadDialogs) {
        if ([temp.lastMessageText containsString:@"Contact"])
        {
            contactBadges += 1;
        }
    }
    
    [((QMAppDelegate *)[UIApplication sharedApplication].delegate) setApplicationBadgeNumber:unreadDialogs.count];
   
    if  ([DataManager sharedManager].chatContactBadge != 0 && unreadDialogs.count == 0)
    {
        self.chatBtn.badgeValue = [NSString stringWithFormat:@"%d", contactBadges];
        [((QMAppDelegate *)[UIApplication sharedApplication].delegate) setApplicationBadgeNumber:-unreadDialogs.count];
    } else {
         self.chatBtn.badgeValue = [NSString stringWithFormat:@"%d", contactBadges];
    }
    [DataManager sharedManager].chatContactBadge = contactBadges;
    [DataManager sharedManager].chatDialogBadge = unreadDialogs.count - contactBadges;
}

- (void) updateNewsFeedBadge
{
    self.newsfeedBtn.shouldHideBadgeAtZero = YES;
    self.newsfeedBtn.shouldAnimateBadge = YES;
    self.newsfeedBtn.badgePadding = 5.0;
    self.newsfeedBtn.badgeFont = [UIFont fontWithName:@"AvenirNext-Regular" size:17];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [[[QMNetworkManager sharedManager] getFeedCountWithCompletion] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (serverTask.error != nil) {
            return nil;
        }
        
        NSNumber *response = [serverTask.result objectForKey:@"unread_count"];
        [((QMAppDelegate *)[UIApplication sharedApplication].delegate) setApplicationBadgeNumber:[response intValue]];
        self.newsfeedBtn.badgeValue = [response stringValue];
        
        [DataManager sharedManager].newsFeedBadge = [response integerValue];
        return nil;
    }];
}

- (void) updateGroupsBadge
{
    self.groupsBtn.shouldHideBadgeAtZero = YES;
    self.groupsBtn.shouldAnimateBadge = YES;
    self.groupsBtn.badgePadding = 5.0;
    self.groupsBtn.badgeFont = [UIFont fontWithName:@"AvenirNext-Regular" size:17];
    
    
    
//    self.groupsBtn.badgeOriginX = 20;
//    self.groupsBtn.badgeOriginY = 30;
    
//    [self.groupsBtn.badge mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(@0);
//    }];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] getGroupBadge] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (serverTask.error != nil) {
            return nil;
        }
        NSNumber *response = [serverTask.result objectForKey:@"unread_count"];
        
        
        self.groupsBtn.badgeValue = [response stringValue];
        
        [self.groupsBtn updateConstraintsIfNeeded];
        [self.groupsBtn layoutIfNeeded];
        [self.view layoutIfNeeded];
        
        [DataManager sharedManager].GroupsBadge = [response integerValue];
        
        [((QMAppDelegate *)[UIApplication sharedApplication].delegate) setApplicationBadgeNumber:[response intValue]];
        
        return nil;
    }];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id) __unused sender {
    
    if ([segue.identifier isEqualToString:kGoToChatSegueIdentifier]) {
//        MYChatNavViewController* viewController = segue.destinationViewController;
//        viewController.dialog = sender;
//        viewController.opponents = qbUserArray;
    }
    
//    if ([segue.identifier isEqualToString:kQMSceneSegueNews])
//    {
//        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//        UITabBarController *tabBar = segue.destinationViewController;
//        UINavigationController* navigation = tabBar.viewControllers.firstObject;
//        AllPostViewController* allPostController = navigation.viewControllers.firstObject;
//        allPostController.postsArray = [[QMNetworkManager sharedManager] getUserPostsWithOffsetWithSync:@(0)];
//        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//    }
}

- (void)gotoChatViewController:(QBChatDialog *) __unused dialog {
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
//    UIViewController *topViewController = [[AppDelegate appDelegate] topViewControllerWithRootViewController:self];
//    if([topViewController isKindOfClass:[MainAnimViewController class]]) {
//        
//        goToChatFlag = YES;
//        chatDialog = dialog;
////        [self performSegueWithIdentifier:kGoToChatSegueIdentifier sender:dialog];
////        [self performSegueWithIdentifier:segue_identifies[1] sender:self];
//        
//        [PushNotificationManager sharedInstance].notificationType = NOTIFICATIONTYPE_DEFALT;
//    } else {
//        MyChatViewController *chatController = [storyboard instantiateViewControllerWithIdentifier:@"MyChatViewController"];
//        chatController.dialog = dialog;
//        chatController.opponents = qbUserArray;
//        
//        // send chatViewController
//        [topViewController.navigationController pushViewController:chatController animated:YES];
//        
//        [PushNotificationManager sharedInstance].notificationType = NOTIFICATIONTYPE_DEFALT;
//    }
}


- (void)getBadges {
//
//    [[NetworkManager sharedManager] getMainBadges:myUserID completion:^(BOOL success, id response, NSError *error) {
//        if(success) {   // success
//            NSDictionary *result = response;
//            [[PushNotificationManager sharedInstance] parseBadges:result];
//            [self refreshBadges];
//        } else {        // fail
//            
//        }
//    }];
//    
//    
}

// update badge
- (void) refreshBadges {
    
    // chat section badge
//    PushNotificationManager *pushNotificationManager = [PushNotificationManager sharedInstance];
//    
//    NSInteger chatSectionBadge = [pushNotificationManager getChatSectionBadges];
//    if(chatSectionBadge == 0) {
//        self.chatBadgeView.hidden = YES;
//    } else {
//        self.chatBadgeLabel.text = [NSString stringWithFormat:@"%ld", (long)chatSectionBadge];
//        self.chatBadgeView.hidden = NO;
//    }
}
@end
