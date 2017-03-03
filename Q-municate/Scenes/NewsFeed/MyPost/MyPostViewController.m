//
//  MyPostViewController.m
//  reach-ios
//
//  Created by Admin on 2016-12-21.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "MyPostViewController.h"
#import "SelfSizingWaterfallCollectionViewLayout.h"
#import "MyPostCell.h"
#import "MyPostDetailViewController.h"

@interface MyPostViewController ()<UIScrollViewDelegate, SelfSizingWaterfallCollectionViewLayoutDelegate, UICollectionViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
{
    NSInteger   selectedIndex;
    __block BOOL        shouldDisplay;
    __block BOOL isBottomRefreshing;
    __block BOOL isFirstLoading;
}

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *myPostsArray;
@property (strong, nonatomic) UserModel * currentUser;
@property (strong, nonatomic) NSNumber *currentOffset;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) UIRefreshControl *bottomRefresh;


@end

@implementation MyPostViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTransion:) name:kEndTransition object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beginTransion:) name:kBeginTransition object:nil];
}

- (void) prepareUI
{
//    self.refreshControl = [[UIRefreshControl alloc] init];
//    self.refreshControl.backgroundColor = [UIColor clearColor];
//    self.refreshControl.tintColor = [UIColor blackColor];
//    [self.refreshControl addTarget:self
//                            action:@selector(getMyNewPosts)
//                  forControlEvents:UIControlEventValueChanged];
//    [self.collectionView addSubview:self.refreshControl];
    self.collectionView.alwaysBounceVertical = YES;
  
    self.collectionView.emptyDataSetSource = self;
    self.collectionView.emptyDataSetDelegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if  (self.myPostsArray == nil)
    {
        self.myPostsArray = [NSMutableArray new];
    }
    
    isFirstLoading = YES;
    @weakify(self);
    [self addMyNewPostWithCompletion:^{
        @strongify(self);
        [self prepareUI];
    }];
}

- (NSNumber *)currentOffset {
    if (_currentOffset == nil) {
        _currentOffset = [[NSNumber alloc] initWithInteger:0];
    }
    
    return _currentOffset;
}

- (void) viewWillDisappear:(BOOL)animated {
    
    NSArray * visibleCells = [self.collectionView visibleCells];
    if (visibleCells) {
        
        for (MyPostCell * cell in visibleCells) {
            
            [cell cancelOperation];
        }
    }
    
    [super viewWillDisappear:animated];
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

- (void) getMyNewPosts
{
    if  (isBottomRefreshing)
    {
        return;
    }
    isBottomRefreshing = YES;
    [self updateMyPostsWithCompletion:nil];
}
    
- (void) addMyNewPostWithCompletion: (void (^)(void)) completion
{
    self.currentOffset = nil;
    
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] getMyPostsWithOffset:[self currentOffset]] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        
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
        self.currentOffset = @([offsetError.localizedDescription integerValue]);
        NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[PostModel getPostListFromResponse:serverTask.result]];
        self.myPostsArray  = resultArray;
        
        if (completion != nil) {
            completion();
        }
        
        [self.collectionView reloadData];
        
        self->isFirstLoading = NO;
        return nil;
    }];
}

- (void) updateMyPostsWithCompletion: (void (^)(void)) completion
{
    @weakify(self);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[[QMNetworkManager sharedManager] getMyPostsWithOffset:[self currentOffset]] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
       
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
            self.currentOffset = @([offsetError.localizedDescription integerValue]);
            NSMutableArray *resultArray = [[NSMutableArray alloc] initWithArray:[PostModel getPostListFromResponse:serverTask.result]];
            [self.myPostsArray addObjectsFromArray:resultArray];

            if (completion != nil) {
                completion();
            }

        [self.collectionView reloadData];
        
        self->isFirstLoading = NO;
        return nil;
    }];
}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self.collectionView reloadData];
}


#pragma mark - ScrollView Delegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetY = scrollView.contentOffset.y;
    CGFloat contentHeight = scrollView.contentSize.height;
    
    if (offsetY > contentHeight - scrollView.frame.size.height && !isFirstLoading) {
        
        [self getMyNewPosts];
    }
}

#pragma mark UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *) __unused collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *) __unused collectionView numberOfItemsInSection:(NSInteger) __unused section
{
    return self.myPostsArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MyPostCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MyPostCell" forIndexPath:indexPath];
    PostModel* post = self.myPostsArray[indexPath.item];
    [cell configureCell:post];
    return cell;
}

- (void)collectionView:(UICollectionView *) __unused collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PostModel* post = self.myPostsArray[indexPath.item];
    [self performSegueWithIdentifier:kNewsFeedSegue sender:post];
}

#pragma mark SelfSizingWaterfallCollectionViewLayoutDelegate

- (NSUInteger)collectionView:(UICollectionView *) __unused collectionView layout:(UICollectionViewLayout *) __unused collectionViewLayout numberOfColumnsInSection:(NSUInteger) __unused section
{
    NSUInteger compactColumns = 2;
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        return compactColumns + 1;
    }
    
    return compactColumns;
}

- (CGFloat)collectionView:(UICollectionView *) __unused collectionView layout:(UICollectionViewLayout *) __unused collectionViewLayout estimatedHeightForItemAtIndexPath:(NSIndexPath *) __unused indexPath
{
    return 250.0f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *) __unused collectionViewLayout referenceSizeForHeaderInSection:(NSUInteger) __unused section
{
    return CGSizeMake(CGRectGetWidth(collectionView.frame), 0.0f);
}

- (UIEdgeInsets)collectionView:(UICollectionView *) __unused collectionView layout:(UICollectionViewLayout *) __unused collectionViewLayout insetForSectionAtIndex:(NSInteger) __unused section
{
    return UIEdgeInsetsMake(16.0f, 16.0f, 16.0f, 16.0f);
}

- (CGFloat)collectionView:(UICollectionView *) __unused collectionView layout:(UICollectionViewLayout *) __unused collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger) __unused section
{
    return 8.0f;
}

- (CGFloat)collectionView:(UICollectionView *) __unused collectionView layout:(UICollectionViewLayout *) __unused collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger) __unused section
{
    return 8.0f;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)__unused scrollView {
    
    [self.view endEditing:YES];
}

#pragma mark - Empty table

- (UIImage *)imageForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    return [UIImage imageNamed:@"logo-splash"];
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *) __unused scrollView
{
    NSString *text = @"There Is No Post yet.";
    
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:kNewsFeedSegue]) {
        MyPostDetailViewController* mypostDetailViewController = segue.destinationViewController;
        PostModel* post = (PostModel*) sender;
        mypostDetailViewController.postsArray = [[NSMutableArray alloc] initWithObjects:post, nil];
    }
}

@end
