//
//  NotificationViewController.m
//  reach-ios
//
//  Created by Admin on 2016-12-26.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "NotificationViewController.h"
#import "UserProfileViewController.h"
#import "MyPostDetailViewController.h"
#import "NotificationCell.h"

#import "QMAlert.h"

@interface NotificationViewController ()<UIScrollViewDelegate, NotificationCellDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, ReachServiceDelegate>
{
    __block BOOL    shouldDisplay;
    __block BOOL    shouldUpdateCell;
    __block BOOL    isFirstLoading;
    __block BOOL    isBottomRefreshing;
    __block BOOL    isTopRefreshing;
}

@property (strong, nonatomic) NSMutableArray *notificationsArray;
@property (strong, nonatomic) UIRefreshControl *bottomRefresh;

@property (strong, nonatomic) NSTimer* cellUpdateTimer;

@property (strong, nonatomic) BFTask* task;

@end

@implementation NotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onBackAction:(id) __unused sender {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Initialization

- (void) prepareUI
{
    // self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor clearColor];
    self.refreshControl.tintColor = [UIColor blackColor];
    [self.refreshControl addTarget:self
                            action:@selector(addNewNotification)
                  forControlEvents:UIControlEventValueChanged];
    
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if (self.notificationsArray.count > 0) {
        self.tabBarItem.badgeValue =  [NSString stringWithFormat:@"%ld", (long)self.notificationsArray.count];
    } else {
        self.tabBarItem.badgeValue = nil;
    }
}

- (void) createTimer
{
    shouldUpdateCell = NO;
    [self performSelector:@selector(updateCell) withObject:nil afterDelay:kNotificationDelay];
}

- (void) updateCell
{
    [self notifyReadFeed];
    shouldUpdateCell = YES;
    [self.tableView reloadData];
}

- (void)registerNibs {
    
    [NotificationCell registerForReuseInTableView:self.tableView];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = THE_CELL_HEIGHT/2;
}

- (void) beginTransion: (NSNotification *)notification
{
    NSInteger myIndex = [notification.object integerValue];
    if (myIndex == 1)
    {
        [self.notificationsArray removeAllObjects];
    }
}

- (void) endTransion:(NSNotification *)notification {
    
    NSInteger myIndex = [notification.object integerValue];
    
    if (myIndex != 0)
        return;
    
    @weakify(self);
    [self addNewNotificationWithCompletion:^{
        @strongify(self);
        [self registerNibs];
        [self prepareUI];
    }];
}

- (NSNumber *)newNoticiationID {
    if (self.notificationsArray == nil || [self.notificationsArray count] == 0) {
        return @-1;
    }
    
    NotificationModel* notification =  (NotificationModel*)self.notificationsArray.firstObject;
    return notification.notificationID;
}

- (NSNumber*) oldNotificationID {
    
    if (self.notificationsArray == nil || [self.notificationsArray count] == 0) {
        return @-1;
    }
    
    NotificationModel* notification =  (NotificationModel*)self.notificationsArray.lastObject;
    return notification.notificationID;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[PushManager instance] addDelegate:self];
    
    if (self.refreshControl.isRefreshing) {
        // fix for freezing refresh control after tab bar switch
        // if it is still active
        CGPoint offset = self.tableView.contentOffset;
        [self.refreshControl endRefreshing];
        [self.refreshControl beginRefreshing];
        [self.bottomRefresh endRefreshing];
        [self.bottomRefresh beginRefreshing];
        self.tableView.contentOffset = offset;
    }
    
    isFirstLoading = YES;
    
    @weakify(self);
    [self addNewNotificationWithCompletion:^{
        @strongify(self);
        [self registerNibs];
        [self prepareUI];
        [self notifyReadFeed];
    }];
}

- (void) viewWillDisappear:(BOOL)animated {
    
    NSArray * visibleCells = [self.tableView visibleCells];
    if (visibleCells) {
        
        for (NotificationCell * cell in visibleCells) {
            
            [cell cancelOperation];
        }
    }
    [[PushManager instance] removeDelegate:self];
    
    [super viewWillDisappear:animated];
}

#pragma mark - News Feed delegate
- (void) didRecieveReachPushNotification:(PushManager *)__unused manager ID:(NSNumber *)__unused ID title:(NSString *)title message:(NSString *)__unused messageText avatar:(NSString *) __unused  avatar
{
    if ([title isEqualToString:@"Post"])
    {
        [self addNewNotification];
        
        [self updateBadge:YES];
    }
}

- (void)updateBadge: (BOOL) fromPush {
    if (fromPush) {
        [DataManager sharedManager].newsFeedBadge += 1;
    }
    
    self.navigationController.tabBarItem.badgeValue =  [NSString stringWithFormat:@"%ld", (long)[DataManager sharedManager].newsFeedBadge];
    
    if ([DataManager sharedManager].newsFeedBadge == 0) {
        self.navigationController.tabBarItem.badgeValue = nil;
    }
}

- (void) addNewNotification
{
    if (isTopRefreshing) {
        return;
    }
    
    isTopRefreshing = YES;
    isFirstLoading = YES;
    [self addNewNotificationWithCompletion:nil];
}

- (void) notifyReadFeed
{
    [DataManager sharedManager].newsFeedBadge = 0;
    self.navigationController.tabBarItem.badgeValue = nil;
    
    for (NotificationModel* notificationModel in self.notificationsArray) {
        notificationModel.readState = @1;
    }
    
    [[[QMNetworkManager sharedManager] notifyReadFeed:[self newNoticiationID]] continueWithBlock:^id _Nullable(BFTask * _Nonnull t1) {
        
        if (t1.isFaulted) {
            NSLog(@"Failed to notify");
        }
        
        return nil;
    }];
}

