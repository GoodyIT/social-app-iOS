//
//  ChangeEmaiViewController.m
//  Reach-iOS
//
//  Created by AlexFill on 08.02.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "ChangeEmaiViewController.h"
#import "NSString+Validation.h"

#import <ChameleonFramework/Chameleon.h>

@interface ChangeEmaiViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIButton *btnChange;

@end

@implementation ChangeEmaiViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareUI];
    // Do any additional setup after loading the view.
    [self initializeData];
}

- (void) initializeData {
    self.view.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleRadial withFrame:self.view.frame andColors:@[[UIColor gradeintBackStart], [UIColor gradeintBackEnd]]];
    
    [[_btnChange layer] setBorderColor:[UIColor whiteColor].CGColor];
    [self.emailTextField becomeFirstResponder];
}

#pragma mark - Private

- (void)prepareUI {
    self.title = @"Change Email";
    self.emailTextField.text = self.user.email;
    self.emailTextField.attributedPlaceholder = [[NSMutableAttributedString alloc] initWithString:@"Email" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:14]}];
}

#pragma mark - IBActions

- (IBAction)cancelTouched:(id)__unused sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveTouched:(id)__unused sender {
    ///////////gumenuk///////////
    [self.view endEditing:YES];
    @weakify(self);
    if([self.emailTextField.text isEmailValid]){
        [SVProgressHUD show];
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
        [[[[QMNetworkManager sharedManager] changeEmailToEmail:self.emailTextField.text] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
            [SVProgressHUD dismiss];
            if (serverTask.isFaulted)
            {
                [SVProgressHUD showErrorWithStatus:serverTask.error.localizedDescription];
                return nil;
            }
            return nil;
        }] continueWithSuccessBlock:^id _Nullable(BFTask * _Nonnull __unused t) {
            QBUpdateUserParameters *params = [QBUpdateUserParameters new];
            params.email = self.emailTextField.text;
            
            [SVProgressHUD show];
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
            
            [[QMTasks taskUpdateCurrentUser:params] continueWithBlock:^id _Nullable(BFTask<QBUUser *> * _Nonnull task) {
                
                @strongify(self);
                [SVProgressHUD dismiss];
                
                if (!task.isFaulted) {
                    
                    [SVProgressHUD showSuccessWithStatus:@"Email successfully changed"];
                    self.emailTextField.text = @"";
                    
                    [self.navigationController popViewControllerAnimated:YES];
                }
                
                return nil;
            }];
            return nil;
        }];
    }

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
