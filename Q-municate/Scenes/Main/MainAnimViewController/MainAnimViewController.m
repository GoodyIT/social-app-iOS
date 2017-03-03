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
#import "GroupDetailViewController.h"

#import "MainTabBarController.h"
#import "GroupsTabBarController.h"

#import "UIButton+Badge.h"

@import AVFoundation;
@import AVKit;

static const NSInteger kQMUnAuthorizedErrorCode = -1011;

@interface MainAnimViewController ()<QMChatServiceDelegate,
QMChatConnectionDelegate, ReachServiceDelegate>
{
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
@synthesize mainSuperView;

static MainAnimViewController *instance = nil;
- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];    
 
    @weakify(self)
    // adding notification for showing chat connection
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationWillEnterForegroundNotification
     object:nil
     queue:nil
     usingBlock:^(NSNotification * _Nonnull __unused note) {
         @strongify(self);
         [self updateNewsFeedBadge];
         [self performAutoLoginAndFetchData];
         [self updateGroupsBadge];
     }];
    
    // Do nay additional setup
    UIImage *NavigationPortraitBackground = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    [[UINavigationBar appearance] setBackgroundImage:NavigationPortraitBackground forBarMetrics:UIBarMetricsDefault];
    
     instance = self;
    // Do any additional setup after loading the view.
    
    [self initializeData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateChatBadges) name:@"fetchAllDialog" object:nil];
    
}

- (void)viewWillAppear:(BOOL) animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:YES];
    
