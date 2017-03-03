//
//  CommentCell.h
//  reach-ios
//
//  Created by Admin on 2016-12-17.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TopicReplyCellDelegate;

@interface TopicReplyCell : UITableViewCell
@property (weak, nonatomic) id<TopicReplyCellDelegate> delegate;
@property (strong, nonatomic) KILabel *userComment;

+ (void)registerForReuseInTableView:(UITableView *)tableView;
+ (NSString *)cellIdentifier;
+ (CGFloat)height;

- (void)configureCellWithTopicInfo: (CommentModel*) commentModel;

@end

@protocol TopicReplyCellDelegate <NSObject>

- (void) didTapAvatar: (TopicReplyCell*) cell;

- (void) didTapReply: (TopicReplyCell*) cell;

- (void) didTapDownVote: (TopicReplyCell*) cell;

- (void) didTapUpVote: (TopicReplyCell*) cell;
@end
