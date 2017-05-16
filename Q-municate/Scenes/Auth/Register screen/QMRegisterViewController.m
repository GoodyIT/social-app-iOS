//
//  QMRegisterViewController.m
//  reach-ios
//
//  Created by Admin on 2016-11-29.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMRegisterViewController.h"
#import "QMCore.h"
#import "UINavigationController+QMNotification.h"
#import "BaseTextInputView.h"
#import "NSString+Validation.h"
#import "CalendarViewController.h"
#import "MainAnimViewController.h"
#import <STPopup/STPopup.h>



@interface QMRegisterViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *firstnameField;
@property (weak, nonatomic) IBOutlet UITextField *lastnameField;
@property (weak, nonatomic) IBOutlet UITextField *birthdayField;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *btnSignup;

@property (strong, nonatomic) UITextField *activeTextField;

@property (weak, nonatomic) BFTask *task;

@end

@implementation QMRegisterViewController

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self prepareUI];
    [self addTapGesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addKeyboardObservers];
    
    self.birthdayField.text = [QMNetworkManager sharedManager].installDate;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeKeyboardObservers];
    [SVProgressHUD dismiss];
}

- (IBAction)closeScreen:(id) __unused sender {
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - UITextFieldDelegate


- (BOOL)textFieldShouldReturn:(UITextField *) __unused textField {
    if ([self.firstnameField isFirstResponder]) {
        [self.lastnameField becomeFirstResponder];
    } else if ([self.lastnameField isFirstResponder]) {
        [self.usernameField becomeFirstResponder];
    } else if ([self.usernameField isFirstResponder]) {
        [self.birthdayField becomeFirstResponder];
    } else if ([self.emailField isFirstResponder]) {
        [self.passwordField becomeFirstResponder];
    } else if ([self.passwordField isFirstResponder]) {
        [self.view endEditing:YES];
        [self registerUser:nil];
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *) __unused textField {
    self.activeTextField = nil;
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification*) notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if (keyboardSize.height != 0.0f && ( [self.emailField isFirstResponder] || [self.passwordField isFirstResponder] || [self.birthdayField isFirstResponder] || [self.usernameField isFirstResponder]) )
    {
        CGFloat y = -keyboardSize.height;
        CGRect frame = CGRectMake(self.view.frame.origin.x, y, self.view.frame.size.width, self.view.frame.size.height);
        [self.view setFrame:frame];
        [self.view layoutIfNeeded];
    }
}

- (void)keyboardWillHide:(NSNotification*) notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if (keyboardSize.height != 0.0f)
    {
        CGFloat y = 0;//self.view.frame.origin.y + keyboardSize.height;
        CGRect frame = CGRectMake(self.view.frame.origin.x, y, self.view.frame.size.width, self.view.frame.size.height);
        [self.view setFrame:frame];
        [self.view layoutIfNeeded];
    }
}

