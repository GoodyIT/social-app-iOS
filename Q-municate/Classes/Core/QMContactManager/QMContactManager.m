//
//  QMContactManager.m
//  Q-municate
//
//  Created by Vitaliy Gorbachov on 3/25/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMContactManager.h"
#import "QMCore.h"
#import "QMNotification.h"
#import "QMMessagesHelper.h"
#import <QMDateUtils.h>
#import "QMContactsDataSource.h"

@interface QMContactManager ()

@property (weak, nonatomic) QMCore <QMServiceManagerProtocol>*serviceManager;

@end

@implementation QMContactManager

@dynamic serviceManager;

#pragma mark - Contacts management

- (BFTask *)addUserToContactList:(QBUUser *)user {
    
    // determine whether we have already received contact request from user or not
    QBChatDialog *chatDialog = [self.serviceManager.chatService.dialogsMemoryStorage privateChatDialogWithOpponentID:user.ID];
    QBChatMessage *lastMessage = [self.serviceManager.chatService.messagesMemoryStorage lastMessageFromDialogID:chatDialog.ID];
    
    QBContactListItem *contactListItem = [self.serviceManager.contactListService.contactListMemoryStorage contactListItemWithUserID:user.ID];
    
    if (lastMessage.messageType == QMMessageTypeContactRequest
        && lastMessage.senderID != self.serviceManager.currentProfile.userData.ID
        && (contactListItem == nil || contactListItem.subscriptionState != QBPresenceSubscriptionStateBoth)) {
        
        return [self confirmAddContactRequest:user];
    }
    else {
        
        @weakify(self);
        return [[[self.serviceManager.contactListService addUserToContactListRequest:user] continueWithSuccessBlock:^id _Nullable(BFTask * _Nonnull __unused task) {
            
            @strongify(self);
            return [self.serviceManager.chatService createPrivateChatDialogWithOpponent:user];
            
        }] continueWithSuccessBlock:^id _Nullable(BFTask<QBChatDialog *> * _Nonnull task) {
            
            @strongify(self);
            QBChatMessage *chatMessage = [QMMessagesHelper contactRequestNotificationForUser:user];
            [self.serviceManager.chatService sendMessage:chatMessage
                                                    type:chatMessage.messageType
                                                toDialog:task.result
                                           saveToHistory:YES
                                           saveToStorage:YES
                                              completion:nil];
            
            NSString *notificationMessage = [NSString stringWithFormat:@"%@ sent you a contact request", self.serviceManager.currentProfile.userData.fullName];
            
            [QMNotification sendPushNotificationToUser:user withText:notificationMessage];
            
            return nil;
        }];
    }
}

- (BFTask *)confirmAddContactRequest:(QBUUser *)user {
    
    QBContactListItem *contactListItem = [[QMCore instance].contactListService.contactListMemoryStorage contactListItemWithUserID:user.ID];
    if (!contactListItem.isOnline) {
        NSString *notificationMessage = [NSString stringWithFormat:@"%@ accepted your request", self.serviceManager.currentProfile.userData.fullName];
        
        [QMNotification sendPushNotificationToUser:user withText:notificationMessage];
    }
    
    @weakify(self);
    return [[[QMNetworkManager sharedManager] addUserToContacts:[NSNumber numberWithInteger:[[QBSession currentSession].currentUser.login integerValue]] otherUserID :[NSNumber numberWithInteger:[user.login integerValue]]] continueWithBlock:^id _Nullable(BFTask * _Nonnull __unused t1) {
        return [[[self.serviceManager.contactListService acceptContactRequest:user.ID] continueWithSuccessBlock:^id _Nullable(BFTask * _Nonnull __unused task) {
            return task;
        }] continueWithBlock:^id _Nullable(BFTask * __unused _Nonnull t) {
            @strongify(self);
            
            return [self.serviceManager.chatService sendMessageAboutAcceptingContactRequest:YES toOpponentID:user.ID];
            
        }];
    }];
    
}

