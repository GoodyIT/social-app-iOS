	//
//  CustomTaBBarController.m
//  reach-ios
//
//  Created by Admin on 2017-01-07.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import "CustomTaBBarController.h"
#import "GroupDetailViewController.h"

@interface CustomTaBBarController ()<QMChatServiceDelegate,
QMChatConnectionDelegate, ReachServiceDelegate>


@end

@implementation CustomTaBBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[QMCore instance].chatService addDelegate:self];
    [[PushManager instance] addDelegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[QMCore instance].chatService removeDelegate:self];
    [[PushManager instance] removeDelegate:self];
}

- (void) updateBadge: (BOOL)__unused fromPush
{
    
}

#pragma mark - News Feed & Group Notification

- (void) didRecieveReachPushNotification:(PushManager *)__unused manager ID:(NSNumber*)ID title:(NSString *)title message:(NSString *)messageText avatar:(NSString *)avatar
{
    [self updateBadge:YES];
    
    [QMSoundManager playMessageReceivedSound];
    
    MPGNotificationButtonHandler buttonHandler = nil;
    UIViewController *hvc = nil;
    
    buttonHandler = ^void(MPGNotification * __unused notification, NSInteger __unused buttonIndex) {
        
        if  ([title isEqualToString:@"Post"])
        {
            MyPostDetailViewController* myPostVC = [[UIStoryboard storyboardWithName:@"News" bundle:nil] instantiateViewControllerWithIdentifier:@"MyPostDetailViewController"];
            myPostVC.postID = ID;
            
            [self.navigationController setNavigationBarHidden:NO];
            [self.navigationController pushViewController:myPostVC animated:YES];
        } else {
            GroupDetailViewController* groupDetailVC = [[UIStoryboard storyboardWithName:@"Groups" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupDetailViewController"];
            groupDetailVC.groupID = ID;
            [self.navigationController setNavigationBarHidden:NO];
            [self.navigationController pushViewController:groupDetailVC animated:YES];
        }
    };
    
    [QMNotification showMessageNotificationWithTitle:title message:messageText avatarURL:avatar buttonHandler:buttonHandler hostViewController:hvc];
}

#pragma mark - Notification

- (void)showNotificationForMessage:(QBChatMessage *)chatMessage {
    if (chatMessage.senderID == [QMCore instance].currentProfile.userData.ID) {
        // no need to handle notification for self message
        return;
    }
    
    if (chatMessage.dialogID == nil) {
        // message missing dialog ID
        NSAssert(nil, @"Message should contain dialog ID.");
        return;
    }
    
    if ([[QMCore instance].activeDialogID isEqualToString:chatMessage.dialogID]) {
        // dialog is already on screen
        return;
    }
    
    QBChatDialog *chatDialog = [[QMCore instance].chatService.dialogsMemoryStorage chatDialogWithID:chatMessage.dialogID];
    
    if (chatMessage.delayed && chatDialog.type == QBChatDialogTypePrivate) {
        // no reason to display private delayed messages
        // group chat messages are always considered delayed
        return;
    }
    
    [QMSoundManager playMessageReceivedSound];
    
    MPGNotificationButtonHandler buttonHandler = nil;
    UIViewController *hvc = nil;
    
    BOOL hasActiveCall = [QMCore instance].callManager.hasActiveCall;
    BOOL isiOS8 = iosMajorVersion() < 9;
    
    if (hasActiveCall
        || isiOS8) {
        
        // using hvc if active call or visible keyboard on ios8 devices
        // due to notification triggering window to be hidden
        hvc = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    
    if (!hasActiveCall) {
        // not showing reply button in active call
        buttonHandler = ^void(MPGNotification * __unused notification, NSInteger __unused buttonIndex) {
            
         //   if (buttonIndex == 1) {
//                QMChatVC *chatVC = [QMChatVC chatViewControllerWithChatDialog:chatDialog];
//                [self.navigationController setNavigationBarHidden:NO];
//                [self.navigationController pushViewController:chatVC animated:YES];
                [self performSegueWithIdentifier:@"ChatNavigation" sender:chatDialog];
         //   }
        };
    }
    
    [QMNotification showMessageNotificationWithMessage:chatMessage buttonHandler:buttonHandler hostViewController:hvc];
}

#pragma mark - QMChatServiceDelegate

- (void)chatService:(QMChatService *)chatService didAddMessageToMemoryStorage:(QBChatMessage *)message forDialogID:(NSString *)dialogID {
    
    if (message.messageType == QMMessageTypeContactRequest) {
        
        QBChatDialog *chatDialog = [chatService.dialogsMemoryStorage chatDialogWithID:dialogID];
        [[[QMCore instance].usersService getUserWithID:[chatDialog opponentID]] continueWithSuccessBlock:^id _Nullable(BFTask<QBUUser *> * _Nonnull __unused task) {
            
            [self showNotificationForMessage:message];
            
            return nil;
        }];
    }
    else {
        
        [self showNotificationForMessage:message];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id) __unused sender {
    
    if ([segue.identifier isEqualToString:@"ChatNavigation"]) {
        QMChatVC* chatVC = [(UINavigationController*)segue.destinationViewController viewControllers].firstObject;
        chatVC.chatDialog = sender;
    }
}

@end
