//
//  PostModel.h
//  Reach-iOS
//
//  Created by AlexFill on 21.01.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserModel.h"

@interface PostModel : NSObject

@property (strong, nonatomic) NSNumber *postID;
@property (strong, nonatomic) NSNumber *likesCount;
@property (strong, nonatomic) NSNumber *commentCount;
@property (strong, nonatomic) NSNumber *isLiked;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSString *condensedText;
@property (strong, nonatomic) NSString *date;
@property (strong, nonatomic) NSString *image;
@property (strong, nonatomic) NSString *video;
@property (strong, nonatomic) NSArray *hashtags;
@property (strong, nonatomic) NSMutableArray *comments;
@property (strong, nonatomic) NSNumber *permission;
@property (strong, nonatomic) UserModel *author;
@property (nonatomic) BOOL isExpanded;

+ (PostModel *)getPostInfoFromResponse:(NSDictionary *)response;
+ (NSArray *)getPostListFromResponse:(NSDictionary *)response;

@end
