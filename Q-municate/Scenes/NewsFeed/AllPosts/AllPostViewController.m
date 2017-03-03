//
//  AllPostViewController.m
//  reach-ios
//
//  Created by Admin on 2016-12-06.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "AllPostViewController.h"
#import "NewsFeedCellTableViewCell.h"
#import "UserProfileViewController.h"
#import "CommentViewController.h"
#import "NewPostController.h"

#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import "QMImagePreview.h"
#import "QMAlert.h"

@interface AllPostViewController ()<AllPostViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NYTPhotosViewControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIActionSheetDelegate>
{
    __block BOOL isTopRefreshing;
    __block BOOL isBottomRefreshing;
    __block BOOL isLikeTapped;
    __block BOOL isFirstLoading;
    BOOL         isPostEdit;
}

@property (strong, nonatomic) NSNumber *postID;
@property (strong, nonatomic) RKNotificationHub* hub ;
@property (strong, nonatomic) UIImageView *postView;

@property (strong, nonatomic) UIRefreshControl *bottomRefresh;
@property (strong, nonatomic) NewsFeedCellTableViewCell* selectedCell;

//@property (strong, nonatomic) __block NSString* shouldRefresh;

@property (strong, nonatomic) BFTask* task;

@end

@implementation AllPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addTapGesture];
    
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
    
    isFirstLoading = YES;
    [self addNewPostWithCompletion:^{
        @strongify(self);
        [self registerNibs];
        [self prepareUI];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostFrom:) name:@"NewPost" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostFromLike:) name:@"LikePost" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onBackAction:(id) __unused sender {
    [self.view endEditing:YES];
    [self.navigationController  dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Initialization

- (void) prepareUI
{
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor clearColor];
    self.refreshControl.tintColor = [UIColor blackColor];
    [self.refreshControl addTarget:self
                            action:@selector(addNewPost)
                  forControlEvents:UIControlEventValueChanged];
    
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
    
    [NewsFeedCellTableViewCell registerForReuseInTableView:self.tableView];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = THE_CELL_HEIGHT;
}

- (NSNumber *)newPostID {
    if (self.postsArray == nil || [self.postsArray count] == 0 || isFirstLoading) {
        return @-1;
    }
    
    PostModel* post =  (PostModel*)self.postsArray.firstObject;
    return post.postID;
}

- (NSNumber*) oldPostID {
    
    if (self.postsArray == nil || [self.postsArray count] == 0) {
        return @-1;
    }
    
    PostModel* post =  (PostModel*)self.postsArray.lastObject;
    return post.postID;
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

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    [SVProgressHUD dismiss];
}

- (void) addNewPostWithCompletion: (void (^)(void)) completion
{
    if (self.hashtag == nil || [self.hashtag isEqualToString:@""]) {
        [self _addNewPostWithCompletion:completion];
    } else {
        [self _addNewPostWithHashTagWithCompletion: completion];
    }
}

- (void) deletePostFromArray:(NSNumber*) postID
{
    for (PostModel* post in self.postsArray) {
        if ([post.postID isEqual:postID]) {
            [self.postsArray removeObject:post];
            break;
        }
    }
}

- (void) updatePostsArray: (PostModel*) post
{
    NSUInteger index = 0;
    for (PostModel* _post in self.postsArray) {
        if ([_post.postID integerValue] == [post.postID integerValue]) {
            [self.postsArray replaceObjectAtIndex:index withObject:post];
            break;
        }
        index++;
    }
}

- (void) updatePostFromLike: (NSNotification*) notification
{
    NewsFeedCellTableViewCell* cell = [notification.object objectForKey:@"cell"];
    
    PostModel *post = [notification.object objectForKey:@"post"];
    [self updatePostsArray:post];
    
    NSString* source = [notification.object objectForKey:@"source"];
    if ([source isEqualToString:@"AllPosts"]){
        [cell updateLike:post];
        NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [self.tableView reloadData];
    }
}

- (void) updatePostFrom: (NSNotification*) notification
{
    PostModel *post = [notification.object objectForKey:@"post"];
    NSNumber* postID = [notification.object objectForKey:@"postID"];
    if (post != nil) {
        [self updatePostsArray:post];
        [self.tableView reloadData];
    } else if (postID != nil) {
      
        [self deletePostWithID:postID];
        
        [self.tableView reloadData];
    } else {
        isFirstLoading = YES;
        [self addNewPost];
    }
}

- (void) addNewPost
{
    if (isTopRefreshing) {
        return;
    }
    isTopRefreshing = YES;
    [self addNewPostWithCompletion:nil];
}

- (void) _addNewPostWithHashTagWithCompletion: (void (^)(void)) completion
{
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] searchPostByHashtag:self.hashtag fromPost:[self newPostID] withType:@"new" ] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        @strongify(self);
        if (self == nil) return nil;
        self->isTopRefreshing = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[PostModel getPostListFromResponse:serverTask.result]];
        
        if (self->isFirstLoading) {
            self.postsArray = resultArray;
        } else {
            [resultArray addObjectsFromArray:self.postsArray];
            self.postsArray = [resultArray mutableCopy];
        }
        
        if (self.refreshControl.isRefreshing) {
            self.refreshControl.attributedTitle = [self getLastRefreshingTime];
            [self.refreshControl endRefreshing];
        }
        
        if  (completion != nil) {
            completion();
        }
        
        [self.tableView reloadData];
        self->isFirstLoading = NO;
        return nil;
    }];
}

