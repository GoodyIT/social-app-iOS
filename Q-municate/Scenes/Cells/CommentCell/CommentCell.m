//
//  CommentCell.m
//  reach-ios
//
//  Created by Admin on 2016-12-17.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "CommentCell.h"
#import <QMImageView.h>
#import "QMHelpers.h"

@interface CommentCell() <QMImageViewDelegate>
@property (weak, nonatomic) IBOutlet QMImageView *userAvatarImage;
@property (weak, nonatomic) IBOutlet UILabel *username;

@property (weak, nonatomic) IBOutlet UILabel *commentTime;
@property (weak, nonatomic) IBOutlet UILabel *numberOfUpVoted;
@property (weak, nonatomic) IBOutlet UIView *commentView;

@end

@implementation CommentCell

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
     self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [self sizeToFit];
    [self updateConstraintsIfNeeded];
    
    self.userAvatarImage.userInteractionEnabled = YES;
    self.userAvatarImage.imageViewType = QMImageViewTypeCircle;
    
    _userComment = [[KILabel alloc] init];
    self.userComment.numberOfLines = 0;
    self.userComment.font = [UIFont fontWithName:@"AvenirNext-Regular" size:18.0];
    self.userComment.tintColor = [UIColor babyBule];
    [self.commentView addSubview:self.userComment];
    [self.commentView bringSubviewToFront:self.userComment];
    [self.userComment mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.commentView.mas_top); //with is an optional semantic filler
        make.left.equalTo(@16);
        make.bottom.equalTo(self.commentView.mas_bottom);
        make.right.equalTo(self.commentTime.mas_right);
    }];
}
- (IBAction)upVoteTapped:(id) __unused sender {
    [self.delegate didTapUpVote:self];
}

- (IBAction)downVoteTapped:(id) __unused sender {
    [self.delegate didTapDownVote:self];
}

#pragma mark - QMImageViewDelegate

- (void)imageViewDidTap:(QMImageView *) __unused imageView {
    [self.delegate didTapAvatar:self];
}

- (IBAction)replyTapped:(id) __unused sender {
    [self.delegate didTapReply:self];
}

- (void)configureCellWithPostInfo: (CommentModel*) commentModel
{
    [self.userAvatarImage setImageWithURL:[NSURL URLWithString:commentModel.author.avatarURL] placeholder:[UIImage imageNamed:@"default"] options:SDWebImageHighPriority progress:nil completedBlock:nil];
    
    self.userAvatarImage.delegate = self;
    
    self.username.text = commentModel.author.userName;
    self.commentTime.text = getTimeLog(commentModel.date);
    self.userComment.text = commentModel.text;
    if ([commentModel.isUpvoted boolValue]) {
        self.numberOfUpVoted.text = @"1";
    } else if ([commentModel.isDownvoted boolValue]) {
        self.numberOfUpVoted.text = @"-1";
    } else {
        self.numberOfUpVoted.text = @"0";
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
