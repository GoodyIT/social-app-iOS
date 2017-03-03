//
//  AllGroupsCell.h
//  reach-ios
//
//  Created by Admin on 2016-12-27.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AllCategoriesCell : UITableViewCell

+ (void)registerForReuseInTableView:(UITableView *)tableView;
+ (NSString *)cellIdentifier;
+ (CGFloat)height;


- (void)configureCellWithCategoryInfo: (CategoryModel*) categoryModel;

@end

