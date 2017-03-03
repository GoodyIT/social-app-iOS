//
//  TopicCommentModel.h
//  reach-ios
//
//  Created by Admin on 2016-12-30.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TopicCommentModel : NSObject

@property (strong, nonatomic)   NSNumber *topicCommentID;
@property (copy, nonatomic)     NSString *text;
@property (strong, nonatomic)   UserModel *author;
@property (copy, nonatomic)     NSString *date;
@property (strong, nonatomic)   NSNumber *rate;
@property (strong, nonatomic)   NSNumber *isUpvoted;
@property (strong, nonatomic)   NSNumber *isDownvoted;
@property (strong, nonatomic)   NSNumber *permission;

+ (CommentModel *)getTopicCommentFromDictionary:(NSDictionary *)dictionary;
+ (NSArray *)getTopicCommentsListFromResponse:(NSDictionary *)response;

@end
