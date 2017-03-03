//
//  CircleCell.m
//  reach-ios
//
//  Created by Admin on 2016-12-27.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "GroupCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <QMImageView.h>
#import "QMHelpers.h"
#import <QuartzCore/QuartzCore.h>

@interface GroupCell() <QMImageViewDelegate>
{
    BOOL isShown;
}
@property (weak, nonatomic) IBOutlet QMImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UILabel *groupBio;
@property (weak, nonatomic) IBOutlet UIView *sideView;
@property (weak, nonatomic) IBOutlet UILabel *groupTitle;
@property (weak, nonatomic) IBOutlet UILabel *categoryOfGroup;
@property (weak, nonatomic) IBOutlet UIButton *joinBtn;
@property (weak, nonatomic) IBOutlet UILabel *numberOfPosts;
@property (weak, nonatomic) IBOutlet UILabel *numberOfUsers;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightOfBottomview;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sideViewContraint;
@property (weak, nonatomic) IBOutlet UIButton *sideViewActionBtn;

@end

@implementation GroupCell

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
    
    isShown = NO;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self sizeToFit];
    [self updateConstraintsIfNeeded];
    
    self.avatarImageView.userInteractionEnabled = YES;
    self.avatarImageView.imageViewType = QMImageViewTypeCircle;
    
    [self.backgroundImage setClipsToBounds:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)configureCellWithGroupInfo: (GroupModel*) groupModel
{
    if ([groupModel.permission boolValue]) {
        [self.avatarImageView setImageWithURL:[NSURL URLWithString:groupModel.owner.avatarURL]
                              placeholder:[UIImage imageNamed:@"default"]
                                  options:SDWebImageLowPriority
                                 progress:nil
                           completedBlock:nil];
        self.avatarImageView.delegate = self;
    } else {
        self.avatarImageView.image =[UIImage imageNamed:@"default-avatar"];
    }
    
    [self.backgroundImage sd_setImageWithURL:[NSURL URLWithString:groupModel.imageURL]
                            placeholderImage:[UIImage imageNamed:@"profile_back"]];
    
    if  ([groupModel.owner.email isEqualToString:[QBSession currentSession].currentUser.email])
    {
        self.joinBtn.enabled = NO;
    }
    
    self.groupBio.text = groupModel.groupDescription;
    self.heightOfBottomview.constant = getLabelHeight(self.groupBio);
    self.groupTitle.text = groupModel.name;
    self.categoryOfGroup.text = groupModel.category.name;
    self.numberOfPosts.text = [NSString stringWithFormat:@"%ld", (unsigned long)groupModel.topics.count ] ;
    self.numberOfUsers.text = [groupModel.memberCount stringValue];
    if ([groupModel.joined boolValue]) {
        [self.joinBtn setTitle:@"Joined" forState:UIControlStateNormal];
    } else
    {
        [self.joinBtn setTitle:@"Join" forState:UIControlStateNormal];
    }
    
    [self layoutIfNeeded];
    [self setNeedsLayout];
}

- (void) updateJoinBtn: (GroupModel*) groupModel
{
    if ([groupModel.joined boolValue]) {
        [self.joinBtn setTitle:@"Joined" forState:UIControlStateNormal];
    } else {
        [self.joinBtn setTitle:@"Join" forState:UIControlStateNormal];
    }
    
    self.numberOfPosts.text = [NSString stringWithFormat:@"%ld", (unsigned long)groupModel.topics.count ] ;
    self.numberOfUsers.text = [groupModel.memberCount stringValue];
}

#pragma mark - QMImageViewDelegate

- (void)imageViewDidTap:(QMImageView *) __unused imageView {
    [self.delegate didTapAvatar:self];
}

#pragma mark - delegate

- (IBAction)showHideAction:(id)__unused sender {
    [self.delegate didTapShowHide:self];
    if  (isShown)
    {
        [UIView animateWithDuration:.5 delay:.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.sideViewContraint.constant = -110;
            [self.sideViewActionBtn setBackgroundImage:[UIImage imageNamed:@"back_1"] forState:UIControlStateNormal];
        }completion:^(BOOL __unused finished) {
            self->isShown = NO;
        }];
       
    } else
    {
        [UIView animateWithDuration:.5 delay:.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            self.sideViewContraint.constant = 0;
            [self.sideViewActionBtn setBackgroundImage:[UIImage imageNamed:@"forward"] forState:UIControlStateNormal];
            
        } completion:^(BOOL __unused finished) {
            self->isShown = YES;
        }];
    }
    
}

- (IBAction)joinClicked:(id)__unused sender {
    [self.delegate didTapJoinBtn:self];
}

@end
