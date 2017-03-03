//
//  ForgotPasswordViewController.m
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import "ForgotPasswordViewController.h"
#import "NSString+Validation.h"

@interface ForgotPasswordViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailField;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UITextField *activeTextField;
@property (weak, nonatomic) IBOutlet UIButton *btnForget;

@end

@implementation ForgotPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareUI];
    [self addTapGesture];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}

- (void)prepareUI {
    self.emailField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"Email" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
}

#pragma mark - IBAction

- (IBAction)recoverAction:(id) __unused sender {
       
    if (![self.emailField.text isEmailValid]) {
         [SVProgressHUD showErrorWithStatus:@"Wrong Email"];
        return;
    }
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"QM_STR_LOADING", nil)];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];

    @weakify(self);
    [[[QMNetworkManager sharedManager] restorePasswordWithEmail:self.emailField.text] continueWithBlock: ^ id _Nullable (BFTask * _Nonnull  task) {
        // Error handling
         @strongify(self);
        if (task.error != nil ) {
            [SVProgressHUD showErrorWithStatus:task.error.localizedDescription];
        } else {
            [SVProgressHUD dismiss];
            [self.view endEditing:YES];
            [self.navigationController popViewControllerAnimated:YES];
        }
        
        return nil;
    }];
}

- (IBAction)closeScreen:(id) __unused sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *) __unused textField {
    [self.view endEditing:YES];
    [self recoverAction:nil];
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)__unused textField {
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

@end
