//
//  CircleViewController.m
//  reach-ios
//
//  Created by Admin on 2016-12-27.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "GroupsViewController.h"
#import "NewGroupViewController.h"
#import "UserProfileViewController.h"
#import "GroupDetailViewController.h"
#import "UIView+Borders.h"
#import "GroupCell.h"

@interface GroupsViewController ()<GroupCellDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIActionSheetDelegate>
{
    __block BOOL isTopRefreshing;
    __block BOOL isBottomRefreshing;
    __block BOOL isFirstLoading;
}

@property (strong, nonatomic) NSNumber* groupID;
@property (strong, nonatomic) NSMutableArray* groupsArray;
@property (strong, nonatomic) UIRefreshControl *bottomRefresh;

@property (strong, nonatomic) UISearchController *searchController;
@property (copy, nonatomic) NSString *filter;

//@property (strong, nonatomic) NSString *shouldRefresh;

@property (strong, nonatomic) BFTask* task;

@end

@implementation GroupsViewController
@synthesize myGroup;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addTapGesture];

    
    if (myGroup == nil)
    {
        self.title = @"All Groups";
        isFirstLoading = YES;
        @weakify(self);
        [self addNewGroupsWithCompletion:^{
            @strongify(self);
            [self prepareUI];
            [self registerNibs];
            [self configureSearch];
            [self setupRefreshControl];
        }];
    } else
    {
        self.title = @"My Group";
        self.groupsArray = [NSMutableArray arrayWithObject:myGroup];
        [self prepareUI];
        [self registerNibs];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createNewGroup) name:@"NewGroup" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGroup:) name:@"UpdateGroup" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onBackAction:(id) __unused sender {
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Initialization

- (void) setupRefreshControl
{
    // self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor clearColor];
    self.refreshControl.tintColor = [UIColor blackColor];
    [self.refreshControl addTarget:self
                            action:@selector(addNewGroup)
                  forControlEvents:UIControlEventValueChanged];
    
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) prepareUI
{
    self.navigationController.navigationBar.hidden = false;
    
    @weakify(self)
    // adding notification for showing chat connection
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationDidEnterBackgroundNotification
     object:nil
     queue:nil
     usingBlock:^(NSNotification * _Nonnull __unused note) {
         
         @strongify(self);
         [self.view endEditing:YES];
     }];
}

- (void)addTapGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)handleTap {
    [self.view endEditing:YES];
}

- (void) configureSearch
{
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchBar.placeholder = NSLocalizedString(@"QM_STR_SEARCH_BAR_PLACEHOLDER", nil);
    self.searchController.searchBar.delegate = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.definesPresentationContext = YES;
    [self.searchController.searchBar sizeToFit]; // iOS8 searchbar sizing
    self.tableView.tableHeaderView = self.searchController.searchBar;
}

- (void)registerNibs {
    
    [GroupCell registerForReuseInTableView:self.tableView];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = THE_CELL_HEIGHT;
}

- (NSNumber *)newGroupID {
    if (self.groupsArray == nil || [self.groupsArray count] == 0 || isFirstLoading) {
        return @-1;
    }
    
    GroupModel* group =  (GroupModel*)self.groupsArray.firstObject;
    return group.groupID;
}

- (NSNumber*) oldGroupID {
    
    if (self.groupsArray == nil || [self.groupsArray count] == 0) {
        return @-1;
    }
    
    GroupModel* group =  (GroupModel*)self.groupsArray.lastObject;
    return group.groupID;
}

