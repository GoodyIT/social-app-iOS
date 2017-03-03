//
//  UserModel.m
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import "UserModel.h"

@implementation UserModel
@synthesize email;

+ (UserModel *)getUserWithResponce:(NSDictionary * _Nullable)responce {
    UserModel *user = [UserModel new];
    
    user.email = [responce valueForKey:@"email"];
    user.firstName = [responce valueForKey:@"first_name"];
    user.userId = [responce valueForKey:@"id"];
    user.lastName = [responce valueForKey:@"last_name"];
    user.userName = [responce valueForKey:@"username"];
    NSDictionary *info = [responce valueForKey:@"info"];
    user.biography = [info valueForKey:@"biography"];
    user.fullName = [info valueForKey:@"full_name"];
    user.commentCount = [info valueForKey:@"comment_count"];
    user.likeCount = [info valueForKey:@"like_count"];
    user.rate = [info valueForKey:@"rate"];
    user.avatarURL = [info valueForKey:@"avatar"];
    user.downvotedCount = [responce valueForKey:@"count_downvoted"];
    user.upvotedCount = [responce valueForKey:@"count_upvoted"];
    user.editProfileCommentsCount = [responce valueForKey:@"count_comments"];
    user.editProfileLikesCount = [responce valueForKey:@"count_likes"];
    user.profilePercentage = [responce valueForKey:@"complete_likes"];
    user.isFacebook = [info valueForKey:@"is_facebook"];
    user.isInstagram = [info valueForKey:@"is_instagram"];
    user.isTwitter = [info valueForKey:@"is_twitter"];
    user.facebookURL = [info valueForKey:@"facebook_url"];
    user.twitterURl = [info valueForKey:@"twitter_url"];
    user.instagramURL = [info valueForKey:@"instagram_url"];
    user.countryName = [info valueForKey:@"country_name"];
    user.cityName = [info valueForKey:@"city_name"];
    user.qbChatID = [info valueForKey:@"qbchat_id"];
    
    if([[info valueForKey:@"latitude"] isEqual:[NSNull null]]) {
        user.latitude = -90;
    } else {
        user.latitude = [[info valueForKey:@"latitude"] floatValue];
    }
    if([[info valueForKey:@"longitude"] isEqual:[NSNull null]]) {
        user.longitude = -90;
    } else {
        user.longitude = [[info valueForKey:@"longitude"] floatValue];
    }

    return user;
}

@end
