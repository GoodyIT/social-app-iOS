//
//  XPageManager.m
//  SmoothPay2.0
//
//  Created by Alex on 11/12/15.
//  Copyright (c) 2015 BCL. All rights reserved.
//

#import "XPageManager.h"
#import "MyPostViewController.h"
#import "NotificationViewController.h"

@interface XPageManager () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *    pageViewController;
@property (strong, nonatomic) UIViewController *        parentViewController;
@property (strong, nonatomic) NSArray *                 viewControllers;
@property (strong, nonatomic) UIView *                  containerView;

@property (nonatomic, assign) BOOL                      customDirFromRight;

@end

@implementation XPageManager

- (instancetype)initWithParentViewController:(UIViewController *)parentViewController containerView:(UIView *)containerView viewControllers:(NSArray *)viewControllers {
    
    self = [super init];
    
    if (self) {
        
        self.parentViewController = parentViewController;
        self.viewControllers = viewControllers;
        self.containerView = containerView;
        self.rangeDisplay = NSMakeRange(0, viewControllers.count);
        
        [self setup];
    }
    
    return self;
}

- (void) setup {
    
    [_parentViewController setEdgesForExtendedLayout:UIRectEdgeNone];
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                            options:nil];
    
    _pageViewController.delegate = self;
    _pageViewController.dataSource = self;
    _pageViewController.doubleSided = YES;
    
    [_parentViewController addChildViewController:_pageViewController];
    [_containerView addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:_parentViewController];
    
    _selectedIndex = 0;
    
    for (UIView * view in _pageViewController.view.subviews) {
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            
            UIScrollView * scroll = (UIScrollView *) view;
            
            scroll.canCancelContentTouches = YES;
            scroll.delaysContentTouches = NO;
            scroll.scrollEnabled = NO;
        }
    }
    
    [self reloadData];
}

#pragma mark - Page View Data Source

- (UIViewController *)pageViewController:(UIPageViewController *) __unused pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger pageIndex = [_viewControllers indexOfObject:viewController];
    
    if (NSLocationInRange(pageIndex - 1, _rangeDisplay))
        return _viewControllers[pageIndex - 1];
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)__unused pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger pageIndex = [_viewControllers indexOfObject:viewController];
    
    if (NSLocationInRange(pageIndex + 1, _rangeDisplay))
        return _viewControllers[pageIndex + 1];
    return nil;
}


#pragma mark - Page View Delegate

- (void)pageViewController:(UIPageViewController *)__unused pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    
    UIViewController * toViewController = pendingViewControllers[0];
    NSInteger index = [_viewControllers indexOfObject:toViewController];
    
    if (!NSLocationInRange(index, _rangeDisplay))
        return;
    
    if (_delegate && [_delegate respondsToSelector:@selector(pageManager:willTransitionToPage:fromPage:)]) {
        
        [_delegate pageManager:self willTransitionToPage:index fromPage:_selectedIndex];
    }
}

- (void)pageViewController:(UIPageViewController *)__unused pageViewController didFinishAnimating:(BOOL)__unused finished previousViewControllers:(NSArray *)__unused previousViewControllers transitionCompleted:(BOOL)__unused completed {
    
    UIViewController * toViewController = self.selectedViewController;
    NSInteger index = [_viewControllers indexOfObject:toViewController];
    NSInteger befIndex = _selectedIndex;
    
    if (!NSLocationInRange(index, _rangeDisplay))
        return;
    
    _selectedIndex = index;
    
    if (_delegate && [_delegate respondsToSelector:@selector(pageManager:didTransitionToPage:fromPage:)]) {
        
        [_delegate pageManager:self didTransitionToPage:index fromPage:befIndex];
    }
}

- (void)reloadData {
    
    CGRect frame = _containerView.frame;
    
    frame.origin.x = 0;
    frame.origin.y = 0;
    _pageViewController.view.frame = frame;
    
    [_pageViewController setViewControllers:@[_viewControllers[_selectedIndex]]
                                  direction:UIPageViewControllerNavigationDirectionReverse
                                   animated:NO
                                 completion:nil];
}

- (void) showCustomPage:(UIViewController *)page animated:(BOOL)animated fromRight:(BOOL)dir {
    
    _customDirFromRight = dir;
    
    [_pageViewController setViewControllers:@[page]
                                  direction:dir ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse
                                   animated:animated
                                 completion:nil];
}

- (void) setSelectedIndex:(NSInteger)index {
    
    [self selectPage:index animated:YES notify:YES];
}

- (UIViewController *)selectedViewController {
    
    if (_pageViewController.viewControllers.count > 0)
        return _pageViewController.viewControllers[0];
    
    return nil;
}

- (void) setScrollEnable:(BOOL)bEnable {
    
    for (UIView * view in _pageViewController.view.subviews) {
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            
            UIScrollView * scroll = (UIScrollView *) view;
            
            scroll.scrollEnabled = bEnable;
        }
    }
}

- (void) selectPage:(NSInteger)select animated:(BOOL)animated notify:(BOOL)notify {
    
    if (select != _selectedIndex || _viewControllers[_selectedIndex] != self.selectedViewController) {
        
        UIViewController * toViewController = _viewControllers[select];
        NSInteger befIndex = _selectedIndex;
        __weak typeof(self) weakSelf = self;
        
        if (animated && notify && _delegate && [_delegate respondsToSelector:@selector(pageManager:willTransitionToPage:fromPage:)])
            [_delegate pageManager:self willTransitionToPage:select fromPage:befIndex];
        
        UIPageViewControllerNavigationDirection dir;
        
        if (self.selectedViewController != _viewControllers[_selectedIndex])
            dir = _customDirFromRight ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward;
        else
            dir = select > _selectedIndex ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
        
        _selectedIndex = select;
        
        [_pageViewController setViewControllers:@[toViewController] direction:dir animated:animated completion:^(BOOL __unused finished) {
            
            __strong typeof(self) strongSelf = weakSelf;
            
            if (animated && notify &&  self->_delegate && [self->_delegate respondsToSelector:@selector(pageManager:didTransitionToPage:fromPage:)])
                [strongSelf.delegate pageManager:strongSelf didTransitionToPage:select fromPage:befIndex];
        }];
    }
}

@end