- (void) _addNewPostWithCompletion: (void (^)(void)) completion
{
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] getUserPostsFrom:[self newPostID] withType:@"new"] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        @strongify(self);
        if (self == nil) return nil;
        self->isTopRefreshing = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
   
        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[PostModel getPostListFromResponse:serverTask.result]];
        if (self->isFirstLoading) {
            self.postsArray = resultArray;
        } else {
            [resultArray addObjectsFromArray:self.postsArray];
            self.postsArray = [resultArray mutableCopy];
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

- (void)updatePosts
{
    if  (isBottomRefreshing)
    {
        return;
    }
    isBottomRefreshing = YES;
    if (self.hashtag == nil || [self.hashtag isEqualToString:@""]) {
        [self getAllPosts];
    } else {
        [self getPostsFromHashtag];
    }
    [self.tableView layoutIfNeeded];
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

- (void) getPostsFromHashtag
{
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] searchPostByHashtag:self.hashtag fromPost:[self oldPostID] withType:@"old" ] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        @strongify(self);
        if (self == nil) return nil;
        self->isBottomRefreshing = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }
        
        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[PostModel getPostListFromResponse:serverTask.result]];
        BOOL shouldReloaded = resultArray.count != 0;
        [self.postsArray addObjectsFromArray:resultArray];
        
        if  (shouldReloaded)
        {
            [self.tableView reloadData];
        }
        return nil;
    }];
}

- (void)getAllPosts
{
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.task = [[[QMNetworkManager sharedManager] getUserPostsFrom:[self oldPostID] withType:@"old"] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        @strongify(self);
        if (self == nil) return nil;
        self->isBottomRefreshing = NO;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
            
            return nil;
        }

        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[PostModel getPostListFromResponse:serverTask.result]];
        BOOL shouldReloaded = resultArray.count != 0;
        [self.postsArray addObjectsFromArray:resultArray];
        
        if  (shouldReloaded)
        {
            [self.tableView reloadData];
        }
        
        return nil;
    }];    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView {
    // Return the number of sections.
    if ([self.postsArray count] > 0) {
        return [self.postsArray count];
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger) __unused section {

    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsFeedCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NewsFeedCellTableViewCell cellIdentifier] forIndexPath:indexPath];
    
    cell.delegate = self;
    cell.tag = indexPath.section;
    [cell configureCellWithPostInfo:self.postsArray[indexPath.section] withSize:self.view.frame parentTableView:self.tableView];
    
    @weakify(self);
    cell.tagsLabel.hashtagLinkTapHandler = ^(KILabel* __unused label, NSString *string, NSRange __unused range) {
        @strongify(self);
        [self.view endEditing:YES];
        [self performSegueWithIdentifier:kHashTagSegue sender:string];
    };
    
    cell.tagsLabel.userHandleLinkTapHandler  = ^(KILabel* __unused label, NSString __unused *string, NSRange __unused range) {
        @strongify(self);
        [self.view endEditing:YES];
        [self performSegueWithIdentifier:kProfileSegue sender:nil];
    };
    
    return cell;
}

