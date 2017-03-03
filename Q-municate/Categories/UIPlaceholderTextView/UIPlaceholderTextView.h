//
//  UIPlaceholderTextView.h
//  Reach-iOS
//
//  Created by AlexFill on 20.01.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIPlaceholderTextView : UITextView

@property (copy, nonatomic) NSString *placeholder;
@property (strong, nonatomic) UIColor *placeholderColor;

-(void)textChanged:(NSNotification*)notification;

@end
