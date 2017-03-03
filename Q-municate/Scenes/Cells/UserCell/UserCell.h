//
//  UserCell.h
//  reach-ios
//
//  Created by Admin on 2017-01-02.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UserCellDelegate;

@interface UserCell : UITableViewCell

@property (weak, nonatomic) id<UserCellDelegate> delegate;

+ (void)registerForReuseInTableView:(UITableView *)tableView;
+ (NSString *)cellIdentifier;
+ (CGFloat)height;

- (void)configureCellWithUserInfo: (UserModel*) userModel;

@end

@protocol UserCellDelegate <NSObject>

- (void) didTapAvatar: (UserCell*) cell;

@end