#pragma mark - NYTPhotosViewControllerDelegate

- (UIView *)photosViewController:(NYTPhotosViewController *)__unused photosViewController referenceViewForPhoto:(id<NYTPhoto>)__unused photo {
    
    return self.postView;
}

- (void)reportPostWithID:(NSNumber*) postID {
    [SVProgressHUD show];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    
    [[[QMNetworkManager sharedManager] reportObject:@0 WithID:postID] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
        [SVProgressHUD dismiss];
        
        if (!t.isFaulted) {
             [QMAlert showAlertWithMessage:@"Report sent" actionSuccess:YES inViewController:self];
        } else {
            [QMAlert showAlertWithMessage:t.error.localizedDescription actionSuccess:NO inViewController:self];
        }
        
        return nil;
    }];
}

- (void) deletePostWithID: (NSNumber*) postID
{
    [SVProgressHUD show];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [[[QMNetworkManager sharedManager] deletePostByID: postID] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
        
        [SVProgressHUD dismiss];
        if (!t.isFaulted) {
            [QMAlert showAlertWithMessage:@"Deleted" actionSuccess:YES inViewController:self];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPost" object:nil];
        } else {
            [QMAlert showAlertWithMessage:t.error.localizedDescription actionSuccess:NO inViewController:self];
        }

        return nil;
    }];
}

- (void) restoreBarButtons
{
    [self.view endEditing:YES];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    UIButton *plusButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 14, 18)];
    [plusButton addTarget:self action:@selector(newPostView:) forControlEvents:UIControlEventTouchUpInside];
    [plusButton setBackgroundImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 13, 23)];
    [backButton addTarget:self action:@selector(onBackAction:) forControlEvents:UIControlEventTouchUpInside];
    [backButton setBackgroundImage:[UIImage imageNamed:@"Back"] forState:UIControlStateNormal];

    UIBarButtonItem *plusButtonItem = [[UIBarButtonItem alloc] initWithCustomView:plusButton];
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    [self.navigationItem setRightBarButtonItems:@[plusButtonItem] animated:YES];
    [self.navigationItem setLeftBarButtonItems:@[backButtonItem] animated:YES];
    
    self.navigationItem.title = @"All Posts";
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor],
       NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:21.0]}];
}

- (IBAction) newPostView: (id) __unused sender
{
    [self performSegueWithIdentifier:kNewPostSegue sender:nil];
}

- (void) cancelEdit {
    [self restoreBarButtons];
    
    [self.tableView reloadData];
}
//
//- (void) doneEdit
//{
//    [self restoreBarButtons];
//    
//    NSIndexPath *indexPath = [self.tableView indexPathForCell:self.selectedCell];
//    PostModel* post = self.postsArray[indexPath.section];
//    
//    NSArray* hastagArray = [self.selectedCell.tagsLabel.text componentsSeparatedByString:@"#####"];
//    [SVProgressHUD show];
//    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
//    @weakify(self);
//    [[[QMNetworkManager sharedManager] editPostWithText:self.selectedCell.postText.text hashtags:hastagArray permission:post.permission postID:post.postID] continueWithBlock:^id _Nullable(BFTask *_Nonnull serverTask) {
//        [SVProgressHUD dismiss];
//        
//        @strongify(self);
//        if (serverTask.isFaulted) {
//            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
//            return nil;
//        }
//        
//        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[PostModel getPostListFromResponse:serverTask.result]];
//        self.postsArray = [resultArray mutableCopy];
//
//        [self.tableView reloadData];
//        return nil;
//    }];
//    
//}



