//
//  ReplyViewController.m
//  reach-ios
//
//  Created by Admin on 2016-12-29.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "ReplyViewController.h"
#import "AllPostViewController.h"
#import "TopicFirstCell.h"
#import "TopicReplyCell.h"
#import "UserProfileViewController.h"
#import "GroupDetailViewController.h"
#import "QMAlert.h"
#import "NSError+Network.h"
#import <JSQMessagesViewController/JSQMessagesInputToolbar.h>
#import <JSQMessagesKeyboardController.h>
#import "UIColor+CustomColors.h"

@interface ReplyViewController ()<UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, TopicFirstCellDelegate, TopicReplyCellDelegate, JSQMessagesInputToolbarDelegate, UITextViewDelegate>
{
    UIEdgeInsets contentInsets;
    CGPoint _lastContentOffset;
    double initialContraint;
    NSUInteger    previousInputMode;
    __block BOOL        isFirstShown;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentViewBottomContraint;
@property (weak, nonatomic) IBOutlet JSQMessagesInputToolbar *commentInputToolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopConstraint;

@end

static CGFloat oldContextSize;
static CGFloat newContextSize;

@implementation ReplyViewController
@synthesize topic;
@synthesize topicID;
@synthesize group;

- (void)viewDidLoad {
    [super viewDidLoad];
        
    [self prepareUI];
    
    [self registerNibs];
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

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self addKeyboardObservers];
    isFirstShown = YES;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [super.view endEditing:YES];
    [self removeKeyboardObservers];
    [SVProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) prepareUI
{
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
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
    
    [[NSNotificationCenter defaultCenter]
     addObserverForName:UIApplicationWillEnterForegroundNotification
     object:nil
     queue:nil
     usingBlock:^(NSNotification * _Nonnull __unused note) {
         @strongify(self);
         if (self == nil) {
             return;
         }
         self->isFirstShown = YES;
     }];

    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow: ([self.tableView numberOfRowsInSection:([self.tableView numberOfSections]-1)]-1) inSection:([self.tableView numberOfSections]-1)];
        
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    });
    
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
    
//    self.tableViewTopConstraint.constant = -64;
}

- (void)registerNibs {
    
    [TopicFirstCell registerForReuseInTableView:self.tableView];
    [TopicReplyCell registerForReuseInTableView:self.tableView];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = THE_CELL_HEIGHT;
}

- (IBAction)onBackAction:(id) __unused sender {
    [self.view endEditing:YES];
    NSInteger count = self.navigationController.viewControllers.count;
    GroupDetailViewController *previousController = self.navigationController.viewControllers[count-2];
    previousController.group = group;
    [self.navigationController popViewControllerAnimated:YES];
}

- (TopicModel*) getMatchedTopic: (NSArray*) topics withTopicID: (NSNumber*) ID
{
    for (TopicModel* topicModel in topics) {
        if ([topicModel.topicID isEqual:ID]) {
            return topicModel;
        }
    }
    
    return nil;
}

- (IBAction)sendReplyToTopic:(id) __unused sender {
    @weakify(self);
    [SVProgressHUD showWithStatus:@"Sending..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [[[QMNetworkManager sharedManager] replyToTopic:self.topic.topicID Text:self.commentInputToolbar.contentView.textView.text Permission:self.topic.permission] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        @strongify(self);
        [SVProgressHUD dismiss];
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        if (self.tableView.numberOfSections != 0)
        {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.tableView.numberOfSections - 1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }

        [SVProgressHUD showSuccessWithStatus:@"Succesfully added"];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        self.commentInputToolbar.contentView.textView.text = @"";
        
        self.group = [GroupModel getGroupFromResponse:[serverTask.result valueForKey:@"circle"]];
        NSArray *reversed = [[self.group.topics reverseObjectEnumerator] allObjects];
        self.group.topics = [reversed mutableCopy];
        self.topic = [self getMatchedTopic:self.group.topics withTopicID:self.topicID];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGroup" object:@{@"group": self.group}];
        
        [self.tableView reloadData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow: ([self.tableView numberOfRowsInSection:([self.tableView numberOfSections]-1)]-1) inSection:([self.tableView numberOfSections]-1)];
            
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        });
        
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
                             [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self->topic.replies.count] atScrollPosition:UITableViewScrollPositionTop  animated:YES];
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
                         }];
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
    [self.view endEditing:YES];
    
    if([self.commentInputToolbar.contentView.textView.text length] <= 1000){
        if ([self.commentInputToolbar.contentView.textView.text length] < 10)
        {
            [QMAlert showAlertWithMessage:@"Comment is too short. It must be longer  then 10 symblos!" actionSuccess:NO inViewController:self];
            return;
        }
        [self sendReplyToTopic:nil];
    } else {
        [QMAlert showAlertWithMessage:@"Comment is too long. It must be no longer  then 1000 symblos!" actionSuccess:NO inViewController:self];
    }
    
}

- (void)messagesInputToolbar:(JSQMessagesInputToolbar *) __unused toolbar
       didPressLeftBarButton:(UIButton *) __unused sender
{
    
}
- (void)touchesBegan:(NSSet<UITouch *> *) __unused touches withEvent:(UIEvent *) __unused event {
    [self.view endEditing:YES];
}

