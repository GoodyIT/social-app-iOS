//
//  GroupDetailViewController.m
//  reach-ios
//
//  Created by Admin on 2016-12-29.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "GroupDetailViewController.h"
#import "UserProfileViewController.h"
#import "UserListViewController.h"
#import "ReplyViewController.h"
#import "QMAlert.h"
#import "NSError+Network.h"
#import <JSQMessagesViewController/JSQMessagesInputToolbar.h>
#import <JSQMessagesKeyboardController.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIColor+CustomColors.h"
#import "GroupDetailCell.h"
#import <QMImageView.h>
#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import "QMImagePreview.h"
#import "QMHelpers.h"

@interface GroupDetailViewController () <GroupDetailCellDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, GroupDetailCellDelegate, QMImageViewDelegate, JSQMessagesInputToolbarDelegate, UITextViewDelegate>
{
    UIEdgeInsets contentInsets;
    CGPoint _lastContentOffset;
    __block BOOL    isFirstShown;
    BOOL    previousInputMode;
    double initialContraint;
}

@property (weak, nonatomic) IBOutlet QMImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *owername;
@property (weak, nonatomic) IBOutlet UILabel *groupTitle;
@property (weak, nonatomic) IBOutlet UILabel *groupCategory;
@property (weak, nonatomic) IBOutlet UILabel *groupBio;
@property (weak, nonatomic) IBOutlet UILabel *numberOfMembers;
@property (weak, nonatomic) IBOutlet UIImageView *memberImageView;
@property (weak, nonatomic) IBOutlet UILabel *numberOfTopics;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIButton *joinBtn;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentViewBottomContraint;
@property (weak, nonatomic) IBOutlet JSQMessagesInputToolbar *commentInputToolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoryBackgroundWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *tableHeaderView;

@end

static CGFloat oldContextSize;
static CGFloat newContextSize;

CGFloat kTableHeaderHeight = 300.0;

@implementation GroupDetailViewController
@synthesize group;
@synthesize groupID;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareHeaderTableView];
    
    [self prepareUI];
    
    [self registerNibs];
    
    if (groupID != nil) {
        [self getGroupDetail];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGroup:) name:@"UpdateGroup" object:nil];
}
    
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self addKeyboardObservers];
    isFirstShown = YES;
}

/*
 Receive the notification about the update from join group, create status and add comment/reply
 */
- (void) updateGroup: (NSNotification*) notification
{
    GroupModel *updatedGroup =  [notification.object objectForKey:@"group"];
    if (updatedGroup != nil) {
        self.group = updatedGroup;
    }
    
    [self.tableView reloadData];
    [self prepareHeaderTableView];
}

- (void) getGroupDetail
{
    @weakify(self)
    [[[QMNetworkManager sharedManager] getGroupWithID:groupID] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
        
        if (t.isFaulted) {
            [SVProgressHUD showErrorWithStatus:t.error.localizedDescription];
            return nil;
        }
        
        @strongify(self)
        self.group = [GroupModel getGroupFromResponse:t.result[@"circle"]];
        [self prepareHeaderTableView];
        [self.tableView reloadData];
        
        return nil;
    }];
    
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationWillEnterForegroundNotification
     object:nil
     queue:nil
     usingBlock:^(NSNotification * _Nonnull __unused note) {
         @strongify(self);
         self->isFirstShown = YES;
     }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeInputMode:)
                                                 name:UITextInputCurrentInputModeDidChangeNotification object:nil];
}

-(void)changeInputMode:(NSNotification *)__unused notification
{
    UITextInputMode *currentInputMode = self.commentInputToolbar.textInputMode;
    
    if (currentInputMode == nil)
    {
        previousInputMode = 1; // Normal Keyboard;
    } else {
        previousInputMode = 0; // Emoji  Keyboard
    }
}

- (void) topicDict:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [super.view endEditing:YES];
    [self removeKeyboardObservers];
    [SVProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) updateHeaderView
{
    CGRect headerRect = CGRectMake(0, -kTableHeaderHeight-64, self.view.bounds.size.width, kTableHeaderHeight);
    if  (self.tableView.contentOffset.y < -kTableHeaderHeight)
    {
        headerRect.origin.y = self.tableView.contentOffset.y;
        headerRect.size.height = -self.tableView.contentOffset.y;
    }
    
//    self.headerView.frame = headerRect;
}

