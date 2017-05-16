//
//  NewsFeedCellTableViewCell.m
//  reach-ios
//
//  Created by Admin on 2016-12-07.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "NewsFeedCellTableViewCell.h"
#import <QMImageView.h>
#import <KILabel.h>
#import "SDWebImageManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "QMHelpers.h"

@import AVKit;

@interface NewsFeedCellTableViewCell()<QMImageViewDelegate>
{
    AVPlayer * avPlayer;
    AVPlayerLayer* avPlayerLayer;
}
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *postImage;
@property (weak, nonatomic) IBOutlet UILabel *likesLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentsLabel;
@property (weak, nonatomic) IBOutlet UILabel *timesLabel;

@property (weak, nonatomic) IBOutlet UIView *tagView;
@property (weak, nonatomic) IBOutlet UIView *redLikeBtn;
@property (weak, nonatomic) IBOutlet UIView *commentBtn;
@property (weak, nonatomic) IBOutlet UIButton *likeSmallBtn;
@property (weak, nonatomic) IBOutlet UIButton *redLikeImageBtn;
@property (weak, nonatomic) IBOutlet UIView *avatarView;

@property (weak, nonatomic) IBOutlet UIButton *btnVideo;
@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *bottomBar;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@property (strong, nonatomic) NSURL *postUrl;
@property (strong, nonatomic) NSString *trimmedString;

@property (strong, nonatomic) id notificationToken;

@property (strong, nonatomic) UITableView* parentTableView;

@end

@implementation NewsFeedCellTableViewCell
@synthesize likeLabel;


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
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.trimmedString = @"";
    
    _avatarImageView.imageViewType = QMImageViewTypeCircle;
    _avatarImageView.userInteractionEnabled = YES;
    _avatarImageView.delegate = self;
    _usernameLabel.text = nil;
    _likesLabel.text = @"0";
    _commentsLabel.text = @"0";
    _timesLabel.text = @"0 Hour(s) ago";
    _postText.text = @"";
    
    _likesLabel.userInteractionEnabled = YES;
    _commentsLabel.userInteractionEnabled = YES;
    
    _tagsLabel = [[KILabel alloc] init];
    self.tagsLabel.numberOfLines = 0;
    self.tagsLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:19.0];
    self.tagsLabel.tintColor = [UIColor babyBule];
    [self.tagView addSubview:self.tagsLabel];
    [self.tagView bringSubviewToFront:self.tagsLabel];
    [_tagsLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagView.mas_top); //with is an optional semantic filler
        make.left.equalTo(@16);
        make.bottom.equalTo(self.tagView.mas_bottom);
        make.right.equalTo(self.tagView.mas_right);
    }];
    
    [_usernameLabel sizeToFit];
    
    self.postImage.userInteractionEnabled = YES;
    self.postImage.contentScaleFactor = UIViewContentModeScaleAspectFit;
    
    avPlayer = [[AVPlayer alloc] init];
    avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    avPlayerLayer =  [AVPlayerLayer playerLayerWithPlayer:avPlayer];
    avPlayerLayer.frame = CGRectMake(0, 0, self.contentView.frame.size.width, 300);
    avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    UITapGestureRecognizer *avatarTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarImageTapped)];
    avatarTap.numberOfTapsRequired = 1;
    [self.avatarView addGestureRecognizer:avatarTap];    

    UITapGestureRecognizer *likeLabelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(likeBtnClicked:)];
    likeLabelTap.numberOfTapsRequired = 1;
    [self.likesLabel addGestureRecognizer:likeLabelTap];
    
    UITapGestureRecognizer *commentLabelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commentBtnClicked:)];
    commentLabelTap.numberOfTapsRequired = 1;
    [self.commentsLabel addGestureRecognizer:commentLabelTap];
    
    UITapGestureRecognizer *readMoreGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(readMoreDidClickedGesture:)];
    readMoreGesture.numberOfTapsRequired = 1;
    [self.postText addGestureRecognizer:readMoreGesture];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - QMImageViewDelegate

