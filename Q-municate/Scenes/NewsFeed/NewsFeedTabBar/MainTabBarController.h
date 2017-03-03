//
//  MainTabBarController.h
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/21/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserModel.h"
#import "CustomTaBBarController.h"

@interface MainTabBarController : CustomTaBBarController

@property (strong, nonatomic) UserModel *user;
@property (nonatomic) BOOL isFromPush;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backBarButtonitem;

- (void) updateBadge: (BOOL) fromPush;

@end