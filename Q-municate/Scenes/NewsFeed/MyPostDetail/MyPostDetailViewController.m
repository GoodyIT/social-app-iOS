//
//  MyPostDetailViewController.m
//  reach-ios
//
//  Created by Admin on 2016-12-23.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "MyPostDetailViewController.h"
#import "NewsFeedCellTableViewCell.h"
#import "UserProfileViewController.h"
#import "CommentViewController.h"
#import "AllPostViewController.h"
#import "NewPostController.h"

#import <NYTPhotoViewer/NYTPhotosViewController.h>
#import "QMImagePreview.h"
#import "QMAlert.h"

@interface MyPostDetailViewController ()<AllPostViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NYTPhotosViewControllerDelegate, UIActionSheetDelegate>
{
    __block BOOL isRefreshing;
    __block BOOL isLikeTapped;
    BOOL isPostEdit;
}

@property (strong, nonatomic) RKNotificationHub* hub ;
@property (strong, nonatomic) UIImageView *postView;

@property (strong, nonatomic) NewsFeedCellTableViewCell* selectedCell;

@end

@implementation MyPostDetailViewController
@synthesize postsArray;
@synthesize postID;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareUI];
    [self registerNibs];
    if (postID != nil){
        [self getPost];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostFrom:) name:@"NewPost" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostFromLike:) name:@"LikePost" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}

- (void) updatePost: (NSNotification*) notification
{
    postID = notification.object;
    [self getPost];
}

- (void) updatePostFromLike: (NSNotification*) notification
{
    PostModel *post = [notification.object objectForKey:@"post"];
    NSUInteger index = 0;
    for (PostModel* _post in self.postsArray) {
        if ([_post.postID integerValue] == [post.postID integerValue]) {
            [self.postsArray replaceObjectAtIndex:index withObject:post];
            break;
        }
        index++;
    }
   
    [self.tableView reloadData];
}

- (void) updatePostFrom: (NSNotification*) notification
{
    PostModel* post = [notification.object objectForKey:@"post"];
    if (post != nil) {
        self.postsArray = [[NSMutableArray alloc] initWithObjects:post, nil];
        postID = post.postID;
        [self.tableView reloadData];
    }
}

- (void) getPost
{
    @weakify(self)
    [[[QMNetworkManager sharedManager] getPostByID:postID] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
        @strongify(self)
        if (serverTask.isFaulted) {
            [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
            return nil;
        }
        PostModel* post = [PostModel getPostInfoFromResponse:[serverTask.result valueForKey:@"post"]];
        self.postsArray = [[NSMutableArray alloc] initWithObjects:post, nil];
        
        [self.tableView reloadData];
        return  nil;
    }];
}

- (void) prepareUI {
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor whiteColor],
       NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:21.0]}];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 14, 23)];
    [backButton setBackgroundImage:[UIImage imageNamed:@"Back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(onBackAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    
    [self.navigationItem setLeftBarButtonItems:@[backButtonItem] animated:YES];
    
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

- (IBAction)onBackAction:(id) __unused sender {
    [self.view endEditing:YES];
     [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView {
    
    return 1;
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
        //  string = [string stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSLog(@"\n\nTableView\n\n");
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

- (void) deletePostWithID: (NSNumber*) _postID
{
    [SVProgressHUD show];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear
     ];
     [[[QMNetworkManager sharedManager] deletePostByID: _postID] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
        
        [SVProgressHUD dismiss];
        if (!t.isFaulted) {
            [QMAlert showAlertWithMessage:@"Deleted" actionSuccess:YES inViewController:self withCompletion:^{
                [self.navigationController popViewControllerAnimated:YES];
            }];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPost" object:nil];
            
        } else {
            [QMAlert showAlertWithMessage:t.error.localizedDescription actionSuccess:NO inViewController:self];
        }
        
        return nil;
    }];
}
//
//- (void) editPost: (NewsFeedCellTableViewCell*) cell {
//    PostModel *post = self.postsArray[cell.tag];
//    [cell editCell:post];
//    self.selectedCell = cell;
//    
//    //    [self.tableView beginUpdates];
//    //    [self.tableView endUpdates];
//    
//    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
//    
//    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
//    
//    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelEdit)];
//    [self.navigationItem setLeftBarButtonItem:cancelButton animated:YES];
//    
//    [cancelButton setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],   NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:19.0]
//                                           } forState:UIControlStateNormal];
//    
//    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneEdit)];
//    [self.navigationItem setRightBarButtonItem:doneButton animated:YES];
//    
//    [doneButton setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor],   NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:19.0]
//                                         } forState:UIControlStateNormal];
//    
//    self.navigationItem.title = @"Edit Post";
//    [self.navigationController.navigationBar setTitleTextAttributes:
//     @{NSForegroundColorAttributeName:[UIColor whiteColor],
//       NSFontAttributeName:[UIFont fontWithName:@"AvenirNext-DemiBold" size:21.0]}];
//}

- (void) restoreBarButtons
{
    [self.view endEditing:YES];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    UIButton *plusButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 14, 18)];
    [plusButton addTarget:self action:@selector(newPostView:) forControlEvents:UIControlEventTouchUpInside];
    [plusButton setBackgroundImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 14, 23)];
    [backButton setBackgroundImage:[UIImage imageNamed:@"Back"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(onBackAction:) forControlEvents:UIControlEventTouchUpInside];
    
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
//    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
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
//}


- (void)reportPostWithID:(NSNumber*) _postID {
    [SVProgressHUD show];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    
    [[[QMNetworkManager sharedManager] reportObject:@0 WithID:_postID] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
        [SVProgressHUD dismiss];
        
        if (!t.isFaulted) {
            [QMAlert showAlertWithMessage:@"Report sent" actionSuccess:YES inViewController:self];
        } else {
            [QMAlert showAlertWithMessage:t.error.localizedDescription actionSuccess:NO inViewController:self];
        }
        
        return nil;
    }];
}


#pragma mark - Tap delegate

- (void) didTapActionButton: (NewsFeedCellTableViewCell*) cell onView:(UIView *)__unused actionView
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
    if ([trimmedString isEqualToString:@""]) {
        return;
    }
    
    PostModel *post  = self.postsArray[cell.tag];
    NSMutableArray *temp = [self.postsArray mutableCopy];
    post.isExpanded = !post.isExpanded;
    temp[cell.tag] = post;
    self.postsArray = [temp copy];
    
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
    
    //  cell.postText.text = post.isExpanded ? post.text : trimmedString;
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
        post.isLiked = @1;
        post.likesCount = @(post.likesCount.intValue + 1);
        
        NSMutableArray *temp = [self.postsArray mutableCopy];
        temp[indexPath.section] = post;
        self.postsArray = [temp copy];
        
        [cell updateLike:post];
        
        [[[QMNetworkManager sharedManager] sendLikeWithPostID:post.postID] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
            if (serverTask.isFaulted) {
                [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
                [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
                return nil;
            }
            
            self->isLikeTapped = NO;
            return nil;
        }];
    } else {
        post.isLiked = @0;
        post.likesCount = @(post.likesCount.intValue - 1);
        NSMutableArray *temp = [self.postsArray mutableCopy];
        temp[indexPath.section] = post;
        self.postsArray = [temp copy];
        
        [cell updateLike:post];
        
        [[[QMNetworkManager sharedManager] removeLikeWithPostID:post.postID] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
            if (serverTask.isFaulted) {
                [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
                [((QMAppDelegate *)[UIApplication sharedApplication].delegate).timer invalidate];
                return nil;
            }
            
            self->isLikeTapped = NO;
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


@end