- (BFTask *)rejectAddContactRequest:(QBUUser *)user {
    
    QBContactListItem *contactListItem = [[QMCore instance].contactListService.contactListMemoryStorage contactListItemWithUserID:user.ID];
    if (!contactListItem.isOnline) {
        NSString *notificationMessage = [NSString stringWithFormat:@"%@ rejected your request", self.serviceManager.currentProfile.userData.fullName];
        
        [QMNotification sendPushNotificationToUser:user withText:notificationMessage];
    }
    
    @weakify(self);
    return [[self.serviceManager.contactListService rejectContactRequest:user.ID] continueWithSuccessBlock:^id _Nullable(BFTask * _Nonnull __unused task) {
        @strongify(self);
        return [self.serviceManager.chatService sendMessageAboutAcceptingContactRequest:NO toOpponentID:user.ID];
    }];

}

- (BFTask *)removeUserFromContactList:(QBUUser *)user {
    
    QBContactListItem *contactListItem = [[QMCore instance].contactListService.contactListMemoryStorage contactListItemWithUserID:user.ID];
    if (!contactListItem.isOnline) {
        NSString *notificationMessage = [NSString stringWithFormat:@"%@ removed you from his contact", self.serviceManager.currentProfile.userData.fullName];
        
        [QMNotification sendPushNotificationToUser:user withText:notificationMessage];
    }

    
    __block QBChatDialog *chatDialog = nil;
    
    @weakify(self);
    return [[[QMNetworkManager sharedManager]  removeUserFromContacts: [NSNumber numberWithInteger:[[QBSession currentSession].currentUser.login integerValue]] otherUserID:[NSNumber numberWithInteger:[user.login integerValue]]] continueWithBlock:^id _Nullable(BFTask * _Nonnull __unused t1) {
        return [[[[self.serviceManager.contactListService removeUserFromContactListWithUserID:user.ID] continueWithSuccessBlock:^id _Nullable(BFTask * _Nonnull __unused task) {
            
            @strongify(self);
            return [self.serviceManager.chatService createPrivateChatDialogWithOpponent:user];
        }] continueWithSuccessBlock:^id _Nullable(BFTask<QBChatDialog *> * _Nonnull t2) {
            
            chatDialog = t2.result;
            QBChatMessage *notificationMessage = [QMMessagesHelper removeContactNotificationForUser:user];
            
            return [self.serviceManager.chatService sendMessage:notificationMessage
                                                           type:notificationMessage.messageType
                                                       toDialog:chatDialog
                                                  saveToHistory:YES
                                                  saveToStorage:NO];
            
        }] continueWithBlock:^id _Nullable(BFTask * __unused _Nonnull t3) {
            return [self.serviceManager.chatService deleteDialogWithID:chatDialog.ID];
        }];
    }];
    
}

#pragma mark - Users

- (NSString *)fullNameForUserID:(NSUInteger)userID {
    
    QBUUser *user = [self.serviceManager.usersService.usersMemoryStorage userWithID:userID];
    
    NSString *fullName = user.fullName ?: [NSString stringWithFormat:@"%tu", userID];
    
    return fullName;
}

- (NSArray *)allContacts {
    
    NSArray *ids = [self.serviceManager.contactListService.contactListMemoryStorage userIDsFromContactList];
    NSArray *allContacts = [self.serviceManager.usersService.usersMemoryStorage usersWithIDs:ids];
    
    return allContacts;
}

- (NSArray *)allContactsSortedByFullName {
    
    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@keypath(QBUUser.new, fullName)
                                                           ascending:YES
                                                            selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortedUsers = [[self allContacts] sortedArrayUsingDescriptors:@[sorter]];
    
    return sortedUsers;
}

