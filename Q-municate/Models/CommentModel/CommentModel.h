//
//  CommentModel.h
//  Reach-iOS
//
//  Created by AlexFill on 21.01.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserModel.h"

@interface CommentModel : NSObject

@property (strong, nonatomic)   NSNumber *commentID;
@property (copy, nonatomic)     NSString *text;
@property (strong, nonatomic)   UserModel *author;
@property (copy, nonatomic)     NSString *date;
@property (strong, nonatomic)   NSNumber *rate;
@property (strong, nonatomic)   NSNumber *isUpvoted;
@property (strong, nonatomic)   NSNumber *isDownvoted;
@property (strong, nonatomic)   NSNumber *permission;

+ (CommentModel *)getCommentFromDictionary:(NSDictionary *)dictionary;
+ (NSArray *)getCommentsListFromResponse:(NSDictionary *)response;

@end
