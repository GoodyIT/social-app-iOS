//
//  WordCollectionViewCell.m
//  SelfSizingWaterfallCollectionViewLayout
//
//  Created by Adam Waite on 01/10/2014.
//  Copyright (c) 2014 adamjwaite.co.uk. All rights reserved.
//

#import "MyPostCell.h"
#import "SDWebImageManager.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "QMHelpers.h"

@import AVKit;

@interface MyPostCell()
{
    AVPlayerViewController *playerViewController;
    AVPlayer * avPlayer;
    AVPlayerLayer* avPlayerLayer;
}

@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@end

@implementation MyPostCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    playerViewController = [[AVPlayerViewController alloc] init];
    avPlayer = [[AVPlayer alloc] init];
    avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    avPlayerLayer =  [AVPlayerLayer playerLayerWithPlayer:avPlayer];
    avPlayerLayer.frame = CGRectMake(0, 0, self.contentView.frame.size.width, 300);
    avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

}

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    self.postText.preferredMaxLayoutWidth = layoutAttributes.size.width - 16.0f;
    UICollectionViewLayoutAttributes *preferredAttributes = [layoutAttributes copy];
  //  preferredAttributes.size = CGSizeMake(layoutAttributes.size.width, self.postText.intrinsicContentSize.height + 120.0f + 16.0f + self.postDate.intrinsicContentSize.height);
    preferredAttributes.size = CGSizeMake(layoutAttributes.size.width, 50 + 120.0f + 16.0f + self.postDate.intrinsicContentSize.height);
    return preferredAttributes;
}
- (IBAction)actionClicked:(id) __unused sender {
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

- (void) cancelOperation
{
    [self.imageOperation cancel];
     if  (self.playBtn.tag == 0)
     {
         [self stopVideo];
         self.playBtn.tag = 1;
     }
}

- (void) configureCell: (PostModel*) post
{
    if (![post.video isKindOfClass:[NSNull class]]) {
        self.postImage.image = nil;
        self.playBtn.hidden = NO;
        self.playBtn.tag = 1;
        [self.playBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        
        NSURL *videoURL = [NSURL URLWithString:post.video];
        AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset: asset];
        
        [avPlayer replaceCurrentItemWithPlayerItem:item];
        avPlayerLayer.player = avPlayer;
        [self.postImage.layer addSublayer:avPlayerLayer];
        [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:[avPlayer currentItem] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification)
                                  {
                                      // Simple item playback rewind.
                                      // [[self.player currentItem] seekToTime:kCMTimeZero];
                                      AVPlayerItem *playerItem = [notification object];
                                      [playerItem seekToTime:kCMTimeZero];
                                  }];
    } else {
        self.playBtn.hidden = YES;
        [avPlayer pause];
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        self.imageOperation = [manager downloadImageWithURL:[NSURL URLWithString:post.image]
                                                    options:SDWebImageRetryFailed
                                                   progress:nil
                                                  completed:^(UIImage *image, NSError __unused *error, SDImageCacheType __unused cacheType, BOOL __unused finished, NSURL __unused *imageURL) {
                                                      if (image)
                                                          self.postImage.image = image;
                                                      else
                                                          self.postImage.image = [UIImage imageNamed:@"profile_back"];
                                                  }];
    }
    
    self.postText.text = post.text;
    
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];
    [formater setDateFormat:@"HH:mm:ss yyyy:MM:dd"];
    NSDate* date = [formater dateFromString:post.date];
    [formater setDateFormat:@"MMM d, yyyy"];
    self.postDate.text = [formater stringFromDate:date];
}
@end