- (NSArray *)friends {
    
    NSArray *allContactListItems = [self.serviceManager.contactListService.contactListMemoryStorage allContactListItems];
    NSMutableArray *friends = [NSMutableArray arrayWithCapacity:allContactListItems.count];
    
    for (QBContactListItem *item in allContactListItems) {
        
        if (item.subscriptionState != QBPresenceSubscriptionStateNone) {
            
            QBUUser *user = [self.serviceManager.usersService.usersMemoryStorage userWithID:item.userID];
            if (user) {
                
                [friends addObject:user];
            }
        }
    }
    
    return [friends copy];
}

- (NSArray *)friendsByExcludingUsersWithIDs:(NSArray *)userIDs {
    
    NSArray *friends = [self friends];
    NSMutableArray *mutableUsers = [friends mutableCopy];
    
    for (QBUUser *user in friends) {
        
        if ([userIDs containsObject:@(user.ID)]) {
            
            [mutableUsers removeObject:user];
        }
    }
    
    return [mutableUsers copy];
}

- (NSArray *)idsOfUsers:(NSArray *)users {
    
    NSMutableArray *ids = [NSMutableArray arrayWithCapacity:users.count];
    
    for (QBUUser *user in users) {
        
        [ids addObject:@(user.ID)];
    }
    
    return [ids copy];
}

- (NSArray *)occupantsWithoutCurrentUser:(NSArray *)occupantIDs {
    
    NSMutableArray *occupantsWithoutCurrentUser = [occupantIDs mutableCopy];
    
    [occupantsWithoutCurrentUser removeObject:@(self.serviceManager.currentProfile.userData.ID)];
    
    return [occupantsWithoutCurrentUser copy];
}

- (NSString *)onlineStatusForUser:(QBUUser *)user {
    
    QBContactListItem *contactListItem = [self.serviceManager.contactListService.contactListMemoryStorage contactListItemWithUserID:user.ID];
    NSString *status = nil;
    
    if (user.ID == self.serviceManager.currentProfile.userData.ID || contactListItem.isOnline) {
        
        status = NSLocalizedString(@"QM_STR_ONLINE", nil);
    }
    else {
        
        if (user.lastRequestAt) {
            
            status = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"QM_STR_LAST_SEEN", nil), [QMDateUtils formattedLastSeenString:user.lastRequestAt withTimePrefix:NSLocalizedString(@"QM_STR_TIME_PREFIX", nil)]];
        }
        else {
            
            status = NSLocalizedString(@"QM_STR_OFFLINE", nil);
        }
    }
    
    return status;
}

#pragma mark - States

- (BOOL)isFriendWithUserID:(NSUInteger)userID {
    
    if (userID == self.serviceManager.currentProfile.userData.ID) {
        NSLog(@"self.serviceManager %lu", (unsigned long)self.serviceManager.currentProfile.userData.ID);
        return YES;
    }
    
    QBContactListItem *contactListItem = [self.serviceManager.contactListService.contactListMemoryStorage contactListItemWithUserID:userID];
    
    return contactListItem != nil && contactListItem.subscriptionState == QBPresenceSubscriptionStateNone;
}

- (BOOL)isCustomFriendWithUserID:(NSUInteger)userID {
    
    if (userID == [QBSession currentSession].currentUser.ID) {
        return YES;
    }
    
    NSArray *friends = [[QMNetworkManager sharedManager] getContacts];
    
    for (QBUUser* myFriend in friends) {
        if (myFriend.ID == userID) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)isContactListItemExistentForUserWithID:(NSUInteger)userID {
    
    QBContactListItem *contactListItem = [self.serviceManager.contactListService.contactListMemoryStorage contactListItemWithUserID:userID];
    
    return contactListItem != nil;
}

- (BOOL)isUserOnlineWithID:(NSUInteger)userID {
    
    QBContactListItem *item = [self.serviceManager.contactListService.contactListMemoryStorage contactListItemWithUserID:userID];
    
    return item.isOnline;
}

@end
