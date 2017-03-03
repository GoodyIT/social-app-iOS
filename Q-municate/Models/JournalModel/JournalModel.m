//
//  JournalModel.m
//  Reach-iOS
//
//  Created by VICTOR on 9/12/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "JournalModel.h"

@implementation JournalModel
@synthesize tblID;
@synthesize title;
@synthesize time;
@synthesize content;
- (id)init {
    if(self != nil) {
        self.title = @"";
        self.time = [self getCurrentDate];
        self.content = @"";
    }
    return self;
}

- (void)initData:(NSDictionary *)data {
    tblID = [data[@"id"] integerValue];
    title = [data objectForKey:@"title"];
    time = [data objectForKey:@"time"];
    content = [data objectForKey:@"content"];
}

- (NSString *)getCurrentDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MM/dd/yy";
    NSString *result = [formatter stringFromDate:[NSDate date]];
    return result;
}
@end
