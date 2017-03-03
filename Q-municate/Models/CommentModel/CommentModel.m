//
//  CommentModel.m
//  Reach-iOS
//
//  Created by AlexFill on 21.01.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "CommentModel.h"

@implementation CommentModel

+ (CommentModel *)getCommentFromDictionary:(NSDictionary *)dictionary {
    CommentModel *comment = [CommentModel new];
    
    comment.commentID = [dictionary valueForKey:@"id"];
    comment.text = [dictionary valueForKey:@"text"];
    comment.author = [UserModel getUserWithResponce:[dictionary valueForKey:@"author"]];
    comment.date = [dictionary valueForKey:@"date"];
    comment.rate = [dictionary valueForKey:@"rate"];
    comment.isUpvoted = [dictionary valueForKey:@"is_upvoted"];
    comment.isDownvoted = [dictionary valueForKey:@"is_downvoted"];
    comment.permission = [dictionary valueForKey:@"permission"];
    
    return comment;
}

+ (NSArray *)getCommentsListFromResponse:(NSDictionary *)response {
    NSMutableArray *comments = [[NSMutableArray alloc] init];
    
    for (NSDictionary *comment in response) {
        [comments addObject:[CommentModel getCommentFromDictionary:comment]];
    }
    
    return comments;
}

@end