- (NSString*) getFilter {
    if (self.filter == nil) {
        self.filter = @"";
    }
    
    return self.filter;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.refreshControl.isRefreshing) {
        // fix for freezing refresh control after tab bar switch
        // if it is still active
        CGPoint offset = self.tableView.contentOffset;
        [self.refreshControl endRefreshing];
        [self.refreshControl beginRefreshing];
        self.tableView.contentOffset = offset;
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

/*
    Receive the notification about the update from create new group
 */

- (void) createNewGroup {
    isFirstLoading = YES;
    [self addNewGroup];
}

/*
 Receive the notification about the update from join group, create status, and add new comment
 */

- (void) updateGroup: (NSNotification*) notification
{
    GroupModel *updatedGroup =  [notification.object objectForKey:@"group"];
    GroupCell* cell = [notification.object objectForKey:@"cell"];
    [self updateGroupInArray:updatedGroup];
    if (cell != nil) {
        [cell updateJoinBtn:updatedGroup];
    } else {
        [self.tableView reloadData];
    }
}

- (void) addNewGroup
{
    if  (isTopRefreshing)
    {
        return;
    }
    
    isTopRefreshing = YES;
    
    [self addNewGroupsWithCompletion:nil];
}

- (void) addNewGroupsWithCompletion: (void (^)(void)) completion
{
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] getGroups:[self getFilter] inCategory:self.categoryID fromGroupID:[self newGroupID] withType:@"new"] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
       
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        @strongify(self);
        if(self == nil) return nil;
        self->isTopRefreshing = NO;
//        self.shouldRefresh = @"NO";
        
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[GroupModel getGroupsListFromResponse:serverTask.result[@"circles"]]];
        
        if (self->isFirstLoading) {
            self.groupsArray = resultArray;
        } else {
            [resultArray addObjectsFromArray:self.groupsArray];
            self.groupsArray = resultArray;
        }
        
        if (self.refreshControl.isRefreshing) {
            CGPoint offset = self.tableView.contentOffset;
            self.refreshControl.attributedTitle = [self getLastRefreshingTime];
            [self.refreshControl endRefreshing];
            self.tableView.contentOffset = offset;
        }
        
        if  (completion != nil) {
            completion();
        }
        
        self->isFirstLoading = NO;
        [self.tableView reloadData];
    
        return nil;
    }];
}

- (void) addOldGroup
{
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] getGroups:[self getFilter] inCategory:self.categoryID fromGroupID:[self oldGroupID] withType:@"old"] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        if (self.bottomRefresh.isRefreshing) {
            [self.bottomRefresh endRefreshing];
        }
        
        @strongify(self);
        if(self == nil) return nil;
        self->isBottomRefreshing = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[GroupModel getGroupsListFromResponse:serverTask.result[@"circles"]]];
        BOOL shouldReloaded = resultArray.count != 0;
        [self.groupsArray addObjectsFromArray:resultArray];

        if (shouldReloaded) {
            [self.tableView reloadData];
        }
        
        return nil;
    }];
}

#pragma mark - search

- (void)updateSearchResultsForSearchController:(UISearchController *) __unused searchController
{
    //  self.navigationController.navigationBarHidden = NO;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)__unused scrollView {
    
    [self.searchController.searchBar endEditing:YES];
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *) __unused searchController {
}

- (void)willDismissSearchController:(UISearchController *) __unused searchController {
    searchController.searchBar.text = @"";
    self.filter = @"";
    [self.groupsArray removeAllObjects];
    
    [self addNewGroup];
}


- (void)searchBar:(UISearchBar *) __unused searchBar textDidChange:(NSString *)searchText
{
    self.filter = searchText;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.filter = searchBar.text;
    [self.groupsArray removeAllObjects];
    [self addNewGroup];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView {

    return [self.groupsArray count];
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GroupCell *cell = [tableView dequeueReusableCellWithIdentifier:[GroupCell cellIdentifier] forIndexPath:indexPath];
    
    cell.delegate = self;
    cell.tag = indexPath.section;
    [cell configureCellWithGroupInfo:self.groupsArray[indexPath.section]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GroupModel* group = [self.groupsArray objectAtIndex:indexPath.section];

    NSArray *reversed = [[group.topics reverseObjectEnumerator] allObjects];
    group.topics = [reversed mutableCopy];
    if (![[QMCore instance] isInternetConnected]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
        return;
    } else {
        [self performSegueWithIdentifier:kGroupDetailSegue sender:group];
    }
}

- (CGFloat)tableView:(UITableView *)__unused tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 0;
    }
    
    return 10;
}

