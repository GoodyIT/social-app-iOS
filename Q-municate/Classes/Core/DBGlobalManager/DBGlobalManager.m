//
//  DBGlobalManager.m
//  GRL
//
//  Created by VICTOR on 5/24/16.
//  Copyright © 2016 Wangu. All rights reserved.
//

#import "DBGlobalManager.h"
#import <AVFoundation/AVFoundation.h>
#import "JournalModel.h"

@implementation DBGlobalManager

SQLiteManager *globaldbManager = nil;
//database Name
NSString *dbName = @"reach-sync.db";
//table Names
NSString *JOURNAL_TBL = @"journal_tbl";
static DBGlobalManager *instance = nil;
+ (DBGlobalManager *)getSharedInstance
{
    @synchronized(self)
    {
        if(instance==nil)
        {
            instance= [DBGlobalManager new];
        }
    }
    
    return instance;
}

- (BOOL)createDB {
    if(globaldbManager == nil) {
        globaldbManager = [[SQLiteManager alloc] initWithDatabaseNamed:dbName];
        [self createTable:[self getJournalTableName]];
    }
    
    return YES;
}

- (NSString *)getJournalTableName {
    return JOURNAL_TBL;
}

- (BOOL)createTable:(NSString *)tableName {
    NSString *createQuery = @"";
    NSError *error;
    if(globaldbManager == nil)
        [self createDB];
    if([tableName isEqualToString:JOURNAL_TBL]) {
        createQuery = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id integer primary key autoincrement, title text, time text, content text)", tableName];
    }
    error = [globaldbManager doQuery:createQuery];
    if(error != nil)
        return NO;
    return YES;
}

- (BOOL)dropTable:(NSString *)tableName {
    NSString *query = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@;", tableName];
    if(globaldbManager == nil)
        return YES;
    [globaldbManager doQuery: query];
    return YES;
}
- (NSInteger)insertData:(NSString *)tableName data:(NSObject *)data {
    NSInteger insertID;
    NSString *query = @"";
    if([tableName isEqualToString:JOURNAL_TBL]) {
        JournalModel *obj = (JournalModel *)data;
        query = [NSString stringWithFormat:@"insert into %@ (title, time, content) values ('%@', '%@', '%@');",tableName, obj.title, obj.time, obj.content];
    }
    insertID = [globaldbManager insertQuery:query];
    if(insertID <= 0)
        return -1;
    return insertID;
}

- (BOOL)updateData:(NSString *)tableName data:(NSObject *)data {
    NSString *query = @"";
    NSString *setStr = @"";
    NSMutableArray *dataArr = [[NSMutableArray alloc] init];
    NSError *error;
    if(data == nil)
        return NO;
    if([tableName isEqualToString:JOURNAL_TBL]) {
        JournalModel *obj = (JournalModel *)data;
        setStr = @"title = ?, time = ?, content = ?";
        dataArr = [[NSMutableArray alloc] initWithObjects:obj.title, obj.time, obj.content, nil];
        query = [NSString stringWithFormat:@"update %@ Set %@ where id = %ld", tableName, setStr, (long)obj.tblID];
    }
    if(globaldbManager == nil)
        [self createDB];
    error = [globaldbManager doUpdateQuery:query withParams:dataArr];
    if(error == nil)
        return YES;
    return NO;
}

- (BOOL)deleteRecord:(NSString *)tableName tableID:(int)table_id {
    NSString *query = @"";
    NSError *error;
    query = [NSString stringWithFormat:@"delete from %@ where id = %ld", tableName, (long)table_id];
    if(globaldbManager == nil)
        [self createDB];
    error = [globaldbManager doQuery:query];
    if(error == nil)
        return YES;
    return NO;
}

- (NSArray *)getData:(NSString *)tableName keys:(NSDictionary *)keys {
    NSArray *result = nil;
    NSString *query = @"";
    NSString *whereas = @"";
    NSArray *keyArray = [keys allKeys];
    if([keyArray count] > 0){
        for (NSUInteger i = 0; i < [keyArray count] - 1; i ++) {
            whereas = [NSString stringWithFormat:@"%@%@ = '%@' and",whereas, keyArray[i], keys[keyArray[i]]];
        }
    }
    if([keyArray count] > 0) {
        whereas = [NSString stringWithFormat:@"%@%@ = '%@'",whereas, keyArray[[keys count] - 1], keys[keyArray[[keys count] - 1]]];
    }
    query = [NSString stringWithFormat:@"Select * from %@ where %@", tableName, whereas];
    if(globaldbManager == nil)
        [self createDB];
    result = [globaldbManager getRowsForQuery:query];
    return result;
}

- (NSArray *)getAllData:(NSString *)tableName {
    NSArray *result = nil;
    NSString *query = [NSString stringWithFormat:@"Select * from %@", tableName];
    if(globaldbManager == nil)
        [self createDB];
    result = [globaldbManager getRowsForQuery:query];
    return result;
}
@end