- (void) prepareUI
{
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor],
       NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:21.0]}];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    UITapGestureRecognizer *memberTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didMemberTap)];
    memberTap.cancelsTouchesInView = NO;
    self.memberImageView.userInteractionEnabled = YES;
    [self.memberImageView addGestureRecognizer:memberTap];
    [self.numberOfMembers addGestureRecognizer:memberTap];
    
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
    
//    [[NSNotificationCenter defaultCenter]
//     addObserverForName:UIApplicationWillEnterForegroundNotification
//     object:nil
//     queue:nil
//     usingBlock:^(NSNotification * _Nonnull __unused note) {
//         @strongify(self);
//         if (self == nil) {
//             return;
//         }
//         self->isFirstShown = YES;
//     }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeInputMode:)
                                                 name:UITextInputCurrentInputModeDidChangeNotification object:nil];
    
    self.commentInputToolbar.delegate = self;
    self.commentInputToolbar.contentView.textView.delegate = self;
    self.commentInputToolbar.contentView.textView.keyboardType = UIKeyboardTypeTwitter;
    
    self.commentInputToolbar.contentView.leftBarButtonItem = nil;
    self.commentInputToolbar.barTintColor = [UIColor whiteColor];
    [self.commentInputToolbar.contentView.rightBarButtonItem setTitleColor:[UIColor skyBlueColor] forState:UIControlStateNormal];
    
    self.commentInputToolbar.maximumHeight = (int)(self.view.frame.size.height / 4.0f);
    
    [self.commentInputToolbar toggleSendButtonEnabled];
    
    oldContextSize = self.commentInputToolbar.contentView.textView.frame.size.height;
    newContextSize = 0.f;
    
    initialContraint = self.commentViewBottomContraint.constant;
    
    // header
    self.avatarImageView.imageViewType = QMImageViewTypeCircle;
}
- (IBAction)memberClicked:(id)__unused sender {
    [self didMemberTap];
}

- (void) didMemberTap
{
    [self performSegueWithIdentifier:kUserListSegue sender:self.group.members];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.groupBio.preferredMaxLayoutWidth = self.view.frame.size.width-24;
    
    UIView* headerView = self.tableView.tableHeaderView;
    
    [headerView setNeedsLayout];
    [headerView layoutIfNeeded];
    
    CGFloat height = [headerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    CGRect headerFrame = headerView.frame;
    headerFrame.size.height = height;
    
    headerView.frame = headerFrame;

    self.tableView.tableHeaderView = headerView;
}

- (void)prepareHeaderTableView {
    NSString* subString = [NSString stringWithFormat:@"(%@) %@", group.category.name, group.name];
    NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:subString attributes:@{NSFontAttributeName :[UIFont fontWithName:@"AvenirNext-Medium" size:15.0],                                                                                                                                  NSForegroundColorAttributeName : [UIColor blackColor]}];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-DemiBold" size:15.0] range:NSMakeRange(0, group.category.name.length+2)];
    self.groupTitle.attributedText = attributedString;
    
    self.groupBio.text = self.group.groupDescription;
    self.categoryBackgroundWidthConstraint.constant = getLabelHeight(self.groupBio);
    self.numberOfMembers.text = [NSString stringWithFormat:@"%@", (group.memberCount == nil) ? @(0):group.memberCount];
    self.numberOfTopics.text = [NSString stringWithFormat:@"%ld", (unsigned long)group.topics.count];
    
    if ([group.permission boolValue]) {
        [self.avatarImageView setImageWithURL:[NSURL URLWithString:group.owner.avatarURL] placeholder:[UIImage imageNamed:@"default"] options:SDWebImageHighPriority progress:nil completedBlock:nil];
        self.owername.text = [NSString stringWithFormat:@"Started by %@", group.owner.userName];
        self.avatarImageView.delegate = self;
    } else {
        self.avatarImageView.image = [UIImage imageNamed:@"default-avatar"];
        self.owername.text = @"Started by Anonymous";
    }
    
    if ([group.joined boolValue]) {
        [self.joinBtn setTitle:@"Joined" forState:UIControlStateNormal];
    } else {
        [self.joinBtn setTitle:@"Join" forState:UIControlStateNormal];
    }
    
    if  ([group.owner.email isEqualToString:[QBSession currentSession].currentUser.email])
    {
        self.joinBtn.enabled = NO;
    }
    
    [self.backgroundImage sd_setImageWithURL:[NSURL URLWithString:group.imageURL]
                                placeholderImage:[UIImage imageNamed:@"profile_back"]];
    
    UITapGestureRecognizer *backgroundTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped)];
    backgroundTap.numberOfTapsRequired = 1;
    [self.backgroundImage addGestureRecognizer:backgroundTap];
    
    self.backgroundImage.clipsToBounds = YES;
    
    [self.tableView setNeedsLayout];
}

