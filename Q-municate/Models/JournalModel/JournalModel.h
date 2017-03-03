//
//  JournalModel.h
//  Reach-iOS
//
//  Created by VICTOR on 9/12/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JournalModel : NSObject
@property(assign, nonatomic) NSInteger tblID;
@property(strong, nonatomic) NSString *title;
@property(strong, nonatomic) NSString *time;
@property(strong, nonatomic) NSString *content;

- (void)initData:(NSDictionary *)data;
@end