#pragma mark - Tap delegate

- (void) didTapActionButton: (NewsFeedCellTableViewCell*) cell onView:(UIView *)actionView
{
    NSInteger section = [self.tableView indexPathForCell:cell].section;
    PostModel* post = (PostModel*)self.postsArray[section];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Reach" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if ([post.author.email isEqualToString:[QMNetworkManager sharedManager].myProfile.email]) {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Delete This Post"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull __unused action) {
                                                              [self deletePostWithID:post.postID];
                                                          }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"Edit This Post"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull __unused action) {
                                                                                                                   self->isPostEdit = YES;
                                                              [self performSegueWithIdentifier:kNewPostSegue sender:post];
                                                              //[self editPost:cell];
                                                              
                                                          }]];
    } else {
        [alertController addAction:[UIAlertAction actionWithTitle:@"Report This Post"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull __unused action) {
                                                              [self reportPostWithID:post.postID];
                                                          }]];
    }
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_CANCEL", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    
    UIPopoverPresentationController *popPresenter = [alertController
                                                     popoverPresentationController];
    popPresenter.sourceView = actionView;
    popPresenter.sourceRect = actionView.bounds;

    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void) didTapPostImage: (NewsFeedCellTableViewCell*) cell {
    NSInteger section = [self.tableView indexPathForCell:cell].section;
    PostModel* post = self.postsArray[section];
    if ([post.video isKindOfClass:[NSNull class]]) {
       [QMImagePreview previewImageWithURL:[cell getPostImageURL] inViewController:self];
    }    
}

- (void) didTapAvatar:(NewsFeedCellTableViewCell *)cell {
    PostModel *post = self.postsArray[cell.tag];
    if(![post.permission boolValue]) {
        return;
    }
    
    [UIView animateWithDuration:0.2 animations:^{
        
        cell.avatarImageView.layer.opacity = 0.6f;
        
    } completion:^(BOOL __unused finished) {
        
        cell.avatarImageView.layer.opacity = 1.0f;
        
        [self performSegueWithIdentifier:kProfileSegue sender:[NSNumber numberWithInteger:cell.tag]];
    }];    
}

