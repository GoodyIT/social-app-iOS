//
//  SettingsViewController.m
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsSwitchTableViewCell.h"
#import "UserProfileViewController.h"

#import <SDWebImage/UIImageView+WebCache.h>
#import "NetworkManagerConstants.h"

//#import "ChangeEmaiViewController.h"
//#import "EditProfileViewController.h"
#import "DataManager.h"
//#import "Message+CoreDataProperties.h"
//#import "User+CoreDataProperties.h"
//#import "CoreDataManager.h"
#import "QMColors.h"


@interface SettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) id <NSObject> observerDidBecomeActive;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet QMImageView *userAvatar;
@property (strong, nonatomic) UserModel *user;

@property (weak, nonatomic) BFTask *subscribeTask;
@property (weak, nonatomic) BFTask *logoutTask;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareUI];    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    
    [self loadUser];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)prepareUI {
    self.title = @"SETTINGS";
    
    self.tableView.backgroundColor = QMTableViewBackgroundColor();
    
    UIImage *NavigationPortraitBackground = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    [[UINavigationBar appearance] setBackgroundImage:NavigationPortraitBackground forBarMetrics:UIBarMetricsDefault];
    
    self.userAvatar.imageViewType = QMImageViewTypeCircle;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)__unused tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 1 || indexPath.row == 4 || indexPath.row == 6)
        return 20.0f;
    return 50.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [self performSegueWithIdentifier:kProfileSegue sender:self.user];
    } else if (indexPath.row == 1) {
        
    } else if (indexPath.row == 2) {
        [self performSegueWithIdentifier:@"ChangeEmailSegue" sender:self.user];
    } else if (indexPath.row == 3) {
    } else if (indexPath.row == 4) {
    } else if (indexPath.row == 5) {
    } else if (indexPath.row == 6) {
        
        ////////gumenuk/////////
    } else {
        
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:nil
                                              message:NSLocalizedString(@"QM_STR_LOGOUT_CONFIRMATION", nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_CANCEL", nil)
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * _Nonnull __unused action) {
                                                          }]];
        
        @weakify(self);
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_LOGOUT", nil)
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * _Nonnull __unused action) {
                                                              
                                                              @strongify(self);
                                                              if (self.logoutTask) {
                                                                  // task is in progress
                                                                  return;
                                                              }
                                                              
                                                              [SVProgressHUD showWithStatus:NSLocalizedString(@"QM_STR_LOADING", nil)];
                                                              [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
                                                
                                                              self.logoutTask = [[[QMCore instance] logout] continueWithBlock:^id _Nullable(BFTask * _Nonnull __unused logoutTask) {
                                                                  
                                                                  [SVProgressHUD dismiss];
                                                                
                                                                  [self performSegueWithIdentifier:kQMSceneSegueAuth sender:nil];
                                                                  return nil;
                                                              }];
                                                          }]];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    [tableView cellForRowAtIndexPath:indexPath].selected = NO;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section {
    
    ////////gumenuk/////////
    return 8;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EditProfile"];
        return cell;
    } else if (indexPath.row == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bar_first"];
        return cell;
    } else if (indexPath.row == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChangeEmail"];
        return cell;
    } else if (indexPath.row == 3) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChangePassword"];
        return cell;
    } else if (indexPath.row == 4) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bar_second"];
        return cell;
    } else if (indexPath.row == 5) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PrivacyPolicy"];
        return cell;
    } else if (indexPath.row == 6) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bar_third"];
        return cell;
    }  else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogOut"];
        return cell;
    }
}

#pragma mark - Private

- (void)loadUser {

    self.user = [QMNetworkManager sharedManager].myProfile;
    [self reloadViewWithUser];
}

- (void)reloadViewWithUser {
    self.username.text = self.user.userName;
    NSURL *avatarUrl = [NSURL URLWithString:self.user.avatarURL];
    
    [self.userAvatar setImageWithURL:avatarUrl placeholder:[UIImage imageNamed:@"default"] options:SDWebImageHighPriority progress:nil completedBlock:nil];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)__unused sender {
    [self.view endEditing:YES];
    
    if ([segue.identifier isEqualToString:kProfileSegue]) {
        
        UINavigationController* navigationController = segue.destinationViewController;
        UserProfileViewController* profileViewController = navigationController.viewControllers.firstObject;
        profileViewController.user = sender;
    }
}

- (IBAction)onBackAction:(id) __unused sender {
    [self.view endEditing:YES];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}
@end
