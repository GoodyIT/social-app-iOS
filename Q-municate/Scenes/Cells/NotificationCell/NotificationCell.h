//
//  NotificationCell.h
//  reach-ios
//
//  Created by Admin on 2016-12-26.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NotificationCell;

@protocol NotificationCellDelegate <NSObject>

- (void) didTapAvatar: (NotificationCell*) cell;

@end

@interface NotificationCell : UITableViewCell

@property (weak, nonatomic) id<NotificationCellDelegate> delegate;
@property (strong, nonatomic) KILabel *notificationText;
@property (weak, nonatomic) id <SDWebImageOperation> imageOperation;

+ (void)registerForReuseInTableView:(UITableView *)tableView;
+ (NSString *)cellIdentifier;
+ (CGFloat)height;

- (void)configureCellWithNotificationInfo: (NotificationModel*) notificationModel shouldUpdateCell:(BOOL)shouldUpdateCell;

- (void) configureCellWithGroupNotification: (GroupNotificationModel*) groupNotificationModel shouldUpdateCell:(BOOL)shouldUpdateCell;

- (void) cancelOperation;

@end