- (void) backgroundTapped
{
    [self.view endEditing:YES];
    [QMImagePreview previewImageWithURL:[NSURL URLWithString:group.imageURL] inViewController:self];
}

- (void)registerNibs {
    
    [GroupDetailCell registerForReuseInTableView:self.tableView];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = THE_CELL_HEIGHT/2;
}


- (IBAction)onBackAction:(id) __unused sender {
    [self.view endEditing:YES];
    if (groupID != nil) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)sendReplyToTopic:(id) __unused sender {

    @weakify(self);
    [SVProgressHUD showWithStatus:@"Sending..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [[[QMNetworkManager sharedManager] createNewTopicWithGroupID:group.groupID text:self.commentInputToolbar.contentView.textView.text permission:group.permission] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        @strongify(self);
        [SVProgressHUD dismiss];
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }

//        if (self.tableView.numberOfSections != 0)
//        {
//            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.tableView.numberOfSections - 1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//        }
      
        [SVProgressHUD showSuccessWithStatus:@"Succesfully added"];
        
        self.commentInputToolbar.contentView.textView.text = @"";
        
        self.group = [GroupModel getGroupFromResponse:[serverTask.result valueForKey:@"circle"]];
        
        NSArray *reversed = [[self.group.topics reverseObjectEnumerator] allObjects];
        self.group.topics = [reversed mutableCopy];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGroup" object:@{@"group": self.group}];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self prepareHeaderTableView];            
            
        });
        
        [self.tableView reloadData];
        
        return nil;
    }];
    
    [self.view endEditing:YES];
    self.toolbarHeight.constant = 44;
    newContextSize = 44;
    oldContextSize = 44;
}

- (void)addKeyboardObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeKeyboardObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification*) notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if (keyboardSize.height != 0.0f)
    {     
        double duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        @weakify(self);
        [UIView animateWithDuration:duration
                         animations:^{
                             self.commentViewBottomContraint.constant = keyboardSize.height;
                             if (self->isFirstShown){
                                 self->isFirstShown = NO;
                             } else if (self->previousInputMode == 1) {
                                 self.commentViewBottomContraint.constant += constraintForEmoji;
                             } else if (self->previousInputMode == 0) {
                                 self.commentViewBottomContraint.constant -=constraintForEmoji;
                             }
                             [self.view layoutIfNeeded];
                         } completion:^(BOOL __unused finished) {
                             @strongify(self);
                             if (self->group.topics.count != 0)
                             {
                                 [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self->group.topics.count-1] atScrollPosition:UITableViewScrollPositionBottom  animated:YES];
                             } else {
                                 if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad){
                                 CGFloat headerHeight = self.view.frame.size.height - 66 - self.tableHeaderView.frame.size.height;
                                 headerHeight = keyboardSize.height - headerHeight;
                                 [self.tableView setContentOffset:CGPointMake(0, headerHeight)];
                                 }
                             }
                         }];
    }
}

- (void)keyboardWillHide:(NSNotification*) notification {
    CGSize __unused keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if (keyboardSize.height != 0.0f)
    {
        double duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        [UIView animateWithDuration:duration
                         animations:^{
                             self.commentViewBottomContraint.constant = self->initialContraint;
                             [self.view layoutIfNeeded];
                             [self.tableView setContentOffset:CGPointZero];                         }];
    }
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView {
    
    self.commentInputToolbar.contentView.rightBarButtonItem.enabled = (textView.text.length > 0) ? YES : NO;
    
    CGSize size = [textView sizeThatFits:textView.frame.size];
    newContextSize = size.height;
    
    if (newContextSize < 44) {
        self.toolbarHeight.constant = 44;
        newContextSize = 44;
        oldContextSize = 44;
//        return;
    }
    
    if (newContextSize >= self.commentInputToolbar.maximumHeight) {
        return;
    }
    
    if (newContextSize > oldContextSize) {
        oldContextSize = newContextSize;
        //textView.frame.size = CGSizeMake(textView.frame.size.width, size.height);
        self.toolbarHeight.constant += 12;
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, contentInsets.bottom + 12, 0.0);
//        self.tableView.contentInset = contentInsets;
//        self.tableView.scrollIndicatorInsets = contentInsets;
    }
    
    if (newContextSize < oldContextSize) {
        oldContextSize = newContextSize;
        if (newContextSize < self.commentInputToolbar.maximumHeight && newContextSize > 44) {
            self.toolbarHeight.constant -= 12;
            contentInsets = UIEdgeInsetsMake(0.0, 0.0, contentInsets.bottom - 12, 0.0);
//            self.tableView.contentInset = contentInsets;
//            self.tableView.scrollIndicatorInsets = contentInsets;
        }
    }
}

