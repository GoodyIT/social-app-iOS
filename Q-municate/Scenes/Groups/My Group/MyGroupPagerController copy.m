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

@interface MyGroupPagerController ()<GroupCellDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
{
    NSInteger   selectedIndex;
    __block BOOL isBottomRefreshing;
    BOOL isFirstLoading;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tabIndicatorLeading;
@property (strong, nonatomic) NSMutableArray* createdGroupsArray;
@property (strong, nonatomic) NSMutableArray* joinedGroupsArray;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSNumber *currentCreatedOffset;
@property (strong, nonatomic) NSNumber *currentJoinedOffset;
@property (copy, nonatomic) NSString *filter;
@property (strong, nonatomic) BFTask* task;

@end

@implementation MyGroupPagerController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self addTapGesture];
    UIImage *NavigationPortraitBackground = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    [[UINavigationBar appearance] setBackgroundImage:NavigationPortraitBackground forBarMetrics:UIBarMetricsDefault];
    
   
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
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

}

- (void)registerNibs {
    [GroupCell registerForReuseInTableView:self.tableView];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = THE_CELL_HEIGHT;
}

- (void)addTapGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)handleTap {
    [self.view endEditing:YES];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    selectedIndex = 0;
    isFirstLoading = YES;
    [self updateTabStateWithAnimate:selectedIndex];
    @weakify(self);
    [self addNewCreatedGroupsWithCompletion:^{
        @strongify(self);
        [self registerNibs];
        [self prepareUI];
    }];
}

- (NSNumber *)currentCreatedOffset {
    if (_currentCreatedOffset == nil) {
        _currentCreatedOffset = [[NSNumber alloc] initWithInteger:0];
    }
    
    return _currentCreatedOffset;
}

- (NSNumber *)currentJoinedOffset {
    if (_currentJoinedOffset == nil) {
        _currentJoinedOffset = [[NSNumber alloc] initWithInteger:0];
    }
    
    return _currentJoinedOffset;
}

- (NSString*) getFilter {
    if (self.filter == nil) {
        self.filter = @"";
    }
    
    return self.filter;
}

- (IBAction)gotoJoinedGroups:(id)__unused  sender {
    selectedIndex = 1;
    self.currentJoinedOffset = nil;
 //   [self.groupsArray removeAllObjects];
    [self getMyGroups];
}

- (IBAction)gotoCreatedGroups:(id) __unused sender {
    selectedIndex = 0;
    isFirstLoading = YES;
    self.currentCreatedOffset = nil;
    [self getMyGroups];
}

- (void) getMyGroups
{
    [self addMyNewGroup];
    [self updateTabStateWithAnimate:selectedIndex];
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
    
    [self.view layoutIfNeeded];
}

- (void) addMyNewGroup
{
    if (isBottomRefreshing) {
        return;
    }
    isBottomRefreshing = YES;
    
    if  (selectedIndex == 0) {
        self.navigationItem.title = @"Created Groups";
        [self addNewCreatedGroupsWithCompletion:nil];
    } else {
        self.navigationItem.title = @"Joined Groups";
        [self addNewJoinedGroupsWithCompletion:nil];
    }    
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

- (void) addNewJoinedGroupsWithCompletion: (void (^)(void)) completion
{
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] getMyJoinedGroupsWithOffset:[self getFilter] offset:[self currentJoinedOffset]] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        @strongify(self);
        if (self == nil) return nil;
        self->isBottomRefreshing = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }

        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[GroupModel getGroupsListFromResponse:serverTask.result[@"circles"]]];
        
//        [resultArray addObjectsFromArray:self.groupsArray];
        self.joinedGroupsArray = resultArray;
        
        if (self.refreshControl.isRefreshing) {
            self.refreshControl.attributedTitle = [self getLastRefreshingTime];
            [self.refreshControl endRefreshing];
        }
        
        if  (completion != nil) {
            completion();
        }
        
        [self.tableView reloadData];
        
        return nil;
    }];
}

