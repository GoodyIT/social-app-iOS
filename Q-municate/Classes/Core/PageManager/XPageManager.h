//
//  XPageManager.h
//  SmoothPay2.0
//
//  Created by Alex on 11/12/15.
//  Copyright (c) 2015 BCL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol XPageDelegate;

@interface XPageManager : NSObject

@property (assign, nonatomic) NSInteger                     selectedIndex;
@property (assign, nonatomic) NSRange                       rangeDisplay;
@property (weak, nonatomic) id<XPageDelegate>               delegate;
@property (weak, nonatomic, readonly) UIViewController *    selectedViewController;

- (instancetype) initWithParentViewController:(UIViewController *)parentViewController containerView:(UIView *)containerView viewControllers:(NSArray *)viewControllers;

- (void) setScrollEnable:(BOOL)bEnable;
- (void) selectPage:(NSInteger)select animated:(BOOL)animated notify:(BOOL)notify;

@end

@protocol XPageDelegate <NSObject>

@optional
- (void)pageManager:(XPageManager *)pageManager willTransitionToPage:(NSInteger)toPage fromPage:(NSInteger)fromPage;
- (void)pageManager:(XPageManager *)pageManager didTransitionToPage:(NSInteger)toPage fromPage:(NSInteger)fromPage;

@end
