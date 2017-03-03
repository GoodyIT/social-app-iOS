//
//  CircleModel.m
//  Reach-iOS
//
//  Created by AlexFill on 29.01.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "GroupModel.h"

@implementation GroupModel

+ (GroupModel *)getGroupFromResponse:(NSDictionary *)response {
    GroupModel *group = [GroupModel new];
    
    group.groupID = [response valueForKey:@"id"];
    group.name = [response valueForKey:@"name"];
    group.owner = [UserModel getUserWithResponce:[response valueForKey:@"owner"]];
    group.groupDescription = [response valueForKey:@"description"];
    group.imageURL = [response valueForKey:@"image"];
    group.category = [CategoryModel getCategoryFromResponse:[response valueForKey:@"group"]];
    group.memberCount = [response valueForKey:@"members_count"];
    group.members = [response valueForKey:@"members"];
    group.joined = [response valueForKey:@"join"];
    group.topics = [[TopicModel getTopicListFromResponse:[response valueForKey:@"topics"]] mutableCopy];
    group.permission = [response valueForKey:@"permission"];

    return group;
}

+ (NSArray *)getGroupsListFromResponse:(NSDictionary *)response {
    NSMutableArray *groups = [[NSMutableArray alloc] init];
    
    for (NSDictionary *groupDictionary in response) {
        [groups addObject:[GroupModel getGroupFromResponse:groupDictionary]];
    }
    
    return groups;
}

@end