- (void) performVoteToComment: (NSNumber*)__unused  commentID statement: (NSNumber*)__unused  statement
{
    [self.view endEditing:YES];
}

#pragma mark - Tap Delegate

- (void) didTapDownVote:(TopicReplyCell *)cell
{
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    NSInteger index = indexPath.section-1;
    CommentModel *comment = topic.replies[index];
    
    if ([comment.isDownvoted boolValue]) {
        [SVProgressHUD showErrorWithStatus:@"You already dislike this post"];
        return;
    }
    
    [self performVoteToComment:comment.commentID statement:[NSNumber numberWithBool:NO]];
}

- (void) didTapUpVote:(TopicReplyCell *)cell
{
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    NSInteger index = indexPath.section-1;
    CommentModel *comment = topic.replies[index];
    
    if ([comment.isUpvoted boolValue]) {
        [SVProgressHUD showErrorWithStatus:@"You already like this post"];
        return;
    }
    
    [self performVoteToComment:comment.commentID statement:[NSNumber numberWithBool:YES]];
}

- (void) didTapAvatar: (TopicReplyCell*)__unused  cell
{
    [self performSegueWithIdentifier:kProfileSegue sender:self.topic.author];
}

- (void) didTapAvatarFirst:(TopicFirstCell *)cell
{
    if  ([self.topic.permission boolValue]) {
        CommentModel* commentModel = self.topic.replies[cell.tag];
        [self performSegueWithIdentifier:kProfileSegue sender:commentModel.author];
    }
}

- (void) didTapReply:(TopicReplyCell *)cell
{
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    NSInteger index = indexPath.section-1;
    CommentModel *comment = topic.replies[index];
    self.commentInputToolbar.contentView.textView.text = [NSString stringWithFormat:@"@%@ ", comment.author.userName];
    [self.commentInputToolbar.contentView.textView becomeFirstResponder];
    
    [self.tableView scrollToRowAtIndexPath:[self.tableView indexPathForCell:cell] atScrollPosition:UITableViewScrollPositionTop  animated:YES];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillEndDragging:(UIScrollView *)__unused scrollView withVelocity:(CGPoint)__unused velocity targetContentOffset:(inout CGPoint *)__unused targetContentOffset
{
    isFirstShown = YES;
    [self.view endEditing:YES];
}

#pragma mark - Empty table

- (UIImage *)imageForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return [UIImage imageNamed:@"logo-splash"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    NSString *text = @"There Is No Comment yet.";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return -50;
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return [UIColor whiteColor];
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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView {
    
    if (topic.replies == nil) {
        return 1;
    }
    
    return [topic.replies count] + 1;
}

- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger) __unused section {
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        TopicFirstCell *firstCell = [tableView dequeueReusableCellWithIdentifier:[TopicFirstCell cellIdentifier] forIndexPath:indexPath];
        [firstCell configureCell:topic];
        firstCell.delegate = self;
        return firstCell;
    }
    
    TopicReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:[TopicReplyCell cellIdentifier] forIndexPath:indexPath];
    cell.delegate = self;
    [cell configureCellWithTopicInfo:topic.replies[indexPath.section-1]];
    
    @weakify(self);
    cell.userComment.hashtagLinkTapHandler = ^(KILabel* __unused label, NSString *string, NSRange __unused range) {
        //  string = [string stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSLog(@"\n\nTableView\n\n");
        @strongify(self);
        [self.view endEditing:YES];
        [self performSegueWithIdentifier:kHashTagSegue sender:string];
    };
    
    cell.userComment.userHandleLinkTapHandler  = ^(KILabel* __unused label, NSString  *string, NSRange __unused range) {
        NSRange nameRange = NSMakeRange(1, string.length-1);
        NSString *userName = [string substringWithRange:nameRange];
        [self.tableView setUserInteractionEnabled:NO];
        @strongify(self);
        [self.view endEditing:YES];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [[[QMNetworkManager sharedManager] getUserByName:userName] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            if(self == nil) return nil;
            [self.tableView setUserInteractionEnabled:YES];
            if  (serverTask.isFaulted)
            {
                [SVProgressHUD showErrorWithStatus:@"This user does not exist"];
                return nil;
            }
            UserModel* _user = [UserModel getUserWithResponce:[serverTask.result valueForKey:@"user"]];
            [self performSegueWithIdentifier:kProfileSegue sender:_user];
            return nil;
        }];
    };
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id) __unused sender {
    [self.view endEditing:YES];
    
    if ([segue.identifier isEqualToString:kProfileSegue]) {
        UINavigationController* navigationController = segue.destinationViewController;
        UserProfileViewController* profileViewController = navigationController.viewControllers.firstObject;
        profileViewController.user = sender;
    }
    
    if ([segue.identifier isEqualToString:kHashTagSegue]) {
        UINavigationController* navigationController = segue.destinationViewController;
        AllPostViewController* allPostViewController = navigationController.viewControllers.firstObject;
        allPostViewController.title = sender;
        allPostViewController.hashtag = sender;
    }
}

@end