- (UIView *)tableView:(UITableView *)__unused tableView viewForHeaderInSection:(NSInteger)__unused section
{
    UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 10)];
    
    CALayer* bottomLayer = [header createBottomBorderWithHeight:1 color:[UIColor lightGrayColor] leftOffset:18 rightOffset:0 andBottomOffset:0];
    [header.layer addSublayer:bottomLayer];
    
    return header;
}

#pragma mark - GroupCellDelegate

- (void) didTapAvatar:(GroupCell *)cell {
    GroupModel *group = self.groupsArray[cell.tag];
    if(![group.permission boolValue]) {
        return;
    }
    
    if (![[QMCore instance] isInternetConnected]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
        return;
    } else {
         [self performSegueWithIdentifier:kProfileSegue sender:[NSNumber numberWithInteger:cell.tag]];
    }
}

- (void) updateGroupInArray: (GroupModel*) group
{
    NSInteger index = 0;
    for (GroupModel* groupModel in self.groupsArray) {
        if ([groupModel.groupID isEqual:group.groupID]){
            [self.groupsArray replaceObjectAtIndex:index withObject:group];
            break;
        }
        index += 1;
    }
}

- (void) didTapJoinBtn:(GroupCell *)cell
{
    GroupModel *group = self.groupsArray[cell.tag];
    [self.view endEditing:YES];
    
    if  ([group.owner.email isEqualToString:[QBSession currentSession].currentUser.email])
    {
        return;
    }
    
    @weakify(self);
    [SVProgressHUD showWithStatus:@"Joining..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [[[QMNetworkManager sharedManager] joinGroupWithGroupID:group.groupID] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        @strongify(self);
        [SVProgressHUD dismiss];
        if(self == nil) return nil;
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        GroupModel* group1 = [GroupModel getGroupFromResponse:[serverTask.result valueForKey:@"circle"]];
//        [cell updateJoinBtn:group1];
//        [self updateGroupInArray:group1];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGroup" object:@{@"cell": cell, @"group": group1, @"action": @"Join"}];
        
        return nil;
    }];
}

- (void) didTapShowHide:(GroupCell *)__unused cell
{
    
}

#pragma mark - goto new group
- (IBAction)createNewGroup:(id)__unused sender {
    if (![[QMCore instance] isInternetConnected]) {
        
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
        return;
    } else {
        [self performSegueWithIdentifier:kNewGroupSegue sender:self.categoryID];
    }
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id)sender {
    [self.view endEditing:YES];
    
    if ([segue.identifier isEqualToString:kProfileSegue]) {
        NSInteger tagNumber = [sender integerValue];
        GroupModel *group = self.groupsArray[tagNumber];
        UINavigationController* navigationController = segue.destinationViewController;
        UserProfileViewController* profileViewController = navigationController.viewControllers.firstObject;
        profileViewController.user = group.owner;
    }

    if ([segue.identifier isEqualToString:kNewGroupSegue]) {
        UINavigationController* navigationController = segue.destinationViewController;
        NewGroupViewController* newGroupViewController = navigationController.viewControllers.firstObject;
        newGroupViewController.categoryID = self.categoryID;
        newGroupViewController.categoryName = self.categoryName;
    }
    
    if ([segue.identifier isEqualToString:kGroupDetailSegue])
    {
        UINavigationController* navigationController = segue.destinationViewController;
        GroupDetailViewController *groupDetailViewController = navigationController.viewControllers.firstObject;
        
        groupDetailViewController.group = sender;
    }
}

#pragma mark - ScrollView Delegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    
    if (offsetY > contentHeight - scrollView.frame.size.height && !isFirstLoading) {
        
        [self addOldGroup];
    }
}

#pragma mark - Empty table
- (UIImage *)imageForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return [UIImage imageNamed:@"logo-splash"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    NSString *text = @"There is no group that belongs to this category yet";
    
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
@end
