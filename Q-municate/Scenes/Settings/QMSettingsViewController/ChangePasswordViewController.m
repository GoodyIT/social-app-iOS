//
//  ChangePasswordViewController.m
//  Reach-iOS
//
//  Created by AlexFill on 08.02.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "ChangePasswordViewController.h"

#import "NSString+Validation.h"

#import <ChameleonFramework/Chameleon.h>

@interface ChangePasswordViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *currentPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmTextField;
@property (weak, nonatomic) IBOutlet UITextField *aNewPasswordTextField;

@property (weak, nonatomic) IBOutlet UIButton *btnChange;

@end

@implementation ChangePasswordViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareUI];
    [self addTapGesture];
    // Do any additional setup after loading the view.
    [self initializeData];
}

- (void) initializeData {
//    self.view.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleRadial withFrame:self.view.frame andColors:@[[UIColor gradeintBackStart], [UIColor gradeintBackEnd]]];
//    
//    [[_btnChange layer] setBorderColor:[UIColor whiteColor].CGColor];
    [self.currentPasswordTextField becomeFirstResponder];
}

#pragma mark - Private

- (void)prepareUI {
    self.title = @"Change Password";
    self.currentPasswordTextField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"Current Password" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
    
    self.aNewPasswordTextField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"New Password" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
    
    self.confirmTextField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"Confirm Password" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
}

- (void)addTapGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap)];
    [self.view addGestureRecognizer:tap];
}

- (void)handleTap {
    [self.view endEditing:YES];
}

#pragma mark - IBActions

- (IBAction)cancelTouched:(id)__unused sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveTouched:(id)__unused sender {
    [self.view endEditing:YES];
    @weakify(self);
    if([self isValidFields]){
        [SVProgressHUD show];
        [[[QMNetworkManager sharedManager] changePassword:self.currentPasswordTextField.text toPassword: self.aNewPasswordTextField.text] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
            
            @strongify(self);
            if (serverTask.isFaulted)
            {
                [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
                return nil;
            }
            [SVProgressHUD showSuccessWithStatus:@"Password successfully changed"];
            [self cleanTextFields];
            [self.navigationController popViewControllerAnimated:YES];
            
            return nil;
        }];
    }
}

#pragma mark CleanFields
-(void)cleanTextFields{
    self.currentPasswordTextField.text = @"";
    self.aNewPasswordTextField.text = @"";
    self.confirmTextField.text = @"";
    
}

#pragma mark Validation

- (BOOL)isValidFields {
    if ([self.currentPasswordTextField.text isEmptyOrWhiteSpace]) {
        [SVProgressHUD showErrorWithStatus:@"Empty Current Password Field"];
        return false;
    }
    if ([self.aNewPasswordTextField.text isEmptyOrWhiteSpace]) {
        [SVProgressHUD showErrorWithStatus:@"Empty New Password Field"];
        return false;
    }
    if ([self.confirmTextField.text isEmptyOrWhiteSpace]) {
        [SVProgressHUD showErrorWithStatus:@"Empty Comfirm Password Field"];
        return false;
    }
    if(![self.aNewPasswordTextField.text isEqualToString:self.confirmTextField.text]){
        [SVProgressHUD showErrorWithStatus:@"Confirm Password isn't equal to New Password"];
         return false;
    }
    
    return true;
}

#pragma mark - UITextFieldDelegate


- (BOOL)textFieldShouldReturn:(UITextField *)__unused textField {
    if ([self.currentPasswordTextField isFirstResponder]) {
        [self.aNewPasswordTextField becomeFirstResponder];
    } else if ([self.aNewPasswordTextField isFirstResponder]) {
        [self.confirmTextField becomeFirstResponder];
    } else {
        [self.view endEditing:YES];
    }
    
    return YES;
}



@end

