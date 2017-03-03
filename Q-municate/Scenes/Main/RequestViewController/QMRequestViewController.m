//
//  QMDialogsViewController.m
//  Q-municate
//
//  Created by Vitaliy Gorbachov on 1/13/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMRequestViewController.h"
#import "QMSearchResultsController.h"
#import "QMRequestsDataSource.h"
#import "QMPlaceholderDataSource.h"
#import "QMDialogsSearchDataSource.h"
#import "QMDialogCell.h"
#import "QMNoResultsCell.h"
#import "QMSearchDataProvider.h"
#import "QMDialogsSearchDataProvider.h"
#import "QMChatVC.h"
#import "QMCore.h"
#import "QMTasks.h"
#import <SVProgressHUD.h>
#import "QBChatDialog+OpponentID.h"
#import "QMSplitViewController.h"

// category
#import "UINavigationController+QMNotification.h"

static const NSInteger kQMUnAuthorizedErrorCode = -1011;

@interface QMRequestViewController ()

<
QMUsersServiceDelegate,
QMChatServiceDelegate,
QMChatConnectionDelegate,

UITableViewDelegate,
UISearchControllerDelegate,
UISearchResultsUpdating,

QMPushNotificationManagerDelegate,
QMDialogsDataSourceDelegate,
QMSearchResultsControllerDelegate
>

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) QMSearchResultsController *searchResultsController;

/**
 *  Data sources
 */
@property (strong, nonatomic) QMRequestsDataSource *dialogsDataSource;
@property (strong, nonatomic) QMPlaceholderDataSource *placeholderDataSource;
@property (strong, nonatomic) QMDialogsSearchDataSource *dialogsSearchDataSource;

@property (weak, nonatomic) BFTask *addUserTask;
@property (strong, nonatomic) id observerWillEnterForeground;

@end

@implementation QMRequestViewController

#pragma mark - Life cycle

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.observerWillEnterForeground];
    
    ILog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        // skip view controller setup if app was
        // instantinated to send a message from background
        return;
    }
    
    // Hide empty separators
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Subscribing delegates
    [[QMCore instance].chatService addDelegate:self];
    [[QMCore instance].usersService addDelegate:self];
    
    if ([QMCore instance].pushNotificationManager.pushNotification != nil) {
        [[QMCore instance].pushNotificationManager handlePushNotificationWithDelegate:self];
    }
    
    // adding refresh control task
    if (self.refreshControl) {
        
        self.refreshControl.backgroundColor = [UIColor whiteColor];
        [self.refreshControl addTarget:self
                                action:@selector(updateDialogsAndEndRefreshing)
                      forControlEvents:UIControlEventValueChanged];
    }
    
    
    
    @weakify(self);
    // adding notification for showing chat connection
    self.observerWillEnterForeground = [[NSNotificationCenter defaultCenter]
                                        addObserverForName:UIApplicationWillEnterForegroundNotification
                                        object:nil
                                        queue:nil
                                        usingBlock:^(NSNotification * _Nonnull __unused note) {
                                            
                                            @strongify(self);
                                            if (![QBChat instance].isConnected) {
                                                
                                                [self.navigationController showNotificationWithType:QMNotificationPanelTypeLoading message:NSLocalizedString(@"QM_STR_CONNECTING", nil) duration:0];
                                            }
                                        }];
}