- (void) addNewCreatedGroupsWithCompletion: (void (^)(void)) completion
{
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] getMyCreatedGroupsWithOffset:[self getFilter] offset:[self currentCreatedOffset]] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        @strongify(self);
        if (self == nil) return nil;
        self->isBottomRefreshing = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        NSError *offsetError = [NSError errorWithDomain:@"99999" code:99999 userInfo:@{NSLocalizedDescriptionKey:[serverTask.result valueForKey:@"offset"]}];
        self.currentCreatedOffset = @([offsetError.localizedDescription integerValue]);
        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[GroupModel getGroupsListFromResponse:serverTask.result[@"circles"]]];
        
        if (self.createdGroupsArray == nil) {
            self.createdGroupsArray = [NSMutableArray new];
        }
        
        [self.createdGroupsArray addObjectsFromArray:resultArray];
        
        if  (completion != nil) {
            completion();
        }
        
        self->isFirstLoading = NO;
        [self.tableView reloadData];
        
        return nil;
    }];
}

#pragma mark - ScrollView Delegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    
    if (offsetY > contentHeight - scrollView.frame.size.height && !isFirstLoading && selectedIndex == 0) {
        
        [self addMyNewGroup];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView {
    if (selectedIndex == 0) {
        return self.createdGroupsArray.count;
    }
    return [self.joinedGroupsArray count];
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GroupCell *cell = [tableView dequeueReusableCellWithIdentifier:[GroupCell cellIdentifier] forIndexPath:indexPath];
    
    cell.delegate = self;
    cell.tag = indexPath.section;
    if (selectedIndex == 0) {
        [cell configureCellWithGroupInfo:self.createdGroupsArray[indexPath.section]];
    } else {
      [cell configureCellWithGroupInfo:self.joinedGroupsArray[indexPath.section]];
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GroupModel* group = [self.createdGroupsArray objectAtIndex:indexPath.section];
    if (selectedIndex == 1) {
        group = [self.joinedGroupsArray objectAtIndex:indexPath.section];
    }
    
    [self performSegueWithIdentifier:kGroupDetailSegue sender:group];
}

#pragma mark - GroupCell Delgate

- (void) didTapAvatar:(GroupCell *)cell {
    GroupModel *group = self.createdGroupsArray[cell.tag];
    if (selectedIndex == 1) {
        group = self.joinedGroupsArray[cell.tag];
    }
    if(![group.permission boolValue]) {
        return;
    }
    
    [self performSegueWithIdentifier:kProfileSegue sender:[NSNumber numberWithInteger:cell.tag]];
}

- (void) didTapShowHide:(GroupCell *)__unused cell
{
 //   GroupModel *groupModel = self.groupsArray[cell.tag];
}

- (void) didTapJoinBtn:(GroupCell *)cell
{
    GroupModel *group;
    if (selectedIndex == 1) {
        group = self.joinedGroupsArray[cell.tag];
    }
    [self.view endEditing:YES];
    
    if  ([group.owner.email isEqualToString:[QBSession currentSession].currentUser.email])
    {
        return;
    }
    
    @weakify(self);
    [SVProgressHUD showWithStatus:@"Joining..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [[[QMNetworkManager sharedManager] joinGroupWithGroupID:group.groupID] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
//        @strongify(self);
        [SVProgressHUD dismiss];
        
        @strongify(self)
        if (self == nil) return nil;
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        GroupModel* group1 = [GroupModel getGroupFromResponse:[serverTask.result valueForKey:@"circle"]];
        [cell updateJoinBtn:group1];
        
        //  [self.tableView reloadData];
        return nil;
    }];

}

#pragma mark - Empty table
- (UIImage *)imageForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return [UIImage imageNamed:@"logo-splash"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    NSString *text = @"You didn't create any group yet";
    if (selectedIndex == 1) {
        text = @"You didn't join any group yet";
    }    
    
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
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kProfileSegue]) {
        NSInteger tagNumber = [sender integerValue];
        GroupModel *group = self.createdGroupsArray[tagNumber];
        if (selectedIndex == 1) {
            group = self.joinedGroupsArray[tagNumber];
        }
        UINavigationController* navigationController = segue.destinationViewController;
        UserProfileViewController* profileViewController = navigationController.viewControllers.firstObject;
        profileViewController.user = group.owner;
    }
    
    if ([segue.identifier isEqualToString:kGroupDetailSegue]) {
        UINavigationController* navigationController = segue.destinationViewController;
        GroupDetailViewController* groupDetailVC = navigationController.viewControllers.firstObject;
        
        groupDetailVC.group = sender;
    }

}


@end
