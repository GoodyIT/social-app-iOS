//
//  QMTableViewCell.h
//  Q-municate
//
//  Created by Andrey Ivanov on 23.03.15.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QMImageView.h>

@interface QMTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet QMImageView *avatarImage;

+ (void)registerForReuseInTableView:(UITableView *)tableView;
+ (NSString *)cellIdentifier;
+ (CGFloat)height;

- (void)setTitle:(NSString *)title
   placeholderID:(NSUInteger)placeholderID
       avatarUrl:(NSString *)avatarUrl;

- (void)setTitle:(NSString *)title;

- (void)setBody:(NSString *)body;

@end