- (void)performAutoLoginAndFetchData {
    
    [self.navigationController showNotificationWithType:QMNotificationPanelTypeLoading message:NSLocalizedString(@"QM_STR_CONNECTING", nil) duration:0];
    
    __weak UINavigationController *navigationController = self.navigationController;
    BFTask *loginTask = [[QMCore instance] login];
    if (loginTask == nil)
    {
        [navigationController dismissNotificationPanel];
        // search implementation
        [self configureSearch];
        
        // Data sources init
        [self configureDataSources];
        
        // registering nibs for current VC and search results VC
        [self registerNibs];
    } else {
        @weakify(self);
        [[loginTask continueWithBlock:^id _Nullable(BFTask * _Nonnull task) {
            
            if (task.isFaulted) {
                [navigationController dismissNotificationPanel];
                if (task.error.code == kQMUnAuthorizedErrorCode
                    || (task.error.code == kBFMultipleErrorsError
                        && ([task.error.userInfo[BFTaskMultipleErrorsUserInfoKey][0] code] == kQMUnAuthorizedErrorCode
                            || [task.error.userInfo[BFTaskMultipleErrorsUserInfoKey][1] code] == kQMUnAuthorizedErrorCode))) {
                            
                            return [[QMCore instance] logout];
                        }
            }
            
            // search implementation
            [self configureSearch];
            
            // Data sources init
            [self configureDataSources];
            
            // registering nibs for current VC and search results VC
            [self registerNibs];
            
            return [BFTask cancelledTask];
            
        }] continueWithBlock:^id _Nullable(BFTask * _Nonnull task) {
            @strongify(self);
            if (!task.isCancelled) {
                
                [self performSegueWithIdentifier:kQMSceneSegueAuth sender:nil];
            }
            
            return nil;
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateBadge];
    
    if (self.searchController.isActive) {
        self.tabBarController.tabBar.hidden = YES;
        // smooth rows deselection
        [self qm_smoothlyDeselectRowsForTableView:self.searchResultsController.tableView];
    }
    else {
        // smooth rows deselection
        [self qm_smoothlyDeselectRowsForTableView:self.tableView];
    }
    
    if (self.refreshControl.isRefreshing) {
        // fix for freezing refresh control after tab bar switch
        // if it is still active
        CGPoint offset = self.tableView.contentOffset;
        [self.refreshControl endRefreshing];
        [self.refreshControl beginRefreshing];
        self.tableView.contentOffset = offset;
    }
    

    [self performAutoLoginAndFetchData];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (IBAction)dismissScreen:(id) __unused sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Init methods

- (void)configureSearch {
    
    self.searchResultsController = [[QMSearchResultsController alloc] init];
    self.searchResultsController.delegate = self;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:self.searchResultsController];
    self.searchController.searchBar.placeholder = NSLocalizedString(@"QM_STR_SEARCH_BAR_PLACEHOLDER", nil);
    self.searchController.searchResultsUpdater = self;
    self.searchController.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.definesPresentationContext = YES;
    [self.searchController.searchBar sizeToFit]; // iOS8 searchbar sizing
    [self.searchController loadViewIfNeeded];
}

- (void)configureDataSources {
    
    self.dialogsDataSource = [[QMRequestsDataSource alloc] init];
    self.dialogsDataSource.delegate = self;
    self.placeholderDataSource  = [[QMPlaceholderDataSource alloc] init];
    
    if ([self.dialogsDataSource.items count] == 0)
    {
        self.tableView.dataSource = self.placeholderDataSource;
    } else{
        self.tableView.dataSource = self.dialogsDataSource;
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
    
    QMDialogsSearchDataProvider *searchDataProvider = [[QMDialogsSearchDataProvider alloc] init];
    searchDataProvider.delegate = self.searchResultsController;
    
    self.dialogsSearchDataSource = [[QMDialogsSearchDataSource alloc] initWithSearchDataProvider:searchDataProvider];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)__unused tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.tableView.dataSource isKindOfClass:[QMRequestsDataSource class]]) {
        
        QBChatDialog *chatDialog = self.dialogsDataSource.items[indexPath.row];
        
        if (![chatDialog.ID isEqualToString:[QMCore instance].activeDialogID]) {
            
            [self performSegueWithIdentifier:kQMSceneSegueChat sender:chatDialog];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return self.dialogsDataSource.items.count > 0 ? [self.dialogsDataSource heightForRowAtIndexPath:indexPath] : CGRectGetHeight(tableView.bounds) - tableView.contentInset.top - tableView.contentInset.bottom;
}

- (NSString *)tableView:(UITableView *)__unused tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    QBChatDialog *chatDialog = self.dialogsDataSource.items[indexPath.row];
    
    return chatDialog.type == QBChatDialogTypePrivate ? NSLocalizedString(@"QM_STR_DELETE", nil) : NSLocalizedString(@"QM_STR_LEAVE", nil);
}

#pragma mark - Actions

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:kQMSceneSegueChat]) {
        
        UINavigationController *chatNavigationController = segue.destinationViewController;
        
        QMChatVC *chatViewController = (QMChatVC *)chatNavigationController.topViewController;
        chatViewController.chatDialog = sender;
    }
}

#pragma mark - UISearchControllerDelegate

- (void)willPresentSearchController:(UISearchController *)__unused searchController {
    
    self.searchResultsController.tableView.dataSource = self.dialogsSearchDataSource;
    self.tabBarController.tabBar.hidden = YES;
}

- (void)willDismissSearchController:(UISearchController *)__unused searchController {
    
    self.tabBarController.tabBar.hidden = NO;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    [self.dialogsSearchDataSource.searchDataProvider performSearch:searchController.searchBar.text];
}

#pragma mark - QMSearchResultsControllerDelegate

- (void)searchResultsController:(QMSearchResultsController *)__unused searchResultsController willBeginScrollResults:(UIScrollView *)__unused scrollView {
    
    [self.searchController.searchBar endEditing:YES];
}

