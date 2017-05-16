//
//  GroupDetailCell.m
//  reach-ios
//
//  Created by Admin on 2016-12-28.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "GroupDetailCell.h"
#import <QMImageView.h>
#import "QMHelpers.h"

@interface GroupDetailCell()<QMImageViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *usersTopicContent;
@property (weak, nonatomic) IBOutlet QMImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *userTopic;
@property (weak, nonatomic) IBOutlet UILabel *numberOfReplies;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UIImageView *numberOfRepliesImageView;

@end

@implementation GroupDetailCell

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
    [self layoutIfNeeded];
    
    self.avatarImageView.userInteractionEnabled = YES;
    self.avatarImageView.imageViewType = QMImageViewTypeCircle;
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configureCellWithGroupDetailInfo: (TopicModel*) topicModel
{
    [self.avatarImageView setImageWithURL:[NSURL URLWithString:topicModel.author.avatarURL] placeholder:[UIImage imageNamed:@"default"] options:SDWebImageDelayPlaceholder progress:nil completedBlock:nil];
    
    self.avatarImageView.delegate = self;
    self.userTopic.text = topicModel.author.userName;
    self.usersTopicContent.text = topicModel.topicText;
    self.numberOfReplies.text = [NSString stringWithFormat:@"%ld", (unsigned long)topicModel.replies.count];
    self.date.text = topicModel.date;
}

#pragma mark - QMImageViewDelegate

- (void)imageViewDidTap:(QMImageView *) __unused imageView {
    [self.delegate didTapAvatar:self];
}


@end
