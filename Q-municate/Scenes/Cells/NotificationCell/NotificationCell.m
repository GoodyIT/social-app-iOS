//
//  NotificationCell.m
//  reach-ios
//
//  Created by Admin on 2016-12-26.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "NotificationCell.h"
#import <QMImageView.h>
#import "QMHelpers.h"

@interface NotificationCell() <QMImageViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *notificationTypeBtn;
@property (weak, nonatomic) IBOutlet QMImageView *userAvatarImage;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *notificationTime;
@property (weak, nonatomic) IBOutlet UIView *notificationView;

@end

@implementation NotificationCell

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
    
    _userAvatarImage.imageViewType = QMImageViewTypeCircle;
    _userAvatarImage.userInteractionEnabled = YES;
    _userAvatarImage.delegate = self;
    
    self.notificationText = [[KILabel alloc] init];
    self.notificationText.numberOfLines = 0;
    self.notificationText.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
    self.notificationText.tintColor = [UIColor babyBule];
    [self.notificationView addSubview:self.notificationText];
    [self.notificationView bringSubviewToFront:self.notificationText];
    [self.notificationText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.notificationView.mas_top); //with is an optional semantic filler
        make.left.equalTo(@16);
        make.bottom.equalTo(self.notificationView.mas_bottom);
        make.right.equalTo(self.notificationTime.mas_right);
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (NSString*) getCommentString:(NSDictionary*) response username:(NSString*) name
{
    NSString* result;
    
    for (NSDictionary* dic in response[@"post_comments"]) {
        NSDictionary* author = [dic objectForKey:@"author"];
        if  ([author[@"username"] isEqualToString:name])
        {
            result = dic[@"text"];
//            NSString* username = [QBSession currentSession].currentUser.fullName;
//            username = [@"@" stringByAppendingString:username];
//            NSRange range = [result rangeOfString:username];
//            if  (range.length != 0)
//            {
//                NSRange nameRange = NSMakeRange(range.location, result.length-range.location);
//                result = [result substringWithRange:nameRange];
//            }
//            
//            range = [result rangeOfString:@"@"];
//            if  (range.length != 0)
//            {
//               result = [result substringFromIndex:range.length-1];
//            }
            
            break;
        }
    }
    
    return result;
}


- (void) cancelOperation
{
    [self.imageOperation cancel];
}

- (void)configureCellWithNotificationInfo: (NotificationModel*) notificationModel shouldUpdateCell:(BOOL)shouldUpdateCell
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    self.imageOperation = [manager downloadImageWithURL:[NSURL URLWithString:notificationModel.image]
                                                options:SDWebImageRetryFailed
                                               progress:nil
                                              completed:^(UIImage *image, NSError __unused *error, SDImageCacheType __unused cacheType, BOOL __unused finished, NSURL __unused *imageURL) {
                                                  if (image)
                                                      self.userAvatarImage.image = image;
                                                  else
                                                      self.userAvatarImage.image = [UIImage imageNamed:@"default"];
                                              }];
    
    self.userAvatarImage.delegate = self;
    
    self.username.text = notificationModel.username;
    self.notificationTime.text = notificationModel.date;
    if ([notificationModel.action isEqualToString:@"Like"]) {
        [self.notificationTypeBtn setImage:[UIImage imageNamed:@"Like_red"] forState:UIControlStateNormal];
        self.notificationText.text = [NSString stringWithFormat:@"Liked your post"];
    } else if ([notificationModel.action isEqualToString:@"PostCommentComment"] || [notificationModel.action isEqualToString:@"PostComment"])
    {
        [self.notificationTypeBtn setImage:[UIImage imageNamed:@"comment"] forState:UIControlStateNormal];
        self.notificationText.text = [@"commented: " stringByAppendingString:notificationModel.commentText];

    }
    else if ([notificationModel.action isEqualToString:@"UpVote"] ) {
        [self.notificationTypeBtn setImage:[UIImage imageNamed:@"upvote-selected"] forState:UIControlStateNormal] ;
        self.notificationText.text = [@"upvoted: " stringByAppendingString:notificationModel.commentText];

    }
    else if ([notificationModel.action isEqualToString:@"DownVote"] ) {
        [self.notificationTypeBtn setImage:[UIImage imageNamed:@"downvote-selected"] forState:UIControlStateNormal] ;
        self.notificationText.text = [@"downvoted: " stringByAppendingString:notificationModel.commentText];
    }
    
    if (![notificationModel.readState boolValue] && !shouldUpdateCell) {
        [self setBackgroundColor:[UIColor colorWithHexString:@"F5F3F2"]];
    } else {
        [self setBackgroundColor:[UIColor clearColor]];
    }
}

- (void) configureCellWithGroupNotification: (GroupNotificationModel*) groupNotificationModel shouldUpdateCell:(BOOL)shouldUpdateCell
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    self.imageOperation = [manager downloadImageWithURL:[NSURL URLWithString:groupNotificationModel.image]
                                                options:SDWebImageRetryFailed
                                               progress:nil
                                              completed:^(UIImage *image, NSError __unused *error, SDImageCacheType __unused cacheType, BOOL __unused finished, NSURL __unused *imageURL) {
                                                  if (image)
                                                      self.userAvatarImage.image = image;
                                                  else
                                                      self.userAvatarImage.image = [UIImage imageNamed:@"default"];
                                              }];
    
    self.userAvatarImage.delegate = self;
    
    self.username.text = groupNotificationModel.username;
    self.notificationTime.text = groupNotificationModel.date;
    
    [self.notificationTypeBtn setImage:[UIImage imageNamed:@"comment"] forState:UIControlStateNormal] ;
    
    if  ([groupNotificationModel.notitype integerValue] == 0)
    {
        [self.notificationTypeBtn setImage:[UIImage imageNamed:@"comment"] forState:UIControlStateNormal] ;
        self.notificationText.text = [@"commented:" stringByAppendingString: groupNotificationModel.detail];
    } else if ([groupNotificationModel.notitype integerValue] == 1)
    {
        [self.notificationTypeBtn setImage:[UIImage imageNamed:@"circles-selected"] forState:UIControlStateNormal] ;
        self.notificationText.text = [@"left a status:" stringByAppendingString: groupNotificationModel.detail];
    } else if  ([groupNotificationModel.notitype integerValue] == 2)
    {
        [self.notificationTypeBtn setImage:[UIImage imageNamed:@"group-icon"] forState:UIControlStateNormal];
        self.notificationText.text = @"joined your group";
    }
    
    if (![groupNotificationModel.readState boolValue] && !shouldUpdateCell) {
        [self setBackgroundColor:[UIColor colorWithHexString:@"F5F3F2"]];
    } else {
        [self setBackgroundColor:[UIColor clearColor]];
    }
}

#pragma mark - QMImageViewDelegate

- (void)imageViewDidTap:(QMImageView *) __unused imageView {
    [self.delegate didTapAvatar:self];
}

@end
