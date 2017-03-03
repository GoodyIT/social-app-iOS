//
//  QMLogInViewController.m
//  Q-municate
//
//  Created by Igor Alefirenko on 13/02/2014.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMLogInViewController.h"
#import "QMCore.h"
#import "UINavigationController+QMNotification.h"
#import "BaseTextInputView.h"
#import "NSString+Validation.h"
#import "ForgotPasswordViewController.h"
#import "MainAnimViewController.h"

@interface QMLogInViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@property (weak, nonatomic) IBOutlet BaseTextInputView *passwordView;
@property (weak, nonatomic) IBOutlet BaseTextInputView *emailView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *btnLogin;

@property (strong, nonatomic) UITextField *activeTextField;

@property (weak, nonatomic) BFTask *task;

@end

@implementation QMLogInViewController

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

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self addTapGesture];
    [self prepareUI];
}

- (void)addKeyboardObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeKeyboardObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addKeyboardObservers];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeKeyboardObservers];
    [SVProgressHUD dismiss];
}

- (IBAction)closeScreen:(id) __unused sender {
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Keyboard
- (void)keyboardWillShow:(NSNotification*) notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if (keyboardSize.height != 0.0f)
    {
         CGFloat y = -keyboardSize.height/2;
        CGRect frame = CGRectMake(self.view.frame.origin.x, y, self.view.frame.size.width, self.view.frame.size.height);
        [self.view setFrame:frame];
        [self.view layoutIfNeeded];
    }
}

- (void)keyboardWillHide:(NSNotification*) notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    if (keyboardSize.height != 0.0f)
    {
        CGFloat y = 0;
        CGRect frame = CGRectMake(self.view.frame.origin.x, y, self.view.frame.size.width, self.view.frame.size.height);
        [self.view setFrame:frame];
        [self.view layoutIfNeeded];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *) __unused textField {
    if ([self.emailField isFirstResponder]) {
        [self.passwordField becomeFirstResponder];
    } else {
        [self.view endEditing:YES];
        [self done:nil];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange) __unused range replacementString:(NSString *) __unused string {
    if ([textField isFirstResponder]) {
        if ([[[textField textInputMode] primaryLanguage] isEqualToString:@"emoji"] || ![[textField textInputMode] primaryLanguage]) {
            return NO;
        }
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *) __unused textField {
    self.activeTextField = nil;
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

    self.title = @"LOGIN";
    [[_btnLogin layer] setBorderColor:[UIColor whiteColor].CGColor];
    
    self.emailField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"Email" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
    self.passwordField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
}

#pragma mark - Actions

- (IBAction)done:(id) __unused sender {
    
    [self.view endEditing:YES];
    
    if (self.task != nil) {
        // task in progress
        return;
    }
    
    NSString* email = self.emailField.text;
    NSString* password = self.passwordField.text;
    if (email.length == 0 || password.length == 0) {
         [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"QM_STR_FILL_IN_ALL_THE_FIELDS", nil)];
    } else  if (![email isEmailValid]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Please input valid email", nil)];
    } else if (password.length < 6)
    {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"The password length should be greater than 6", nil)];
    }
    else {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"QM_STR_SIGNING_IN", nil)];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        
        @weakify(self);
        self.task = [[[QMNetworkManager sharedManager] loginUserWithEmail:email password:password] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
            
           if (serverTask.error != nil) {
               [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
               return nil;
           }
            [TokenModel sharedInstance].token = [serverTask.result valueForKey:@"token"];
            NSDictionary* userDict = [serverTask.result objectForKey:@"user"];
            [TokenModel sharedInstance].currentUserID = [userDict valueForKey:@"id"];
            [[DataManager sharedManager] setActiveUserID:[userDict valueForKey:@"id"]];
            [QMNetworkManager sharedManager].myProfile = [UserModel getUserWithResponce:userDict];
            
            @strongify(self);
            QBUUser *user = [QBUUser user];
            user.email = email;
            user.password = kQBPassword;

            self.task = [[[QMCore instance].authService loginWithUser:user] continueWithBlock:^id _Nullable(BFTask<QBUUser *> * _Nonnull QBtask) {
               
               @strongify(self);
               [SVProgressHUD dismiss];
               
               if (!QBtask.isFaulted) {
                   [QMCore instance].currentProfile.accountType = QMAccountTypeEmail;
                   [[QMCore instance].currentProfile synchronizeWithUserData:QBtask.result];
                   
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
               
               return nil;
           }];
            
            return nil;
        }];
    }
}

@end
