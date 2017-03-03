//
//  BaseViewController.h
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/21/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

- (void)addKeyboardObservers;
- (void)removeKeyboardObservers;
- (void)keyboardWillShowWithSize:(CGSize)size;
- (void)keyboardWillHideToController;
- (void)backButtonAction;

@end
