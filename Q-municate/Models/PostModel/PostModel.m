//
//  PostModel.m
//  Reach-iOS
//
//  Created by AlexFill on 21.01.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "PostModel.h"
#import "HashtagModel.h"
#import "CommentModel.h"

@implementation PostModel

+ (NSArray *)getPostListFromResponse:(NSDictionary *)response {
    NSMutableArray *posts = [[NSMutableArray alloc] init];
    
    if ([(NSArray*)[response valueForKey:@"post"] count] > 0) {
    
        for (NSDictionary *postDictionary in [response valueForKey:@"post"]) {
            [posts addObject:[PostModel getPostInfoFromResponse:postDictionary]];
        }
    } else {
        for (NSDictionary *postDictionary in [response valueForKey:@"posts"]) {
            [posts addObject:[PostModel getPostInfoFromResponse:postDictionary]];
        }
    }
    
    return posts;
}

+ (PostModel *)getPostInfoFromResponse:(NSDictionary *)response {
    
    
    PostModel *post = [PostModel new];
    post.postID = [response valueForKey:@"id"];
    post.isLiked = [response valueForKey:@"is_like"];
    post.text = [response valueForKey:@"text"];
    post.likesCount = [response valueForKey:@"like_count"];
    post.commentCount = [response valueForKey:@"comment_count"];
    post.date = [response valueForKey:@"date"];
    post.author = [UserModel getUserWithResponce:[response valueForKey:@"author"]];
    
    post.image = [response valueForKey:@"image"];
    post.video = [response valueForKey:@"video"];
    post.permission = [response valueForKey:@"permission"];
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    for (NSDictionary *hashtagDictionary in [response valueForKey:@"post_hashtags"]) {
        [tempArray addObject:[HashtagModel getHashtagFromDictionary:hashtagDictionary]];
    }
    
    post.hashtags = [tempArray mutableCopy];
    
    [tempArray removeAllObjects];
    
    for (NSDictionary *commentDictionary in [response valueForKey:@"post_comments"]) {
        [tempArray addObject:[CommentModel getCommentFromDictionary:commentDictionary]];
    }
    
    post.comments = [tempArray mutableCopy];
    
    return post;
}

@end
