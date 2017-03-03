//
//  UIImage+Base64.h
//  Reach-iOS
//
//  Created by AlexFill on 21.01.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Base64)

- (NSString *)encodeToBase64String;
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

@end
