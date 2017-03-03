//
//  UserCell.m
//  reach-ios
//
//  Created by Admin on 2017-01-02.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import "UserCell.h"
#import <QMImageView.h>
#import "QMHelpers.h"

@interface UserCell() <QMImageViewDelegate>
@property (weak, nonatomic) IBOutlet QMImageView *userAvatarImage;
@property (weak, nonatomic) IBOutlet UILabel *username;

@end;

@implementation UserCell
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
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    
    [self sizeToFit];
    [self updateConstraintsIfNeeded];
    
    self.userAvatarImage.userInteractionEnabled = YES;
    self.userAvatarImage.imageViewType = QMImageViewTypeCircle;
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureCellWithUserInfo: (UserModel*) userModel
{
    [self.userAvatarImage setImageWithURL:[NSURL URLWithString:userModel.avatarURL] placeholder:[UIImage imageNamed:@"default"] options:SDWebImageHighPriority progress:nil completedBlock:nil];
    
    self.userAvatarImage.delegate = self;
    
    self.username.text = userModel.userName;
}

#pragma mark - QMImageViewDelegate

- (void)imageViewDidTap:(QMImageView *) __unused imageView {
    [self.delegate didTapAvatar:self];
}

@end
