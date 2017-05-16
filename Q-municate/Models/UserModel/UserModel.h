//
//  UserModel.h
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserModel : NSObject

@property(copy, nonatomic) NSString * _Nullable email;
@property(copy, nonatomic) NSString * _Nullable firstName;
@property(copy, nonatomic) NSString * _Nullable lastName;
@property(copy, nonatomic) NSString * _Nullable userName;
@property(copy, nonatomic) NSString * _Nullable biography;
@property(copy, nonatomic) NSString * _Nullable fullName;
@property(copy, nonatomic) NSString * _Nullable avatarURL;
@property(strong, nonatomic) NSNumber * _Nullable userId;
@property(strong, nonatomic) NSNumber * _Nullable likeCount;
@property(strong, nonatomic) NSNumber * _Nullable commentCount;
@property(strong, nonatomic) NSNumber *rate;
@property(strong, nonatomic) NSNumber *downvotedCount;
@property (strong, nonatomic) NSNumber *upvotedCount;
@property (strong, nonatomic) NSNumber *editProfileCommentsCount;
@property (strong, nonatomic) NSNumber *editProfileLikesCount;
@property (strong, nonatomic) NSNumber *profilePercentage;
@property (strong, nonatomic) NSNumber *isFacebook;
@property (strong, nonatomic) NSNumber *isTwitter;
@property (strong, nonatomic) NSNumber *isInstagram;

//gps data
@property (strong, nonatomic) NSString *countryName;
@property (strong, nonatomic) NSString *cityName;
@property (strong, nonatomic) NSString *state;
@property (assign) float latitude;
@property (assign) float longitude;

//QBChat id
@property (strong, atomic) NSNumber *qbChatID;

@property (copy,atomic) NSString *facebookURL;
@property (copy,atomic) NSString *twitterURl;
@property (copy,atomic) NSString *instagramURL;


+ (UserModel *)getUserWithResponce:(NSDictionary  * _Nullable )  responce;

@end
