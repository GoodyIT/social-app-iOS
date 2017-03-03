//
//  QMSplashViewController.m
//  Q-municate
//
//  Created by lysenko.mykhayl on 3/24/14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMSplashViewController.h"
#import "QMCore.h"

@implementation QMSplashViewController

- (void)dealloc {
    ILog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([QMCore instance].currentProfile.userData == nil || [[TokenModel sharedInstance].token isEqualToString:@""])
    {
        [self performSegueWithIdentifier:kQMSceneSegueAuth
                                  sender:nil];
    } else {
        [[[[QMNetworkManager sharedManager] updateAndGetUserWithCompletion] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
            if (!t.isFaulted) {
                [QMNetworkManager sharedManager].myProfile = [UserModel getUserWithResponce:[t.result objectForKey:@"user"]];
            }
            
            return t;
        }] continueWithBlock:^id _Nullable(BFTask * _Nonnull __unused task1) {
            [[[QMCore instance] login] continueWithBlock:^id _Nullable(BFTask * _Nonnull __unused task) {
                
                [self performSegueWithIdentifier:[QMCore instance].currentProfile.userData != nil && ![[TokenModel sharedInstance].token isEqualToString:@""] ? kQMSceneSegueMain : kQMSceneSegueAuth
                                          sender:nil];
                
                return [BFTask cancelledTask];
                
            }];
            
            return nil;
        }];
    }
}
@end
