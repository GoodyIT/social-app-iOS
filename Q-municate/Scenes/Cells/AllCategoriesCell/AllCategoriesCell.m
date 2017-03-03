//
//  AllGroupsCell.m
//  reach-ios
//
//  Created by Admin on 2016-12-27.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "AllCategoriesCell.h"

@interface AllCategoriesCell()
@property (weak, nonatomic) IBOutlet UILabel *categoryName;
@property (weak, nonatomic) IBOutlet UILabel *numberOfGroups;

@end

@implementation AllCategoriesCell

+ (void)registerForReuseInTableView:(UITableView *)tableView {
    
    NSString *nibName = NSStringFromClass([self class]);
    UINib *nib = [UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]];
    NSParameterAssert(nib);
    
    NSString *cellIdentifier = [self cellIdentifier];
    NSParameterAssert(cellIdentifier);
    
    [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
}

+ (NSString *)cellIdentifier {
    
    return NSStringFromClass([self class]);
}

+ (CGFloat)height {
    return 0;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self sizeToFit];
    [self updateConstraintsIfNeeded];
    
    self.selectionStyle = UITableViewCellSelectionStyleGray;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

- (void)configureCellWithCategoryInfo: (CategoryModel*) categoryModel
{
    self.categoryName.text = categoryModel.name;
    self.numberOfGroups.text = [NSString stringWithFormat:@"%@ Groups", [categoryModel.countOfGroups stringValue]];
}

@end
