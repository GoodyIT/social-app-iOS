//
//  BaseTextInputView.m
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/21/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import "BaseTextInputView.h"

@implementation BaseTextInputView

-(void)layoutSubviews {
    [super layoutSubviews];
    
    self.layer.borderColor = [UIColor colorWithRed:0.7556 green:0.7556 blue:0.7556 alpha:1.0].CGColor;
  //  self.layer.borderWidth = 1;
    
    
    CALayer *bottomBorder = [CALayer layer];
    bottomBorder.frame = CGRectMake(0.0f, self.frame.size.height - 1, self.frame.size.width, 1.0f);
    bottomBorder.backgroundColor = [UIColor whiteColor].CGColor;
    [self.layer addSublayer:bottomBorder];
}

@end