- (NSAttributedString*) getLastRefreshingTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM d, h:mm a"];
    NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor flatBlackColor]
                                                                forKey:NSForegroundColorAttributeName];
    return [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
}

- (void) addNewNotificationWithCompletion: (void (^)(void)) completion
{
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] getUserNotifications: [self newNoticiationID] withType:@"new"] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        @strongify(self);
        if (self == nil) return nil;
        self->isTopRefreshing = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[NotificationModel getNotificationListFromResponse:serverTask.result]];
        [resultArray addObjectsFromArray:self.notificationsArray];
        self.notificationsArray = [resultArray mutableCopy];
        
        if (self.refreshControl.isRefreshing) {
            self.refreshControl.attributedTitle = [self getLastRefreshingTime];
            [self.refreshControl endRefreshing];
        }
        
        if (completion != nil) {
            completion();
        }
        
        if  (resultArray.count  != 0)
        {
            [self createTimer];
        } else {
            self->shouldUpdateCell = YES;
        }
        
        self->isFirstLoading = NO;
        [self.tableView reloadData];
        
        return nil;
    }];
}

- (void)addOldNotification
{
    if (isBottomRefreshing) {
        return;
    }
    isBottomRefreshing = YES;
    
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.task = [[[QMNetworkManager sharedManager] getUserNotifications:[self oldNotificationID] withType:@"old"] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        @strongify(self);
        if (self == nil) return nil;
        self->isBottomRefreshing = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:self.notificationsArray];
        BOOL shouldReloaded = resultArray.count != 0;
        [resultArray addObjectsFromArray:[NotificationModel getNotificationListFromResponse:serverTask.result]];
        self.notificationsArray = [resultArray mutableCopy];
       
        if (shouldReloaded) {
            [self.tableView reloadData];
        }

        return nil;
    }];
}

#pragma mark - NotificationCell Delegate

- (void) didTapAvatar:(NotificationCell *)cell {
    
    NotificationModel *notification = self.notificationsArray[cell.tag];
    
    @weakify(self);
    [[[QMNetworkManager sharedManager] getUserByID:notification.userID] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
      
        @strongify(self)
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            return nil;
        }
        
        UserModel* user = [UserModel getUserWithResponce:[serverTask.result valueForKey:@"user"]];
        if (![[QMCore instance] isInternetConnected]) {
            
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
            return nil;
        } else {
            [self performSegueWithIdentifier:kProfileSegue sender:user];
        }
        
        return nil;
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView {
    return self.notificationsArray.count;
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:[NotificationCell cellIdentifier] forIndexPath:indexPath];
    
    cell.delegate = self;
    cell.tag = indexPath.section;
    [cell configureCellWithNotificationInfo:self.notificationsArray[indexPath.section] shouldUpdateCell:shouldUpdateCell];
    
    @weakify(self);
    cell.notificationText.userHandleLinkTapHandler  = ^(KILabel* __unused label, NSString  *string, NSRange __unused range) {
        NSRange nameRange = NSMakeRange(1, string.length-1);
        NSString *userName = [string substringWithRange:nameRange];
        [self.tableView setUserInteractionEnabled:NO];
        @strongify(self);
        [self.view endEditing:YES];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [[[QMNetworkManager sharedManager] getUserByName:userName] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self.tableView setUserInteractionEnabled:YES];
            if  (serverTask.isFaulted)
            {
                [SVProgressHUD showErrorWithStatus:@"This user does not exist"];
                return nil;
            }
            UserModel* _user = [UserModel getUserWithResponce:[serverTask.result valueForKey:@"user"]];
            if (![[QMCore instance] isInternetConnected]) {
                
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
                return nil;
            } else {
                [self performSegueWithIdentifier:kProfileSegue sender:_user];
            }
            
            return nil;
        }];
    };
    
    return cell;
}

- (void)tableView:(UITableView *)__unused tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (![[QMCore instance] isInternetConnected]) {
        
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
        return ;
    }
    
    NotificationModel* notificationModel = [self.notificationsArray objectAtIndex:indexPath.section];
    PostModel* post = [PostModel getPostInfoFromResponse:notificationModel.objectOfResponse];
    [self performSegueWithIdentifier:kNewsFeedSegue sender:post.postID];
}

#pragma mark - ScrollView Delegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    
    if (offsetY > contentHeight - scrollView.frame.size.height && !isFirstLoading) {
        
        [self addOldNotification];
    }
}

#pragma mark - Empty table
- (UIImage *)imageForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return [UIImage imageNamed:@"logo-splash"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    NSString *text = @"There is No New Notification Yet";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return [UIColor whiteColor];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return -50;
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return 20.0f;
}

#pragma mark - Empty table delegate

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *) __unused scrollView
{
    return YES;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *) __unused scrollView
{
    return YES;
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id)sender {
    [self.view endEditing:YES];
    
    if ([segue.identifier isEqualToString:kProfileSegue]) {
        UINavigationController* navigationController = segue.destinationViewController;
        UserProfileViewController* profileViewController = navigationController.viewControllers.firstObject;
        profileViewController.user = sender;
    }
    
    if ([segue.identifier isEqualToString:kNewsFeedSegue]) {
        MyPostDetailViewController* mypostDetailViewController = segue.destinationViewController;
        mypostDetailViewController.postID = sender;
    }
}


@end