//
//  QMRootViewControllerSegue.m
//  Q-municate
//
//  Created by Igor Alefirenko on 13/02/2014.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMRootViewControllerSegue.h"
#import "QMAppDelegate.h"

@implementation QMRootViewControllerSegue

- (void)perform {
    
    QMAppDelegate *delegate = (QMAppDelegate *)[UIApplication sharedApplication].delegate;
    
    UIView *snapShot = [delegate.window snapshotViewAfterScreenUpdates:YES];
    [self.destinationViewController.view addSubview:snapShot];
    delegate.window.rootViewController = self.destinationViewController;
    [UIView animateWithDuration:1.0 animations:^{
        snapShot.layer.opacity = 0;
        snapShot.layer.transform = CATransform3DMakeScale(1.5, 1.5, 1.5);
    } completion:^(BOOL __unused finished) {
        [snapShot removeFromSuperview];
    }];
    
//    self.destinationViewController.view.backgroundColor = [UIColor orangeColor];
//    
//    UIView *myView1 = delegate.window.rootViewController.view;
//    
//    UIView *myView2 = self.destinationViewController.view;
//    
//    myView2.frame = delegate.window.bounds;
//    
//    [delegate.window addSubview:myView2];
//    
//    CATransition* transition = [CATransition animation];
//    transition.startProgress = 0;
//    transition.endProgress = 1.0;
//    transition.type = kCATransitionFade;
//    transition.subtype = kCATransitionReveal;
//    transition.duration = 5.0;
//    
//    // Add the transition animation to both layers
//    [myView1.layer addAnimation:transition forKey:@"transition"];
//    [myView2.layer addAnimation:transition forKey:@"transition"];
//    myView2.hidden = NO;
//    
//    [UIView animateWithDuration:0.5 animations:^{
//        myView1.hidden = YES;
//    } completion:^(BOOL __unused finished) {
//    }];
//    delegate.window.rootViewController = self.destinationViewController;
}

@end
