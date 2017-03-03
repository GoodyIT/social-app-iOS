//
//  QMTabBarVC.m
//  Q-municate
//
//  Created by Vitaliy Gorbachov on 5/17/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMTabBarVC.h"
#import "QMNotification.h"
#import "QMCore.h"
#import "QMChatVC.h"
#import "QMSoundManager.h"
#import "QBChatDialog+OpponentID.h"
#import "QMHelpers.h"
#import "QMRequestViewController.h"
#import "QMDialogsViewController.h"
#import "GroupDetailViewController.h"

@interface QMTabBarVC ()

<
UITabBarControllerDelegate,

QMChatServiceDelegate,
QMChatConnectionDelegate,

ReachServiceDelegate
>

@end

@implementation QMTabBarVC

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // subscribing for delegates
    UIImage *NavigationPortraitBackground = [[UIImage imageNamed:@"background"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch];
    [[UINavigationBar appearance] setBackgroundImage:NavigationPortraitBackground forBarMetrics:UIBarMetricsDefault];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateBadge) name:@"fetchAllDialog" object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[QMCore instance].chatService addDelegate:self];
    [[PushManager instance] addDelegate:self];
    [self.navigationController setNavigationBarHidden:YES];
    
    [self updateBadge];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[QMCore instance].chatService removeDelegate:self];
    [[PushManager instance] removeDelegate:self];
}


#pragma mark - News Feed & Group Notification

- (void) didRecieveReachPushNotification:(PushManager *)__unused manager ID:(NSNumber*)ID title:(NSString *)title message:(NSString *)messageText avatar:(NSString *)avatar
{
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
            
//            if (buttonIndex == 1) {
                UINavigationController *navigationController = self.viewControllers.firstObject;
                UIViewController *dialogsVC = navigationController.viewControllers.firstObject;
                [dialogsVC performSegueWithIdentifier:kQMSceneSegueChat sender:chatDialog];
//            }
        };
    }
    
    [QMNotification showMessageNotificationWithMessage:chatMessage buttonHandler:buttonHandler hostViewController:hvc];
}

#pragma mark - QMChatServiceDelegate

- (void)chatService:(QMChatService *)chatService didAddMessageToMemoryStorage:(QBChatMessage *)message forDialogID:(NSString *)dialogID {
    
    [self updateBadge];
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

#pragma mark - badge

- (void) updateBadge
{
    NSArray* unreadDialogs = [[[QMCore instance].chatService.dialogsMemoryStorage unreadDialogs] mutableCopy];
    NSUInteger dialogBadges = 0;
    NSUInteger requestBadges = 0;
    
    for (QBChatDialog*  dialog in unreadDialogs) {
        if (![dialog.lastMessageText containsString:@"Contact"])
        {
            dialogBadges += dialog.unreadMessagesCount;
        } else {
            requestBadges += dialog.unreadMessagesCount;
        }
    }
    
    QMDialogsViewController *dialogViewController = (QMDialogsViewController *)[self.childViewControllers objectAtIndex:0];
    QMRequestViewController *requestViewController = (QMRequestViewController*) [self.childViewControllers objectAtIndex:2];
    
    if (requestBadges == 0)
    {
        requestViewController.tabBarItem.badgeValue = nil;
    } else {
        requestViewController.tabBarItem.badgeValue =  [NSString stringWithFormat:@"%ld", (long)requestBadges];
    }
    
    if (dialogBadges == 0) {
        dialogViewController.tabBarItem.badgeValue = nil;
    } else {
        dialogViewController.tabBarItem.badgeValue =  [NSString stringWithFormat:@"%ld", (long)dialogBadges];
    }
    
    [DataManager sharedManager].chatDialogBadge = dialogBadges;
    [DataManager sharedManager].chatContactBadge = requestBadges;
}

@end
