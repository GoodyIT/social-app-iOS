//
//  TopicModel.h
//  Reach-iOS
//
//  Created by AlexFill on 02.02.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserModel.h"

@interface TopicModel : NSObject

@property (strong, nonatomic) NSNumber *topicID;
@property (copy, nonatomic) NSString *topicText;
@property (copy, nonatomic) NSString *date;
@property (strong, nonatomic) NSNumber *permission;
@property (strong, nonatomic) UserModel *author;

@property (strong, nonatomic) NSArray *replies;

//permission:true - public

+ (TopicModel *)getTopicFromResponse:(NSDictionary *)response;
+ (NSArray *)getTopicListFromResponse:(NSDictionary *)response;

@end
