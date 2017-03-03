//
//  FirstCommentCell.h
//  reach-ios
//
//  Created by Admin on 2016-12-22.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FirstCellDelegate;

@interface FirstCommentCell : UITableViewCell
@property (weak, nonatomic) id<FirstCellDelegate> delegate;


+ (void)registerForReuseInTableView:(UITableView *)tableView;
+ (NSString *)cellIdentifier;
+ (CGFloat)height;

- (void) configureCell: (PostModel*) post;

@end

@protocol FirstCellDelegate <NSObject>
- (void) didTapAvatarFirst: (FirstCommentCell*) cell;
@end
