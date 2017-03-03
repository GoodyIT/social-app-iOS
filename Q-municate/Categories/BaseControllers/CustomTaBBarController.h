//
//  CustomTaBBarController.h
//  reach-ios
//
//  Created by Admin on 2017-01-07.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTaBBarController : UITabBarController

@property (strong, nonatomic) NSString* pushType;

- (void) updateBadge: (BOOL) fromPush;


@end
