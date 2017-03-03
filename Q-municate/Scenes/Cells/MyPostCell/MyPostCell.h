//
//  WordCollectionViewCell.h
//  SelfSizingWaterfallCollectionViewLayout
//
//  Created by Adam Waite on 01/10/2014.
//  Copyright (c) 2014 adamjwaite.co.uk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyPostCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *postImage;
@property (weak, nonatomic) IBOutlet UILabel *postText;
@property (weak, nonatomic) IBOutlet UILabel *postDate;

@property (weak) id <SDWebImageOperation> imageOperation;


- (void) configureCell: (PostModel*) post;

- (void) cancelOperation;

@end
