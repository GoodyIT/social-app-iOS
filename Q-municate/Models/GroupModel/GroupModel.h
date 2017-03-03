//
//  CircleModel.h
//  Reach-iOS
//
//  Created by AlexFill on 29.01.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserModel.h"
#import "TopicModel.h"
#import "CategoryModel.h"

@interface GroupModel : NSObject

@property (strong, nonatomic) NSNumber *groupID;
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) UserModel *owner;
@property (copy, nonatomic) NSString *groupDescription;
@property (copy, nonatomic) NSString *imageURL;
@property (strong, nonatomic) NSNumber *memberCount;
@property (strong, nonatomic) NSArray *members;
@property (strong, nonatomic) NSNumber *joined;
@property (copy, nonatomic) NSMutableArray *topics;
@property (strong, nonatomic) CategoryModel *category;
@property (strong, nonatomic) NSNumber *permission;


+ (GroupModel *)getGroupFromResponse:(NSDictionary *)response;
+ (NSArray *)getGroupsListFromResponse:(NSDictionary *)response;

@end
