//
//  CommentCell.h
//  reach-ios
//
//  Created by Admin on 2016-12-17.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CommentCellDelegate;

@interface CommentCell : UITableViewCell
@property (weak, nonatomic) id<CommentCellDelegate> delegate;
@property (strong, nonatomic) KILabel *userComment;

+ (void)registerForReuseInTableView:(UITableView *)tableView;
+ (NSString *)cellIdentifier;
+ (CGFloat)height;

- (void)configureCellWithPostInfo: (CommentModel*) commentModel;

@end

@protocol CommentCellDelegate <NSObject>

- (void) didTapAvatar: (CommentCell*) cell;

- (void) didTapReply: (CommentCell*) cell;

- (void) didTapDownVote: (CommentCell*) cell;

- (void) didTapUpVote: (CommentCell*) cell;
@end
