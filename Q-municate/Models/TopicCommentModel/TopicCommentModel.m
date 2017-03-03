//
//  TopicCommentModel.m
//  reach-ios
//
//  Created by Admin on 2016-12-30.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "TopicCommentModel.h"

@implementation TopicCommentModel

+ (TopicCommentModel *)getTopicCommentFromDictionary:(NSDictionary *)dictionary {
    TopicCommentModel *comment = [TopicCommentModel new];
    
    comment.topicCommentID = [dictionary valueForKey:@"id"];
    comment.text = [dictionary valueForKey:@"text"];
    comment.author = [UserModel getUserWithResponce:[dictionary valueForKey:@"author"]];
    comment.date = [dictionary valueForKey:@"date"];
    comment.rate = [dictionary valueForKey:@"rate"];
    comment.isUpvoted = [dictionary valueForKey:@"is_upvoted"];
    comment.isDownvoted = [dictionary valueForKey:@"is_downvoted"];
    comment.permission = [dictionary valueForKey:@"permission"];
    
    return comment;
}

+ (NSArray *)getTopicCommentsListFromResponse:(NSDictionary *)response {
    NSMutableArray *comments = [[NSMutableArray alloc] init];
    
    for (NSDictionary *comment in response) {
        [comments addObject:[CommentModel getCommentFromDictionary:comment]];
    }
    
    return comments;
}

@end