//    [[QMCore instance].chatService addDelegate:self];
    [[PushManager instance] addDelegate:self];
    [self updateChatBadges];
    [self performAutoLoginAndFetchData];

    [self updateGroupsBadge];
    [self updateNewsFeedBadge];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [[QMCore instance].chatService removeDelegate:self];
    [[PushManager instance] removeDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateDialogsAndEndRefreshing {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    @weakify(self);
    [[QMTasks taskFetchAllData] continueWithBlock:^id _Nullable(BFTask * _Nonnull __unused task) {
        
        @strongify(self);
        
        [self updateChatBadges];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        return nil;
    }];
}

- (void) gotoChatView: (QBChatDialog*) chatDialog
{
    if (chatDialog != nil) {
        QMChatVC *chatVC = [QMChatVC chatViewControllerWithChatDialog:chatDialog];
        [self.navigationController setNavigationBarHidden:NO];
        [self.navigationController pushViewController:chatVC animated:YES];
    }
}

- (void) restoreLoadingBar
{
    [SVProgressHUD dismiss];
    [SVProgressHUD resetOffsetFromCenter];
    [SVProgressHUD setBackgroundColor:[UIColor whiteColor]];
}

- (void)performAutoLoginAndFetchData {

    @weakify(self);
    self.loginTask = [[QMCore instance] login];
    if (self.loginTask == nil){
        [self updateDialogsAndEndRefreshing];
    } else {
        [SVProgressHUD setOffsetFromCenter:UIOffsetMake(0, self.view.frame.size.width/2+50)];
        [SVProgressHUD show];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [SVProgressHUD setBackgroundColor:[UIColor babyBule]];
        self.loginTask = [[self.loginTask continueWithBlock:^id _Nullable(BFTask * _Nonnull __unused task) {
            [self restoreLoadingBar];
            if (task.isFaulted) {
                if (task.error.code == kQMUnAuthorizedErrorCode
                    || (task.error.code == kBFMultipleErrorsError
                        && ([task.error.userInfo[BFTaskMultipleErrorsUserInfoKey][0] code] == kQMUnAuthorizedErrorCode
                            || [task.error.userInfo[BFTaskMultipleErrorsUserInfoKey][1] code] == kQMUnAuthorizedErrorCode))) {
                            
                            return [[[QMCore instance] logout] continueWithBlock:^id _Nullable(BFTask * _Nonnull __unused logoutTask) {
                                
                                [SVProgressHUD dismiss];
                                
                                [self performSegueWithIdentifier:kQMSceneSegueAuth sender:nil];
                                return logoutTask;
                            }];
                        }
            }
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            [self updateDialogsAndEndRefreshing];
            
            return [BFTask cancelledTask];
            
        }] continueWithBlock:^id _Nullable(BFTask * _Nonnull task) {
            @strongify(self);
            [self restoreLoadingBar];
            if (!task.isCancelled) {
                
                [self performSegueWithIdentifier:kQMSceneSegueAuth sender:nil];
            }
            
            return nil;
        }];
    }
}

- (void)initializeData {
    // init values.
  //  [GlobalVars sharedInstance].mainAnimViewController = self;
    NSArray *top_array = @[setting_top, Messages_top, newsfeed_top, group_top, journal_top];
    NSArray *leading_array = @[settting_leading, Messages_leading, newsfeed_leading, group_leading, journal_leading];
    btn_array = @[settingView, messagesView, newsView, groupView, journalView];
    segue_identifies = @[kQMSceneSegueSetting, @"messages_segue", kQMSceneSegueNews, @"groups_segue", @"journal_segue"];
        
    for(NSUInteger i = 0; i < [top_array count]; i ++) {
        double w = self.view.frame.size.width;
        double r = w / 2 - w / 5;
        float angle = 360 / 5 * i + 18;
        //        float angle = 36 / 6;
        double view_w = cos(angle / 180 * M_PI) * r;
        double view_h = sin(angle / 180 * M_PI) * r;
        UIView *control = btn_array[i];
        NSLayoutConstraint *top_constraint = top_array[i];
        NSLayoutConstraint *leading_constraint = leading_array[i];
         double width = self.view.frame.size.width * 3/20;
        double top_offset = w / 2 - view_h - width / 2;
        double left_offset = w / 2 - view_w - width / 2;
        top_constraint.constant = top_offset;
        leading_constraint.constant = left_offset;
//        if(i == 0)
//            delat_x = w / 2 - view_w;
//        // update views
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
    [self performSegueWithIdentifier:segue_identifies[2] sender:self];
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
    if (![[QMCore instance] isInternetConnected]) {
        
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
        return ;
    }
    [self performSegueWithIdentifier:segue_identifies[0] sender:self];
}

- (IBAction)onJournalAction:(id) __unused sender {
    if (![[QMCore instance] isInternetConnected]) {
        
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
        return ;
    }
    [self performSegueWithIdentifier:segue_identifies[4] sender:self];
}

- (IBAction)onGroupAction:(id) __unused sender {
    if (![[QMCore instance] isInternetConnected]) {
        
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
        return ;
    }
    [self performSegueWithIdentifier:segue_identifies[3] sender:self];
}

#pragma mark - News Feed & Group Notification

- (void) didRecieveReachPushNotification:(PushManager *)__unused manager ID:(NSNumber*)ID title:(NSString *)title message:(NSString *)messageText avatar:(NSString *)avatar
{
    if  ([title isEqualToString:@"Post"]){
        [self updateNewsFeedBadge];
    } else {
        [self updateGroupsBadge];
    }
    
    [QMSoundManager playMessageReceivedSound];
    
    MPGNotificationButtonHandler buttonHandler = nil;
    UIViewController *hvc = nil;
    
    buttonHandler = ^void(MPGNotification * __unused notification, NSInteger __unused buttonIndex) {
        if  ([title isEqualToString:@"Post"])
        {
            MyPostDetailViewController* myPostVC = [[UIStoryboard storyboardWithName:@"News" bundle:nil] instantiateViewControllerWithIdentifier:@"MyPostDetailViewController"];
            myPostVC.postID = ID;
            
            [self.navigationController setNavigationBarHidden:NO];
            [self.navigationController pushViewController:myPostVC animated:YES];
        } else {
            GroupDetailViewController* groupDetailVC = [[UIStoryboard storyboardWithName:@"Groups" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupDetailViewController"];
            groupDetailVC.groupID = ID;
            [self.navigationController setNavigationBarHidden:NO];
            [self.navigationController pushViewController:groupDetailVC animated:YES];
        }
    };
    
    [QMNotification showMessageNotificationWithTitle:title message:messageText avatarURL:avatar buttonHandler:buttonHandler hostViewController:hvc];
}

- (void) updateChatBadges
{
    [super updateChatBadges];
    
    self.chatBtn.shouldHideBadgeAtZero = YES;
    self.chatBtn.shouldAnimateBadge = YES;
    self.chatBtn.badgePadding = 5.0;

    NSArray* unreadDialogs = [[[QMCore instance].chatService.dialogsMemoryStorage unreadDialogs] mutableCopy];
    NSUInteger dialogBadges = 0;
    NSUInteger requestBadges = 0;
    NSUInteger chatBadges = 0;
    
    for (QBChatDialog*  dialog in unreadDialogs) {
        if (![dialog.lastMessageText containsString:@"Contact"])
        {
            dialogBadges += dialog.unreadMessagesCount;
        } else {
            requestBadges += dialog.unreadMessagesCount;
        }
    }
    chatBadges = dialogBadges + requestBadges;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if  (chatBadges != 0)
        {
            self.chatBtn.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)chatBadges];
        } else {
            self.chatBtn.badgeValue = nil;
        }
    });   
    
    [DataManager sharedManager].chatDialogBadge = dialogBadges;
    [DataManager sharedManager].chatContactBadge = requestBadges;
    
    [self.newsfeedBtn updateConstraintsIfNeeded];
    [self.newsfeedBtn layoutIfNeeded];
    [self.view layoutIfNeeded];
}

