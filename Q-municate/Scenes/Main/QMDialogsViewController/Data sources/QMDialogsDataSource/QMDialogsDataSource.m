//
//  QMDialogsDataSource.m
//  Q-municate
//
//  Created by Vitaliy Gorbachov on 1/13/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMDialogsDataSource.h"
#import "QMDialogCell.h"
#import "QMCore.h"
#import <QMDateUtils.h>
#import "QBChatDialog+OpponentID.h"

#import <SVProgressHUD.h>

@implementation QMDialogsDataSource

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
    
    return YES;
}

- (void)tableView:(UITableView *)__unused tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        QBChatDialog *chatDialog = self.items[indexPath.row];
        [self.delegate dialogsDataSource:self commitDeleteDialog:chatDialog];
    }
}

- (NSMutableArray *)items {
    return [self getDialogsOnly:[[[QMCore instance].chatService.dialogsMemoryStorage dialogsSortByLastMessageDateWithAscending:NO] mutableCopy]];
}

- (NSMutableArray*) getDialogsOnly: (NSMutableArray*) dialogs
{
    NSMutableArray* requests = [NSMutableArray new];
    for (QBChatDialog *temp in dialogs) {
        if (![temp.lastMessageText containsString:@"Contact"])
        {
            [requests addObject:temp];
        }
    }
    
    return requests;
}

@end
