//
//  MyCreatedGroupViewController.m
//  reach-ios
//
//  Created by DenningIT on 10/02/2017.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import "MyCreatedGroupViewController.h"
#import "UserProfileViewController.h"
#import "GroupDetailViewController.h"
#import "GroupCell.h"

@interface MyCreatedGroupViewController ()<GroupCellDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
{
    __block BOOL isBottomRefreshing;
    BOOL isFirstLoading;
}

@property (strong, nonatomic) NSMutableArray* createdGroupsArray;
@property (strong, nonatomic) NSNumber *currentCreatedOffset;
@property (copy, nonatomic) NSString *filter;

@end

@implementation MyCreatedGroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
     [self addTapGesture];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.createdGroupsArray = [[NSMutableArray alloc] init];
    
    isFirstLoading = YES;
    @weakify(self);
    [self addNewCreatedGroupsWithCompletion:^{
        @strongify(self);
        [self registerNibs];
        [self prepareUI];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createNewGroup) name:@"NewGroup" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGroup:) name:@"UpdateGroup" object:nil];
}

/*
 Receive the notification about the update from create new group
 */

- (void) createNewGroup {
    isFirstLoading = YES;
    [self addMyNewGroup];
}

- (void) updateGroupInArray: (GroupModel*) group action:(NSString*) action
{
    if ([action isEqualToString:@"Join"] && [group.joined integerValue] == 1) {
        [self.createdGroupsArray addObject:group];
    } else {
        NSInteger index = 0;
        for (GroupModel* groupModel in self.createdGroupsArray) {
            if ([groupModel.groupID isEqual:group.groupID]){
                if (![group.joined boolValue]) {
                    [self.createdGroupsArray removeObjectAtIndex:index];
                    break;
                } else {
                    [self.createdGroupsArray replaceObjectAtIndex:index withObject:group];
                    break;
                }
            }
            index += 1;
        }
    }
    
    [self.tableView reloadData];
}

/*
 Receive the notification about the update from join group, and create status
 */
- (void) updateGroup: (NSNotification*) notification
{
    GroupModel *updatedGroup =  [notification.object objectForKey:@"group"];
    NSString* action = [notification.object objectForKey:@"action"];
    if (updatedGroup != nil) {
        [self updateGroupInArray:updatedGroup action:action];
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareUI
{
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
}

- (NSString*) getFilter {
    if (self.filter == nil) {
        self.filter = @"";
    }
    
    return self.filter;
}

- (NSNumber *)currentCreatedOffset {
    if (_currentCreatedOffset == nil || isFirstLoading) {
        _currentCreatedOffset = [[NSNumber alloc] initWithInteger:0];
    }
    
    return _currentCreatedOffset;
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
        
        if (self->isFirstLoading) {
            self.createdGroupsArray = resultArray;
        } else {
           [self.createdGroupsArray addObjectsFromArray:resultArray];
        }
    
        if  (completion != nil) {
            completion();
        }
        
        self->isFirstLoading = NO;
        if (resultArray.count != 0){
            [self.tableView reloadData];
        }
        
        return nil;
    }];
}


- (void) addMyNewGroup
{
    if (isBottomRefreshing) {
        return;
    }
    isBottomRefreshing = YES;
    
    [self addNewCreatedGroupsWithCompletion:nil];
}

#pragma mark - ScrollView Delegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    
    if (offsetY > contentHeight - scrollView.frame.size.height && !isFirstLoading) {
        
        [self addMyNewGroup];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.createdGroupsArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GroupCell *cell = [tableView dequeueReusableCellWithIdentifier:[GroupCell cellIdentifier] forIndexPath:indexPath];
    
    cell.delegate = self;
    cell.tag = indexPath.section;
     [cell configureCellWithGroupInfo:self.createdGroupsArray[indexPath.section]];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GroupModel* group = [self.createdGroupsArray objectAtIndex:indexPath.section];
    
    [self performSegueWithIdentifier:kGroupDetailSegue sender:group];
}

#pragma mark - GroupCell Delgate

- (void) didTapAvatar:(GroupCell *)cell {
    GroupModel *group = self.createdGroupsArray[cell.tag];
    
    if(![group.permission boolValue]) {
        return;
    }
    
    [self performSegueWithIdentifier:kProfileSegue sender:[NSNumber numberWithInteger:cell.tag]];
}

- (void) didTapShowHide:(GroupCell *)__unused cell
{
    //   GroupModel *groupModel = self.groupsArray[cell.tag];
}

- (void) didTapJoinBtn:(GroupCell *)__unused cell
{
    
}


#pragma mark - Empty table
- (UIImage *)imageForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return [UIImage imageNamed:@"logo-splash"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    NSString *text = @"You didn't create any group yet";
    
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
