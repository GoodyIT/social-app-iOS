//
//  NSError+Network.m
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import "NSError+Network.h"

@implementation NSError (Network)

+ (NSString *)errorLocalizedDescriptionForCode:(NSInteger)errorCode {
    NSDictionary *codes = @{
                            @"1" : @"registration successfully",
                            @"2" : @"user with this username is already exist",
                            @"3" : @"username is less than 4 symbols",
                            @"4" : @"username is more than 20 symbols",
                            @"5" : @"username contain space(s)",
                            @"6" : @"username contain special character(s)",
                            @"7" : @"user with this email is already exist",
                            @"8" : @"email is not in format like qwe@qwe.qwe",
                            @"9" : @"password is less than 6 symbols",
                            @"10" : @"password is more than 20 symbols",
                            @"11" : @"password contain space(s)",
                            @"12" : @"login successfully",
                            @"13" : @"user with this email doesn't exist",
                            @"14" : @"incorrect password",
                            @"15" : @"recover password successfully",
                            @"16" : @"user with this email doesn't exist",
                            @"17" : @"token doesn't exist",
                            @"18" : @"user_id is not integer",
                            @"19" : @"user with this id doesn't exist",
                            @"20" : @"getting user successfully",
                            @"21" : @"post text is less than 10 symbols",
                            @"22" : @"post text is more than 255 symbols",
                            @"23" : @"successfully add new post",
                            @"24" : @"comment text is less that 10 symbols",
                            @"25" : @"comment text is more that 255 symbols",
                            @"26" : @"successfully add new comment",
                            @"27" : @"post with this post_id doesn't exist",
                            @"29" : @"successfully get user posts",
                            @"30" : @"successfully send like",
                            @"31" : @"you already like this post",
                            @"32" : @"post with that ID doesn't exist",
                            @"33" : @"successfully remove like",
                            @"34" : @"you haven't like this post yet",
                            @"35" : @"comment with that ID doesn't exist",
                            @"36" : @"this is not your comment, can't remove",
                            @"37" : @"successfully remove comment",
                            @"38" : @"successfully send like/dislike to this comment",
                            @"39" : @"you already like/dislike this comment",
                            @"40" : @"you successfully change the best_response status",
                            @"41" : @"you don't have permissions to mark comment as best response",
                            @"42" : @"circle name must be more than 4 symbols",
                            @"43" : @"circle name must be less than 50 symbols",
                            @"44" : @"circle description must be more that 4 symbols",
                            @"45" : @"circle description must be less than 500 symbols",
                            @"46" : @"circle with that name is already exist",
                            @"47" : @"successfully create a new circle",
                            @"48" : @"successfully get all circles",
                            @"49" : @"successfully get all created circles",
                            @"50" : @"successfully get all joined circles",
                            @"51" : @"circle with that id doesn't exist",
                            @"52" : @"successfully get single circle",
                            @"53" : @"You are not member of the circle",
                            @"54" : @"successfully join circle",
                            @"55" : @"successfully created a new topic in circle",
                            @"56" : @"successfully get single topic",
                            @"57" : @"topic with that id doesn't exist",
                            @"58" : @"successfully get all groups",
                            @"59" : @"group with that id doesn't exist",
                            @"79" : @"request does not exist"
                            };
    
    return [codes valueForKey:[NSString stringWithFormat:@"%ld", (long)errorCode]];
}

@end