- (void)searchResultsController:(QMSearchResultsController *)__unused searchResultsController didSelectObject:(id)object {
    
    [self performSegueWithIdentifier:kQMSceneSegueChat sender:object];
}

#pragma mark - QMChatServiceDelegate

- (void)chatService:(QMChatService *)__unused chatService didAddChatDialogsToMemoryStorage:(NSArray *)__unused chatDialogs {
    
    [self checkIfDialogsDataSource];
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)__unused chatService didAddChatDialogToMemoryStorage:(QBChatDialog *)__unused chatDialog {
    
    [self checkIfDialogsDataSource];
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)__unused chatService didAddMessagesToMemoryStorage:(NSArray<QBChatMessage *> *)__unused messages forDialogID:(NSString *)__unused dialogID {
    
    
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)__unused chatService didAddMessageToMemoryStorage:(QBChatMessage *)__unused message forDialogID:(NSString *)__unused dialogID {
    
//    [self updateBadge];
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)__unused chatService didDeleteChatDialogWithIDFromMemoryStorage:(NSString *)__unused chatDialogID {
    
    if (self.dialogsDataSource.items.count == 0) {
        self.tableView.dataSource = self.placeholderDataSource;
        self.tableView.tableHeaderView = nil;
    }
    
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)__unused chatService didLoadChatDialogsFromCache:(NSArray *)dialogs withUsers:(NSSet *)__unused dialogsUsersIDs {
    
    if (dialogs.count > 0) {
        self.tableView.dataSource = self.dialogsDataSource;
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)__unused chatService didReceiveNotificationMessage:(QBChatMessage *)message createDialog:(QBChatDialog *)__unused dialog {
    
    if (message.addedOccupantsIDs.count > 0) {
        
        [[QMCore instance].usersService getUsersWithIDs:message.addedOccupantsIDs];
    }
    
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)__unused chatService didUpdateChatDialogInMemoryStorage:(QBChatDialog *)__unused chatDialog {
    
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)__unused chatService didUpdateChatDialogsInMemoryStorage:(NSArray<QBChatDialog *> *)__unused dialogs {
    
    [self.tableView reloadData];
}

#pragma mark - QMPushNotificationManagerDelegate

- (void)pushNotificationManager:(QMPushNotificationManager *)__unused pushNotificationManager didSucceedFetchingDialog:(QBChatDialog *)chatDialog {
    
    [self.tableView reloadData];
    [self performSegueWithIdentifier:kQMSceneSegueChat sender:chatDialog];
}

#pragma mark - QMChatConnectionDelegate

- (void)chatServiceChatDidConnect:(QMChatService *)__unused chatService {
    
    [QMTasks taskFetchAllData];
    [self.navigationController showNotificationWithType:QMNotificationPanelTypeSuccess message:NSLocalizedString(@"QM_STR_CHAT_CONNECTED", nil) duration:kQMDefaultNotificationDismissTime];
}

- (void)chatServiceChatDidReconnect:(QMChatService *)__unused chatService {
    
    [QMTasks taskFetchAllData];
    [self.navigationController showNotificationWithType:QMNotificationPanelTypeSuccess message:NSLocalizedString(@"QM_STR_CHAT_RECONNECTED", nil) duration:kQMDefaultNotificationDismissTime];
}

- (void)chatService:(QMChatService *)__unused chatService chatDidNotConnectWithError:(NSError *)error {
    
    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:NSLocalizedString(@"QM_STR_CHAT_FAILED_TO_CONNECT_WITH_ERROR", nil), error.localizedDescription]];
    [self updateDialogsAndEndRefreshing];
}

#pragma mark - QMUsersServiceDelegate

- (void)usersService:(QMUsersService *)__unused usersService didLoadUsersFromCache:(NSArray<QBUUser *> *)__unused users {
    
    if ([self.tableView.dataSource isKindOfClass:[QMRequestsDataSource class]]) {
        
        [self.tableView reloadData];
    }
}

- (void)usersService:(QMUsersService *)__unused usersService didAddUsers:(NSArray<QBUUser *> *)__unused user {
    
    if ([self.tableView.dataSource isKindOfClass:[QMRequestsDataSource class]]) {
        
        [self.tableView reloadData];
    }
}

- (void)usersService:(QMUsersService *)__unused usersService didUpdateUsers:(NSArray<QBUUser *> *)__unused users {
    
    if ([self.tableView.dataSource isKindOfClass:[QMRequestsDataSource class]]) {
        
        [self.tableView reloadData];
    }
}

#pragma mark - QMDialogsDataSourceDelegate

