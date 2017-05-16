//
//  FirstCommentCell.m
//  reach-ios
//
//  Created by Admin on 2016-12-22.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "FirstCommentCell.h"
#import "QMImageView.h"

@interface FirstCommentCell() <QMImageViewDelegate>
@property (weak, nonatomic) IBOutlet QMImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *postText;

@end

@implementation FirstCommentCell

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
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.avatarImageView.imageViewType = QMImageViewTypeCircle;
    self.avatarImageView.userInteractionEnabled = YES;
    self.avatarImageView.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void) configureCell: (PostModel*)  post
{
    if ([post.permission boolValue]) {
        self.username.text = post.author.userName;
        NSURL *avatarUrl = [NSURL URLWithString:post.author.avatarURL];
        
        [self.avatarImageView setImageWithURL:avatarUrl placeholder:[UIImage imageNamed:@"default"] options:SDWebImageDelayPlaceholder progress:nil completedBlock:nil];
    } else {
        self.username.text = @"Anonymous";
        self.avatarImageView.image = [UIImage imageNamed:@"default-avatar"];
    }
 
    self.postText.text = post.text;
}


#pragma mark - QMImageViewDelegate

- (void)imageViewDidTap:(QMImageView *) __unused imageView {
    [self.delegate didTapAvatarFirst:self];
}

@end