- (void) didTapReadMoreButton: (NewsFeedCellTableViewCell*) cell trimmedString:(NSString *)trimmedString
{
    PostModel *post  = self.postsArray[cell.tag];
    NSMutableArray *temp = [self.postsArray mutableCopy];
    post.isExpanded = !post.isExpanded;
    temp[cell.tag] = post;
    self.postsArray = [temp mutableCopy];
    
    NSString* username = [post.permission boolValue] ? post.author.userName : @"Anonymous";
    
    NSString* subString1 = [NSString stringWithFormat:@"%@ %@...Less", username, post.text];
    NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:subString1 attributes:@{NSFontAttributeName :[UIFont fontWithName:@"AvenirNext-Regular" size:14.0],                                                                                                                                  NSForegroundColorAttributeName : [UIColor blackColor]}];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Bold" size:14.0] range:NSMakeRange(0, username.length)];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(subString1.length-7, 7)];
    
    [attributedString addAttribute:NSUnderlineStyleAttributeName value:NSUnderlineColorAttributeName range:NSMakeRange(subString1.length-8, 7)];
    
    NSMutableAttributedString* attributedTrimmedString = [[NSMutableAttributedString alloc] initWithString:trimmedString attributes:@{NSFontAttributeName :[UIFont fontWithName:@"AvenirNext-Regular" size:14.0],                                                                                                                                  NSForegroundColorAttributeName : [UIColor blackColor]}];
    [attributedTrimmedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Bold" size:14.0] range:NSMakeRange(0, username.length)];
    [attributedTrimmedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(121+ username.length, 11)];
    [attributedTrimmedString addAttribute:NSUnderlineStyleAttributeName value:NSUnderlineColorAttributeName range:NSMakeRange(121+ username.length, 11)];

    cell.postText.attributedText = post.isExpanded ? attributedString : attributedTrimmedString;;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void) didTapLikeButton:(NewsFeedCellTableViewCell*) __unused cell
{
    if  (isLikeTapped) return;
    isLikeTapped = YES;
    
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    PostModel *post = self.postsArray[indexPath.section];

    if (![post.isLiked isEqual:@(1)]) {

     
        [[[QMNetworkManager sharedManager] sendLikeWithPostID:post.postID] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
            self->isLikeTapped = NO;
            
            if (serverTask.isFaulted) {
                [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
                [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
                return nil;
            }
            
            post.isLiked = @1;
            post.likesCount = @(post.likesCount.intValue + 1);
            NSMutableArray *temp = [self.postsArray mutableCopy];
            temp[indexPath.section] = post;
            self.postsArray = [temp mutableCopy];
            
//            [cell updateLike:post];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LikePost" object:@{@"post":post, @"cell":cell, @"source":@"AllPosts"}];
            
            return nil;
        }];
    } else { 
        [[[QMNetworkManager sharedManager] removeLikeWithPostID:post.postID] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
            self->isLikeTapped = NO;
            if (serverTask.isFaulted) {
                [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
                [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
                return nil;
            }
            
            post.isLiked = @0;
            post.likesCount = @(post.likesCount.intValue - 1);
            NSMutableArray *temp = [self.postsArray mutableCopy];
            temp[indexPath.section] = post;
            self.postsArray = [temp mutableCopy];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"LikePost" object:@{@"post":post, @"cell":cell, @"source":@"AllPosts"}];
            
            return nil;
        }];
    }
}

- (void) didTapCommentButton:(NewsFeedCellTableViewCell*) cell
{
    [self.view endEditing:YES];
    [self performSegueWithIdentifier:kCommentSegue sender:[NSNumber numberWithInteger:cell.tag]];
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id)sender {
    [self.view endEditing:YES];
    
    if ([segue.identifier isEqualToString:kProfileSegue]) {
        NSInteger tagNumber = [sender integerValue];
        PostModel *post = self.postsArray[tagNumber];
        UINavigationController* navigationController = segue.destinationViewController;
        UserProfileViewController* profileViewController = navigationController.viewControllers.firstObject;
        profileViewController.user = post.author;
    }
    
    if ([segue.identifier isEqualToString:kCommentSegue]) {
        NSInteger tagNumber = [sender integerValue];
        UINavigationController* navigationController = segue.destinationViewController;
        CommentViewController* commentViewController = navigationController.viewControllers.firstObject;
        commentViewController.post = self.postsArray[tagNumber];
    }
    
    if ([segue.identifier isEqualToString:kHashTagSegue]) {
        UINavigationController* navigationController = segue.destinationViewController;
        AllPostViewController* allPostViewController = navigationController.viewControllers.firstObject;
        allPostViewController.title = sender;
        allPostViewController.hashtag = sender;
    }
    
    if ([segue.identifier isEqualToString:kNewPostSegue])
    {
        UINavigationController* navigationController = segue.destinationViewController;
        NewPostController* newPostController = navigationController.viewControllers.firstObject;
        if (isPostEdit) {
            newPostController.post = sender;
        }
    }
}

#pragma mark - ScrollView Delegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    
    if (offsetY > contentHeight - scrollView.frame.size.height && !isFirstLoading) {
        
        [self updatePosts];
    }
}

#pragma mark - Empty table
- (UIImage *)imageForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return [UIImage imageNamed:@"logo-splash"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    NSString *text = @"There is no new post yet";
    
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