- (void)imageViewDidTap:(QMImageView *) __unused imageView {
    [self.delegate didTapAvatar:self];
}

#pragma mark - Callbacks
- (IBAction)otherAction:(id) __unused sender {
    [self.delegate didTapActionButton:self onView:sender];
}

- (void) postImageTapped: (NewsFeedCellTableViewCell*) __unused cell
{
    [self.delegate didTapPostImage:self];
}

- (void) avatarImageTapped {
    [self.delegate didTapAvatar:self];
}

- (void) readMoreDidClickedGesture: (NewsFeedCellTableViewCell*) __unused sender{
    [self.delegate didTapReadMoreButton:self trimmedString:self.trimmedString];
}

- (IBAction)likeBtnClicked:(id) __unused sender {
    [self.delegate didTapLikeButton:self];
}

- (IBAction)commentBtnClicked:(id) __unused sender {
    [self.delegate didTapCommentButton:self];
}

- (IBAction)commentSmallBtnClicked:(id) __unused sender {
    [self.delegate didTapCommentButton:self];
}

- (IBAction)likeSmallBtnClicked:(id) __unused sender {
     [self.delegate didTapLikeButton:self];
}


- (NSURL*) getPostImageURL
{
    return _postUrl;
}

- (IBAction)actionPlay:(id)sender {
    UIButton* btn = (UIButton*) sender;
    if  (btn.tag == 1)
    {
        self.playBtn.tag = 0;
        [self playVideo];
    } else {
        [self stopVideo];
        self.playBtn.tag = 1;
    }
}