#pragma mark - JSQMessagesInputToolbarDelegate

- (void)messagesInputToolbar:(JSQMessagesInputToolbar *) __unused toolbar
      didPressRightBarButton:(UIButton *) __unused sender {
    if([self.commentInputToolbar.contentView.textView.text length] <= 255){
        if ([self.commentInputToolbar.contentView.textView.text length] < 10)
        {
            [QMAlert showAlertWithMessage:@"Comment is too short. It must be longer  then 10 symblos!" actionSuccess:NO inViewController:self];
            return;
        }
        [self sendReplyToTopic:nil];
    } else {
        [QMAlert showAlertWithMessage:@"Comment is too long. It must be no longer  then 255 symblos!" actionSuccess:NO inViewController:self];
    }
}

- (void)messagesInputToolbar:(JSQMessagesInputToolbar *) __unused toolbar
       didPressLeftBarButton:(UIButton *) __unused sender
{
    
}
- (void)touchesBegan:(NSSet<UITouch *> *) __unused touches withEvent:(UIEvent *) __unused event {
    [self.view endEditing:YES];
}

#pragma mark - ScrollView delegate

- (void) scrollViewDidScroll:(UIScrollView *)__unused scrollView
{
//    [self updateHeaderView];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)__unused tableView {
    if  (group.topics == nil){
        return 0;
    }
    return [group.topics count];
}

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section {

    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GroupDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:[GroupDetailCell cellIdentifier] forIndexPath:indexPath];
    
    cell.delegate = self;
    cell.tag = indexPath.section;
    [cell configureCellWithGroupDetailInfo:self.group.topics[indexPath.section]];
    
    return cell;
}

- (void)tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   [self performSegueWithIdentifier:kTopicReplySegue sender:self.group.topics[indexPath.section]];
   [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - GroupDetailCell delegate

- (void) didTapAvatar:(GroupDetailCell *)cell
{
    TopicModel *topic = self.group.topics[cell.tag];
    if(![topic.permission boolValue]) {
        return;
    }
    
    [self performSegueWithIdentifier:kProfileSegue sender:topic.author];
}

- (IBAction)didTapJoinBtn:(id) __unused sender {
    [self.view endEditing:YES];
    
    @weakify(self);
    [SVProgressHUD showWithStatus:@"Joining..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [[[QMNetworkManager sharedManager] joinGroupWithGroupID:group.groupID] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        @strongify(self);
        if(self == nil) return nil;
        [SVProgressHUD dismiss];
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        self.group = [GroupModel getGroupFromResponse:[serverTask.result valueForKey:@"circle"]];
        NSArray *reversed = [[self.group.topics reverseObjectEnumerator] allObjects];
        self.group.topics = [reversed mutableCopy];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGroup" object:@{@"group": self.group, @"action":@"Join"}];
        
        [self prepareHeaderTableView];

        [self.tableView reloadData];
        return nil;
    }];
}

#pragma mark - QMImageViewDelegate

- (void)imageViewDidTap:(QMImageView *) __unused imageView {
    if(![group.permission boolValue]) {
        return;
    }
 
    [self performSegueWithIdentifier:kProfileSegue sender:group.owner];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)__unused scrollView withVelocity:(CGPoint)__unused velocity targetContentOffset:(inout CGPoint *)__unused targetContentOffset
{
    [self.view endEditing:YES];
    isFirstShown = YES;
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
    
    if ([segue.identifier isEqualToString:kTopicReplySegue]) {
        ReplyViewController* replyViewController = segue.destinationViewController;
        TopicModel* selectedTopic = sender;
        replyViewController.topic = sender;
        replyViewController.topicID = selectedTopic.topicID;
        replyViewController.group = self.group;
    }
    
    if ([segue.identifier isEqualToString:kUserListSegue])
    {
        UserListViewController* userListViewController = segue.destinationViewController;
        userListViewController.members = sender;
    }
}

#pragma mark - Empty table
//- (UIImage *)imageForEmptyDataSet:(UIScrollView *) __unused scrollView
//{
//    return [UIImage imageNamed:@"logo-splash"];
//}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    NSString *text = @"There is no status yet";
    
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
    return 210;
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