- (void) imageviewTapped: (NSInteger) tag
{
    if ([self.tableView.dataSource isKindOfClass:[QMRequestsDataSource class]]) {
        
        QBChatDialog *chatDialog = self.dialogsDataSource.items[tag];
        
        if (![chatDialog.ID isEqualToString:[QMCore instance].activeDialogID]) {
            
            [self performSegueWithIdentifier:kQMSceneSegueChat sender:chatDialog];
        }
    }
}

- (void)dialogsDataSource:(QMRequestsDataSource *)__unused dialogsDataSource commitDeleteDialog:(QBChatDialog *)chatDialog {
    
    NSString *dialogName = chatDialog.name;
    
    if (chatDialog.type == QBChatDialogTypePrivate) {
        
        QBUUser *user = [[QMCore instance].usersService.usersMemoryStorage userWithID:[chatDialog opponentID]];
        dialogName = user.fullName;
    }
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:nil
                                          message:[NSString stringWithFormat:NSLocalizedString(@"QM_STR_CONFIRM_DELETE_DIALOG", nil), dialogName]
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_CANCEL", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * _Nonnull __unused action) {
                                                          
                                                          [self.tableView setEditing:NO animated:YES];
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_DELETE", nil)
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction * _Nonnull __unused action) {
                                                          
                                                          BFContinuationBlock completionBlock = ^id _Nullable(BFTask * _Nonnull __unused task) {
                                                              
                                                              [SVProgressHUD dismiss];
                                                              return nil;
                                                          };
                                                          
                                                          [SVProgressHUD show];
                                                          [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
                                                          
                                                              // private chats
                                                              [[[QMCore instance].chatService deleteDialogWithID:chatDialog.ID] continueWithSuccessBlock:completionBlock];
                                                          
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - badge
- (void) updateBadge
{
    NSArray* unreadDialogs = [[[QMCore instance].chatService.dialogsMemoryStorage unreadDialogs] mutableCopy];
    NSUInteger dialogBadges = 0;
    NSUInteger requestBadges = 0;
    
    for (QBChatDialog*  dialog in unreadDialogs) {
        if (![dialog.lastMessageText containsString:@"Contact"])
        {
            dialogBadges += dialog.unreadMessagesCount;
        } else {
            requestBadges += dialog.unreadMessagesCount;
        }
    }
    
    NSArray *items = self.tabBarController.tabBar.items;
    if (requestBadges == 0)
    {
        [(UITabBarItem*)[items objectAtIndex:2] setBadgeValue:nil];
    } else {
        [(UITabBarItem*)[items objectAtIndex:2] setBadgeValue:[NSString stringWithFormat:@"%ld", (unsigned long)requestBadges]];
    }
    
    if (dialogBadges == 0) {
        [(UITabBarItem*)[items objectAtIndex:0] setBadgeValue:nil];
    } else {
        [(UITabBarItem*)[items objectAtIndex:0] setBadgeValue:[NSString stringWithFormat:@"%ld", (unsigned long)dialogBadges]];
    }
    
    [DataManager sharedManager].chatDialogBadge = dialogBadges;
    [DataManager sharedManager].chatContactBadge = requestBadges;
}
#pragma mark - Helpers

- (void)checkIfDialogsDataSource {
    NSArray *dialogs = [self getDialogsOnly:[[[QMCore instance].chatService.dialogsMemoryStorage dialogsSortByLastMessageDateWithAscending:NO] mutableCopy]];
    if ([dialogs count] > 0) {
        
        self.tableView.dataSource = self.dialogsDataSource;
        self.tableView.tableHeaderView = self.searchController.searchBar;
    }
    
}

- (NSMutableArray*) getDialogsOnly: (NSMutableArray*) dialogs
{
    NSMutableArray* requests = [NSMutableArray new];
    for (QBChatDialog *temp in dialogs) {
        if ([temp.lastMessageText containsString:@"Contact"])
        {
            [requests addObject:temp];
        }
    }
    
    return requests;
}

- (void)updateDialogsAndEndRefreshing {
    
    @weakify(self);
    [[QMTasks taskFetchAllData] continueWithBlock:^id _Nullable(BFTask * _Nonnull __unused task) {
        
        @strongify(self);
        
        [self.refreshControl endRefreshing];
        
        return nil;
    }];
}

#pragma mark - Register nibs

- (void)registerNibs {
    
    [QMDialogCell registerForReuseInTableView:self.tableView];
    [QMDialogCell registerForReuseInTableView:self.searchResultsController.tableView];
    
    [QMNoResultsCell registerForReuseInTableView:self.searchResultsController.tableView];
}

@end
