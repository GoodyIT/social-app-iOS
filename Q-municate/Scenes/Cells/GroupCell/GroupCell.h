//
//  CircleCell.h
//  reach-ios
//
//  Created by Admin on 2016-12-27.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GroupCell;

@protocol GroupCellDelegate <NSObject>

- (void) didTapAvatar: (GroupCell*) cell;

- (void) didTapJoinBtn: (GroupCell*) cell;

@optional
- (void) didTapShowHide: (GroupCell*) cell;

@end

@interface GroupCell : UITableViewCell

@property (weak, nonatomic) id<GroupCellDelegate> delegate;

+ (void)registerForReuseInTableView:(UITableView *)tableView;
+ (NSString *)cellIdentifier;
+ (CGFloat)height;

- (void)configureCellWithGroupInfo: (GroupModel*) groupModel;

- (void) updateJoinBtn: (GroupModel*) groupModel;

@end