- (void) stopVideo
{
    [avPlayer pause];
    [self.playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
}

- (void) playVideo
{
    [avPlayer play];
    [self.playBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
}

- (void) updateLike: (PostModel*) postInfo
{
    if ([postInfo.isLiked isEqual:@(1)]) {
        self.likeLabel.text = @"Liked";
        [self.redLikeImageBtn setImage:[UIImage imageNamed:@"Like_red"] forState:UIControlStateNormal] ;
        
    } else {
        self.likeLabel.text = @"Like";
        [self.redLikeImageBtn setImage:[UIImage imageNamed:@"Like_icon"] forState:UIControlStateNormal] ;
    }
    
    if  ([postInfo.likesCount integerValue] < 1)
    {
        [self.likeSmallBtn setImage:[UIImage imageNamed:@"Like_icon"] forState:UIControlStateNormal] ;
    } else {
        [self.likeSmallBtn setImage:[UIImage imageNamed:@"Like_red"] forState:UIControlStateNormal] ;
    }
    
    self.likesLabel.text = postInfo.likesCount.stringValue;
}

- (void) editCell: (PostModel *)postInfo
{
    self.postText.editable = YES;
    self.postText.text = postInfo.text;
    [self.postText becomeFirstResponder];
}

- (void)configureCellWithPostInfo:(PostModel *)postInfo withSize:(CGRect) __unused size parentTableView:(UITableView*) tableView{
    self.parentTableView = tableView;
    if (![postInfo.video isKindOfClass:[NSNull class]]) {
        self.postImage.image = nil;
        self.playBtn.hidden = NO;
        self.playBtn.tag = 1;
        [self.playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        NSURL *videoURL = [NSURL URLWithString:postInfo.video];
        AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset: asset];

        [avPlayer replaceCurrentItemWithPlayerItem:item];
        avPlayerLayer.player = avPlayer;
       [self.postImage.layer addSublayer:avPlayerLayer];
        self.notificationToken = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:[avPlayer currentItem] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification)
                                  {
                                      // Simple item playback rewind.
                                      // [[self.player currentItem] seekToTime:kCMTimeZero];
                                      AVPlayerItem *playerItem = [notification object];
                                      [playerItem seekToTime:kCMTimeZero];
                                  }];
    } else {
        self.playBtn.hidden = YES;
        [avPlayer pause];
        self.postUrl = [NSURL URLWithString:postInfo.image];
        
        if (avPlayerLayer != nil){
            [avPlayerLayer removeFromSuperlayer];
        }
        
        [self.postImage sd_setImageWithURL:self.postUrl placeholderImage:[UIImage imageNamed:@"profile_back"]];
        
        UITapGestureRecognizer *postImageTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(postImageTapped:)];
        postImageTapped.numberOfTapsRequired = 1;
        [self.postImage addGestureRecognizer:postImageTapped];
    }
    
    self.timesLabel.text = getTimeLog(postInfo.date);

    [_tagsLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tagView.mas_top); //with is an optional semantic filler
        make.left.equalTo(@16);
        make.bottom.equalTo(self.tagView.mas_bottom);
        make.right.equalTo(self.bottomBar.mas_right);
    }];

    
    NSMutableString *hashtagsString = [@"" mutableCopy];
    for (HashtagModel *hashtag in postInfo.hashtags) {
        if ([hashtag.hashtagText stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0) {
            //                [hashtagsString appendString:@"#"];
            [hashtagsString appendString:hashtag.hashtagText];
            [hashtagsString appendString:@" "];
        }
    }
    
    if ([postInfo.author.userId integerValue] == [[QBSession currentSession].currentUser.login integerValue]){
        [self.redLikeBtn setUserInteractionEnabled:NO];
        self.redLikeImageBtn.enabled = NO;
        self.likeSmallBtn.enabled = NO;
    } else {
        [self.redLikeBtn setUserInteractionEnabled:YES];
        self.redLikeImageBtn.enabled = YES;
        self.likeSmallBtn.enabled = YES;
    }
    
    [self updateLike:postInfo];
    
    self.tagsLabel.text = hashtagsString;
    self.commentsLabel.text = postInfo.commentCount.stringValue;
    self.trimmedString = @"";
    
    if  (postInfo.text.length > 120) {
        NSString *subString =  [postInfo.text substringWithRange:NSMakeRange(0, 120)];
        subString = [subString stringByAppendingString:@"...ReadMore"];

        NSString* username = [postInfo.permission boolValue] ? postInfo.author.userName : @"Anonymous";
        subString = [NSString stringWithFormat:@"%@ %@", username, subString];
        NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:subString attributes:@{NSFontAttributeName :[UIFont fontWithName:@"AvenirNext-Regular" size:14.0],                                                                                                                                  NSForegroundColorAttributeName : [UIColor blackColor]}];
        [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Bold" size:14.0] range:NSMakeRange(0, username.length)];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(121 + username.length, 11)];
        [attributedString addAttribute:NSUnderlineStyleAttributeName value:NSUnderlineColorAttributeName range:NSMakeRange(121+username.length, 11)];
        self.postText.attributedText = attributedString;
        self.trimmedString = subString;
    } else {
        NSString* username = [postInfo.permission boolValue] ? postInfo.author.userName : @"Anonymous";
        NSString* subString1 = [NSString stringWithFormat:@"%@ %@", username, postInfo.text];
        NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:subString1 attributes:@{NSFontAttributeName :[UIFont fontWithName:@"AvenirNext-Regular" size:14.0],                                                                                                                                  NSForegroundColorAttributeName : [UIColor blackColor]}];
        [attributedString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Bold" size:14.0] range:NSMakeRange(0, username.length)];

        self.postText.attributedText = attributedString;
    }
    
    if ([postInfo.permission boolValue]) {
        self.usernameLabel.text = postInfo.author.userName;
        NSURL *avatarUrl = [NSURL URLWithString:postInfo.author.avatarURL];
        
         [self.avatarImageView setImageWithURL:avatarUrl placeholder:[UIImage imageNamed:@"default"] options:SDWebImageDelayPlaceholder progress:nil completedBlock:nil];
    } else {
        self.usernameLabel.text = @"Anonymous";
        self.avatarImageView.image = [UIImage imageNamed:@"default-avatar"];
    }
   
    [self.postText sizeToFit];
    [self sizeToFit];
}

@end
