//
//  JournalTableViewCell.h
//  Reach-iOS
//
//  Created by VICTOR on 9/12/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JournalTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