- (IBAction)registerUser:(id) __unused sender {
    [self.view endEditing:YES];
    
    if (self.task != nil) {
        // task in progress
        return;
    }
    
    NSString* username = self.usernameField.text;
    NSString* firstname = self.firstnameField.text;
    NSString* lastname = self.lastnameField.text;
    NSString* birthday = self.birthdayField.text;
    NSString* email = self.emailField.text;
    NSString* password = self.passwordField.text;
    
    if (email.length == 0 || password.length == 0 || username.length == 0 || birthday.length == 0) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_FILL_IN_ALL_THE_FIELDS", nil)];
    } else  if (![email isEmailValid]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Please input valid email", nil)];
    } else if (password.length < 8 || password.length > 20)
    {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"The password length should be between 8 and 20", nil)];
    } else if (username.length < 6)
    {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"The username length should be greater than 6", nil)];
    }
    else {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"QM_STR_SIGNING_UP", nil)];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];

        @weakify(self);
      
                QBUUser *user = [QBUUser user];
                user.email = email;
                user.password = kQBPassword;
                user.fullName = username;
        
                self.task = [[[QMCore instance].authService signUpAndLoginWithUser:user] continueWithBlock:^id _Nullable(BFTask<QBUUser *> * _Nonnull QBtask) {
                    
                    @strongify(self);                    
                    if (!QBtask.isFaulted) {
                        [QMCore instance].currentProfile.accountType = QMAccountTypeEmail;
                        [[QMCore instance].currentProfile synchronizeWithUserData:QBtask.result];
                        
                        [[[QMNetworkManager sharedManager] registerUserWithUsername:username firstname:firstname lastname:lastname birthday:birthday email:email password:password] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
                            if (!serverTask.isFaulted)
                            {
                                [TokenModel sharedInstance].token = [serverTask.result valueForKey:@"token"];
                                NSDictionary* userDict = [serverTask.result objectForKey:@"user"];
                                [TokenModel sharedInstance].currentUserID = [userDict valueForKey:@"id"];
                                [[DataManager sharedManager] setActiveUserID:[userDict valueForKey:@"id"]];
                                [QMNetworkManager sharedManager].myProfile = [UserModel getUserWithResponce:userDict];
                                
                                QBUpdateUserParameters *params = [QBUpdateUserParameters new];
                                params.login = [userDict valueForKey:@"id"];
                                
                                [[QMTasks taskUpdateCurrentUser:params] continueWithBlock:^id _Nullable(BFTask<QBUUser *> * _Nonnull task) {
                                    
                                    @strongify(self);
                                    if (!task.isFaulted) {
                                        [SVProgressHUD dismiss];
                                        
                                        MainAnimViewController *splitViewControler =
                                        [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"MainAnimViewController"];
                                        
                                        [UIView transitionWithView:self.navigationController.view duration:1.0f
                                                           options:UIViewAnimationOptionTransitionFlipFromLeft
                                                        animations:^{
                                                            [self.navigationController pushViewController:splitViewControler animated:NO];
                                                        }
                                                        completion:nil];

                                        return [[QMCore instance].pushNotificationManager subscribeForPushNotifications];
                                    }
                                    
                                    [SVProgressHUD showErrorWithStatus:task.error.localizedDescription];
                                    return nil;
                                }];
                                
                                return nil;
                            }
                            
                        [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];

                        [QBRequest deleteCurrentUserWithSuccessBlock:^(QBResponse __unused *response) {
                            } errorBlock:^(QBResponse __unused *response) {
                            }];
                            
                            return nil;
                        }];
                        
                        return nil;
                    }
                    
                    NSError *aerror = nil;
                    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: [QBtask.error.localizedRecoverySuggestion dataUsingEncoding:NSUTF8StringEncoding]
                                                                         options: NSJSONReadingMutableContainers
                                                                           error: &aerror];
                    NSDictionary* errorDic = [dict objectForKey:@"errors"];
                    if  ([[errorDic.allKeys objectAtIndex:0] isEqualToString:@"email"]) {
                        [SVProgressHUD showErrorWithStatus:@"email is already taken by others"];
                    } else {
                        [SVProgressHUD showErrorWithStatus:QBtask.error.localizedDescription];
                    }
                  
                    return nil;
                }];
    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if(textField.tag == 4)
    {
        [self showCalendar];
        return NO; // preventing keyboard from showing
    }
    return YES;
}

- (void)showCalendar {
    [self.view endEditing:YES];
    
    CalendarViewController *calendarViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"CalendarView"];
    STPopupController *popupController = [[STPopupController alloc] initWithRootViewController:calendarViewController];
    [STPopupNavigationBar appearance].barTintColor = [UIColor colorWithRed:0.20f green:0.60f blue:0.86f alpha:1.0f];
    [STPopupNavigationBar appearance].tintColor = [UIColor whiteColor];
    [STPopupNavigationBar appearance].barStyle = UIBarStyleDefault;
    [STPopupNavigationBar appearance].titleTextAttributes = @{ NSFontAttributeName: [UIFont fontWithName:@"Cochin" size:18], NSForegroundColorAttributeName: [UIColor whiteColor] };
    popupController.transitionStyle = STPopupTransitionStyleFade;;
    popupController.containerView.layer.cornerRadius = 4;
    popupController.containerView.layer.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor;
    popupController.containerView.layer.shadowOffset = CGSizeMake(4, 4);
    popupController.containerView.layer.shadowOpacity = 1;
    popupController.containerView.layer.shadowRadius = 1.0;
    
    [popupController presentInViewController:self];
}


#pragma mark Private

- (void)addTapGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self.view addGestureRecognizer:tap];
}

- (void)handleTap {
    [self.view endEditing:YES];
}

- (void)prepareUI {
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.0866 green:0.6965 blue:0.9986 alpha:1.0];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.birthdayField.delegate = self;
    
    self.firstnameField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"First Name" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
    self.lastnameField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"Last Name" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
    self.usernameField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"Username" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
    self.birthdayField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"Birthday" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
    self.emailField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"Email" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
    self.passwordField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
