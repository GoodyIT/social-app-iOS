//
//  QMDialogsDataSource.m
//  Q-municate
//
//  Created by Vitaliy Gorbachov on 1/13/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMRequestsDataSource.h"
#import "QMDialogCell.h"
#import "QMCore.h"
#import <QMDateUtils.h>
#import "QBChatDialog+OpponentID.h"
#import "QBChatMessage+QMCallNotifications.h"

#import <SVProgressHUD.h>

@implementation QMRequestsDataSource

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)__unused indexPath {
    
    return [QMDialogCell height];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    QMDialogCell *cell = [tableView dequeueReusableCellWithIdentifier:[QMDialogCell cellIdentifier] forIndexPath:indexPath];
    QBChatDialog *chatDialog = self.items[indexPath.row];
    
    if (chatDialog.type == QBChatDialogTypePrivate) {
        cell.avatarImage.tag = indexPath.row;
        
        UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewClick:)];
        tapped.numberOfTapsRequired = 1;
        [cell.avatarImage addGestureRecognizer:tapped];
        
        QBUUser *recipient = [[QMCore instance].usersService.usersMemoryStorage userWithID:[chatDialog opponentID]];
        
        if (recipient.fullName != nil) {
            
            [cell setTitle:recipient.fullName placeholderID:[chatDialog opponentID] avatarUrl:recipient.avatarUrl];
        }
        else {
            
            [cell setTitle:NSLocalizedString(@"QM_STR_UNKNOWN_USER", nil) placeholderID:[chatDialog opponentID] avatarUrl:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"fetchAllDialog" object:nil];
    } else {
        
        [cell setTitle:chatDialog.name placeholderID:chatDialog.ID.hash avatarUrl:chatDialog.photo];
    }
    
    // there was a time when updated at didn't exist
    // in order to support old dialogs, showing their date as last message date
    NSDate *date = chatDialog.updatedAt ?: chatDialog.lastMessageDate;
    
    NSString *time = [QMDateUtils formattedShortDateString:date];
    [cell setTime:time];
    [cell setBody:chatDialog.lastMessageText];
    [cell setBadgeNumber:chatDialog.unreadMessagesCount];
    
    return cell;
}

-(void)imageViewClick :(id) sender
 {
    UITapGestureRecognizer *gesture = (UITapGestureRecognizer *) sender;
    [self.delegate imageviewTapped:gesture.view.tag];
 }

- (BOOL)tableView:(UITableView *)__unused tableView canEditRowAtIndexPath:(NSIndexPath *)__unused indexPath {
    
    return NO;
}

- (void)tableView:(UITableView *)__unused tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        QBChatDialog *chatDialog = self.items[indexPath.row];
        [self.delegate dialogsDataSource:self commitDeleteDialog:chatDialog];
    }
}


- (NSMutableArray *)items {
    return [self getRequets:[[[QMCore instance].chatService.dialogsMemoryStorage dialogsSortByLastMessageDateWithAscending:NO] mutableCopy]];
}

- (NSMutableArray*) getRequets: (NSMutableArray*) dialogs
{
    NSMutableArray* requests = [NSMutableArray new];
    for (QBChatDialog *temp in dialogs) {
        if ([temp.lastMessageText containsString:@"Contact"])
        {
            // Retrieving message from Quickblox REST history and cache.
            NSArray* messages =  (NSArray*)[[QMCore instance].chatService.messagesMemoryStorage messagesWithDialogID:temp.ID];
                
                QBChatMessage *message = messages.lastObject;
                if  (message.messageType == QMMessageTypeAcceptContactRequest)
                {
                    temp.lastMessageText = @"Contact Request Accpeted";
                } else if (message.messageType == QMMessageTypeRejectContactRequest)
                {
                    temp.lastMessageText = @"Contact Request Rejected";
                } else if (message.messageType == QMMessageTypeDeleteContactRequest) {
                    temp.lastMessageText = @"Your Contact Deleted";
                } else if (message.senderID == [QMCore instance].currentProfile.userData.ID) {
                    temp.lastMessageText = @"Contact Request Sent";
                }

            [requests addObject:temp];
            
        }
    }
    
    return requests;
}

@end