- (void) updateNewsFeedBadge
{
    self.newsfeedBtn.shouldHideBadgeAtZero = YES;
    self.newsfeedBtn.shouldAnimateBadge = YES;
    self.newsfeedBtn.badgePadding = 5.0;
//    self.newsfeedBtn.badgeFont = [UIFont fontWithName:@"AvenirNext-Regular" size:17];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [[[QMNetworkManager sharedManager] getFeedCountWithCompletion] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (serverTask.error != nil) {
            return nil;
        }
        
        NSNumber *response = [serverTask.result objectForKey:@"unread_count"];
        self.newsfeedBtn.badgeValue = [response stringValue];
        [DataManager sharedManager].newsFeedBadge = [response integerValue];
        
        [self.newsfeedBtn updateConstraintsIfNeeded];
        [self.newsfeedBtn layoutIfNeeded];
        [self.view layoutIfNeeded];
        
        return nil;
    }];
}

- (void) updateGroupsBadge
{
    self.groupsBtn.shouldHideBadgeAtZero = YES;
    self.groupsBtn.shouldAnimateBadge = YES;
    self.groupsBtn.badgePadding = 5.0;
//    self.groupsBtn.badgeFont = [UIFont fontWithName:@"AvenirNext-Regular" size:17];
    
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
    
    if ([segue.identifier isEqualToString:kQMSceneSegueNews])
    {
        MainTabBarController* mainNewsTC = (MainTabBarController*)(((UINavigationController*)segue.destinationViewController).topViewController);
        mainNewsTC.pushType = sender;
    }
    
    if ([segue.identifier isEqualToString:@"groups_segue"])
    {
        GroupsTabBarController* mainGroupsTC = (GroupsTabBarController*)(((UINavigationController*)segue.destinationViewController).topViewController);
        mainGroupsTC.pushType = sender;
    }
    
    if ([segue.identifier isEqualToString:@"ChatNavigation"]) {
        QMChatVC* chatVC = [(UINavigationController*)segue.destinationViewController viewControllers].firstObject;
        chatVC.chatDialog = sender;
    }
}

@end
