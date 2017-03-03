//
//  DBGlobalManager.h
//  GRL
//
//  Created by VICTOR on 5/24/16.
//  Copyright © 2016 Wangu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLiteManager.h"
#import "UserModel.h"

@interface DBGlobalManager : NSObject
+(DBGlobalManager *)getSharedInstance;

- (BOOL)createDB;
- (NSString *)getJournalTableName;
- (BOOL)createTable:(NSString *)tableName;
- (BOOL)dropTable:(NSString *)tableName;
- (NSInteger)insertData:(NSString *)tableName data:(NSObject *)data;
- (BOOL)updateData:(NSString *)tableName data:(NSObject *)data;
- (NSArray *)getData:(NSString *)tableName keys:(NSDictionary *)keys;
- (NSArray *)getAllData:(NSString *)tableName;
- (BOOL)deleteRecord:(NSString *)tableName tableID:(int)table_id ;
@end
