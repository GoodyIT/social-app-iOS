//
//  GroupDetailCell.h
//  reach-ios
//
//  Created by Admin on 2016-12-28.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GroupDetailCell;

@protocol GroupDetailCellDelegate <NSObject>

- (void) didTapAvatar: (GroupDetailCell*) cell;

@end

@interface GroupDetailCell : UITableViewCell

@property (weak, nonatomic) id<GroupDetailCellDelegate> delegate;

+ (void)registerForReuseInTableView:(UITableView *)tableView;
+ (NSString *)cellIdentifier;
+ (CGFloat)height;

- (void)configureCellWithGroupDetailInfo: (TopicModel*) topicModel;

@end
