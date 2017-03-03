//
//  JournalTableViewCell.m
//  Reach-iOS
//
//  Created by VICTOR on 9/12/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "JournalTableViewCell.h"

@implementation JournalTableViewCell
@synthesize timeLabel;
@synthesize titleLabel;

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
