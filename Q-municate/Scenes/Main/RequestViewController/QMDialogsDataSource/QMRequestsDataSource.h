//
//  QMDialogsDataSource.h
//  Q-municate
//
//  Created by Vitaliy Gorbachov on 1/13/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QMTableViewDataSource.h"

@class QMRequestsDataSource;

@protocol QMDialogsDataSourceDelegate <NSObject>

- (void)dialogsDataSource:(QMRequestsDataSource *)dialogsDataSource commitDeleteDialog:(QBChatDialog *)chatDialog;
@optional
-(void)imageviewTapped: (NSInteger) tag;

@end

@interface QMRequestsDataSource : QMTableViewDataSource

@property (weak, nonatomic) id<QMDialogsDataSourceDelegate> delegate;

@end
