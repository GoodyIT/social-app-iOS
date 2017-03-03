//
//  NewsFeedCellTableViewCell.h
//  reach-ios
//
//  Created by Admin on 2016-12-07.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QMImageView.h"

@protocol AllPostViewDelegate;

@interface NewsFeedCellTableViewCell : UITableViewCell
+ (void)registerForReuseInTableView:(UITableView *)tableView;
+ (NSString *)cellIdentifier;
+ (CGFloat)height;

- (void)configureCellWithPostInfo:(PostModel *)postInfo withSize:(CGRect)size parentTableView:(UITableView*) tableView;

- (void) editCell: (PostModel *)postInfo;

@property (weak, nonatomic) id<AllPostViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *likeLabel;
@property (weak, nonatomic) IBOutlet UITextView *postText;
@property (weak, nonatomic) IBOutlet QMImageView *avatarImageView;
@property (strong, nonatomic) KILabel *tagsLabel;


- (NSURL*) getPostImageURL;

- (void) stopVideo;

- (void) playVideo;

- (void) updateLike: (PostModel*) postInfo;

@end

@protocol AllPostViewDelegate <NSObject>

- (void) didTapPostImage: (NewsFeedCellTableViewCell*) cell;

- (void) didTapAvatar: (NewsFeedCellTableViewCell*) cell;

- (void) didTapLikeButton:(NewsFeedCellTableViewCell*) cell;

- (void) didTapCommentButton:(NewsFeedCellTableViewCell*) cell;

- (void) didTapReadMoreButton: (NewsFeedCellTableViewCell*) sender trimmedString:(NSString*) trimmedString;

@optional

- (void) didTapActionButton: (NewsFeedCellTableViewCell*) sender onView:(UIView*)actionView;

@end
