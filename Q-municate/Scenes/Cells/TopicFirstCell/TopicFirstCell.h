//
//  CommentCell.h
//  reach-ios
//
//  Created by Admin on 2016-12-17.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TopicFirstCellDelegate;

@interface TopicFirstCell : UITableViewCell
@property (weak, nonatomic) id<TopicFirstCellDelegate> delegate;
@property (strong, nonatomic) KILabel *userComment;

+ (void)registerForReuseInTableView:(UITableView *)tableView;
+ (NSString *)cellIdentifier;
+ (CGFloat)height;

- (void)configureCell: (TopicModel*) topicModel;

@end

@protocol TopicFirstCellDelegate <NSObject>

- (void) didTapAvatar: (TopicFirstCell*) cell;

@end
