//
//  QMAlert.m
//  Q-municate
//
//  Created by Vitaliy Gorbachov on 5/20/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMAlert.h"

@implementation QMAlert

+ (void)showAlertWithMessage:(NSString *)message actionSuccess:(BOOL)success inViewController:(UIViewController *)viewController {
    
    [QMAlert showAlertWithMessage:message actionSuccess:success inViewController:viewController withCompletion:nil];
}
    
+ (void) showAlertWithMessage:(NSString *)message actionSuccess:(BOOL)success inViewController:(UIViewController *)viewController withCompletion:(void(^)(void)) completion
    {
        NSString *title = success ? NSLocalizedString(@"QM_STR_SUCCESS", nil) : NSLocalizedString(@"QM_STR_ERROR", nil);
        
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:title
                                              message:message
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_OK", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull __unused action) {
            if (completion!= nil) {
                completion();
            }
        }]];
        
        [viewController presentViewController:alertController animated:YES completion:nil];
    }

@end
