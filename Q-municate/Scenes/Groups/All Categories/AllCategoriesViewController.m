//
//  AllGroupsViewController.m
//  reach-ios
//
//  Created by Admin on 2016-12-27.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "AllCategoriesViewController.h"
#import "GroupsViewController.h"
#import "AllCategoriesCell.h"


@interface AllCategoriesViewController ()<UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating,DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (strong, nonatomic) NSNumber *groupID;
@property (strong, nonatomic) RKNotificationHub* hub ;

@property (strong, nonatomic) UISearchController *searchController;
@property (copy, nonatomic) NSString *filter;

@property (strong, nonatomic) BFTask* task;

@end

@implementation AllCategoriesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureSearch];
    [self addTapGesture];
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
    UIColor *tabBarTintColor = [UIColor colorWithRed:2 green:25 blue:33 alpha:1.0];
    [[UITabBar appearance] setTintColor:tabBarTintColor];    
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
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

- (void)addTapGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)handleTap {
    [self.view endEditing:YES];
}

- (void)registerNibs {    
    [AllCategoriesCell registerForReuseInTableView:self.tableView];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = THE_CELL_HEIGHT/2;
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
    [self.navigationController setNavigationBarHidden:NO];
    [self.tabBarController.tabBar setHidden:NO];
    
    self.filter = @"";
    @weakify(self);
    [self addNewCategoryWithCompletion:^{
        @strongify(self);
        [self prepareUI];
        [self registerNibs];
    }];
}

- (void) addNewCategory
{
    [self addNewCategoryWithCompletion:nil];
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

- (void) addNewCategoryWithCompletion: (void (^)(void)) completion
{
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] getCategories:[self getFilter]] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        @strongify(self);
        if(self == nil) return nil;
        
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        self.categoriesArray = [[NSMutableArray alloc] initWithArray:[CategoryModel getListOfCategoriesFromResponse:serverTask.result[@"groups"]]];
        
        if  (completion != nil) {
            completion();
        }
        
        [self.tableView reloadData];
        return nil;
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView {
    return [self.categoriesArray count];
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section {

    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AllCategoriesCell *cell = [tableView dequeueReusableCellWithIdentifier:[AllCategoriesCell cellIdentifier] forIndexPath:indexPath];
    
    cell.tag = indexPath.section;
    [cell configureCellWithCategoryInfo:self.categoriesArray[indexPath.section]];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CategoryModel* category = [self.categoriesArray objectAtIndex:indexPath.section];
    if (![[QMCore instance] isInternetConnected]) {
        
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_CHECK_INTERNET_CONNECTION", nil)];
        return;
    } else {
        [self performSegueWithIdentifier:kGroupSegue sender:category];
    }
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
    self.filter = @"";
    searchController.searchBar.text = @"";
    [self.categoriesArray removeAllObjects];
    
    [self addNewCategory];
}

#pragma mark - searchbar delegate

- (void)searchBar:(UISearchBar *) __unused searchBar textDidChange:(NSString *)searchText
{
    self.filter = searchText;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.filter = searchBar.text;
     [self.categoriesArray removeAllObjects];
    [self addNewCategory];
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id)sender {
    [self.view endEditing:YES];
    
    if ([segue.identifier isEqualToString:kGroupSegue]) {
        GroupsViewController* groupsViewController = segue.destinationViewController;
        groupsViewController.categoryName = ((CategoryModel*)sender).name;
        groupsViewController.categoryID = ((CategoryModel*)sender).categoryID;
    }
}

#pragma mark - Empty table
- (UIImage *)imageForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return [UIImage imageNamed:@"logo-splash"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    NSString *text = @"There is no category yet";
    
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
