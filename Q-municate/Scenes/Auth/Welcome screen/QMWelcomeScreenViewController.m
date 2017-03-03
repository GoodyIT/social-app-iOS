//
//  SplashControllerViewController.m
//  Q-municate
//
//  Created by Igor Alefirenko on 13/02/2014.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMWelcomeScreenViewController.h"
#import "QMLicenseAgreement.h"
#import "QMAlert.h"
#import <SVProgressHUD.h>

#import "QMFacebook.h"
#import "QMCore.h"
#import "QMContent.h"
#import "QMTasks.h"

#import <DigitsKit/DigitsKit.h>
#import "QMDigitsConfigurationFactory.h"

static NSString * const kQMFacebookIDField = @"id";

@implementation QMWelcomeScreenViewController

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)dealloc {
    
    ILog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self prepareUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)prepareUI {
    //    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.0866 green:0.6965 blue:0.9986 alpha:1.0];
    //        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barTintColor = [UIColor clearColor];
    self.navigationController.navigationBar.tintColor = [UIColor clearColor];
    
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.translucent = NO;
    
    self.view.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleRadial withFrame:self.view.frame andColors:@[[UIColor gradeintBackStart], [UIColor gradeintBackEnd]]];
    self.loginBtn.layer.borderColor = [UIColor babyBule].CGColor;
    self.registerBtn.layer.borderColor = [UIColor babyBule].CGColor;
}

#pragma mark - Actions

- (IBAction)connectWithPhone {
    
    @weakify(self);
    [QMLicenseAgreement checkAcceptedUserAgreementInViewController:self completion:^(BOOL success) {
        // License agreement check
        if (success) {
            @strongify(self);
            [self performDigitsLogin];
        }
    }];
}

- (IBAction)loginWithEmailOrSocial:(UIButton *)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_LOGIN_WITH_FACEBOOK", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull __unused action) {
                                                          
                                                          [QMLicenseAgreement checkAcceptedUserAgreementInViewController:self completion:^(BOOL success) {
                                                              // License agreement check
                                                              if (success) {
                                                                  
                                                                  [self chainFacebookConnect];
                                                              }
                                                          }];
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_LOGIN_WITH_EMAIL", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull __unused action) {
                                                          
                                                          [self performSegueWithIdentifier:kQMSceneSegueLogin sender:nil];
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_CANCEL", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    
    if (alertController.popoverPresentationController) {
        // iPad support
        alertController.popoverPresentationController.sourceView = sender;
        alertController.popoverPresentationController.sourceRect = sender.bounds;
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)chainFacebookConnect {
    
    @weakify(self);
    [[[QMFacebook connect] continueWithBlock:^id _Nullable(BFTask<NSString *> * _Nonnull task) {
        // Facebook connect
        if (task.isFaulted || task.isCancelled) {
            
            return nil;
        }
        
        [SVProgressHUD show];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        
        return [[QMCore instance].authService loginWithFacebookSessionToken:task.result];
        
    }] continueWithBlock:^id _Nullable(BFTask<QBUUser *> * _Nonnull task) {
        
        if (task.isFaulted) {
            
            [QMFacebook logout];
        }
        else if (task.result != nil) {
            
            @strongify(self);
            [SVProgressHUD dismiss];
            [self performSegueWithIdentifier:kQMSceneSegueMain sender:nil];
            [QMCore instance].currentProfile.accountType = QMAccountTypeFacebook;
            [[QMCore instance].currentProfile synchronizeWithUserData:task.result];
            
            if (task.result.avatarUrl.length == 0) {
                
                return [[[QMFacebook loadMe] continueWithSuccessBlock:^id _Nullable(BFTask<NSDictionary *> * _Nonnull loadTask) {
                    // downloading user avatar from url
                    NSURL *userImageUrl = [QMFacebook userImageUrlWithUserID:loadTask.result[kQMFacebookIDField]];
                    return [QMContent downloadImageWithUrl:userImageUrl];
                    
                }] continueWithSuccessBlock:^id _Nullable(BFTask<UIImage *> * _Nonnull imageTask) {
                    // uploading image to content module
                    return [QMTasks taskUpdateCurrentUserImage:imageTask.result progress:nil];
                }];
            }
            
            return [[QMCore instance].pushNotificationManager subscribeForPushNotifications];
        }
        
        return nil;
    }];
}

- (void)performDigitsLogin {
    
    @weakify(self);
    [[Digits sharedInstance] authenticateWithViewController:nil configuration:[QMDigitsConfigurationFactory qmunicateThemeConfiguration] completion:^(DGTSession *session, NSError *error) {
        @strongify(self);
        // twitter digits auth
        if (error.userInfo.count > 0) {
            
            [QMAlert showAlertWithMessage:NSLocalizedString(@"QM_STR_UNKNOWN_ERROR", nil) actionSuccess:NO inViewController:self];
        }
        else {
            
            DGTOAuthSigning *oauthSigning = [[DGTOAuthSigning alloc] initWithAuthConfig:[Digits sharedInstance].authConfig
                                                                            authSession:session];
            
            NSDictionary *authHeaders = [oauthSigning OAuthEchoHeadersToVerifyCredentials];
            if (!authHeaders) {
                // user seems skipped auth process
                return;
            }
            
            [SVProgressHUD show];
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            
            [[[QMCore instance].authService loginWithTwitterDigitsAuthHeaders:authHeaders] continueWithBlock:^id _Nullable(BFTask<QBUUser *> * _Nonnull task) {
                
                [SVProgressHUD dismiss];
                
                if (!task.isFaulted) {
                    
                    [self performSegueWithIdentifier:kQMSceneSegueMain sender:nil];
                    
                    [QMCore instance].currentProfile.accountType = QMAccountTypeDigits;
                    
                    QBUUser *user = task.result;
                    if (user.fullName.length == 0) {
                        // setting phone as user full name
                        user.fullName = user.phone;
                        
                        QBUpdateUserParameters *updateUserParams = [QBUpdateUserParameters new];
                        updateUserParams.fullName = user.fullName;
                        
                        return [QMTasks taskUpdateCurrentUser:updateUserParams];
                    }
                    
                    [[QMCore instance].currentProfile synchronizeWithUserData:user];
                    
                    return [[QMCore instance].pushNotificationManager subscribeForPushNotifications];
                }
                
                return nil;
            }];
        }
    }];
}

@end
