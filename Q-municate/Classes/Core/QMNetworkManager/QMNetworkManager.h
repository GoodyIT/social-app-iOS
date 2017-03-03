//
//  QMNetworkManager.h
//  reach-ios
//
//  Created by Admin on 2016-11-30.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^CompletionHandler)(BOOL success, id response, NSError *error);

@interface QMNetworkManager : NSObject

@property(strong, nonatomic) UserModel*     myProfile;

@property (strong, nonatomic) NSString       *installDate;
@property (strong, nonatomic) NSString       *installDateTemp;
@property (strong, nonatomic) NSDate*       lastLoggedDateTime;
@property (assign, nonatomic) CLLocationCoordinate2D     oldLocation;
@property(strong, nonatomic) NSString       *countryName;
@property(strong, nonatomic) NSString       *cityName;
@property(strong, nonatomic) NSString       *stateName;

+ (QMNetworkManager *)sharedManager;

- (BFTask *)registerUserWithUsername:(NSString *)username
                       firstname:(NSString*)firstname
                        lastname:(NSString*)lastname
                        birthday:(NSString*)birthday
                           email:(NSString *)email
                        password:(NSString *)password;

- (BFTask *)updateLocate;

- (BFTask *) restorePasswordWithEmail:(NSString *)email;

-(BFTask *)changePassword:(NSString *)oldPassword
           toPassword:(NSString *)newPassword;

-(BFTask *)changeEmailToEmail:(NSString *)email;

// Users
- (BFTask *) getUserWithCompletion;

-(BFTask *) getUserByID:(NSNumber *)userID;

-(BFTask *)getUserByName:(NSString *)userName;

- (BFTask *)getMainBadges: (NSNumber *)userID;

- (BFTask *)  loginUserWithEmail:(NSString *)email
                        password:(NSString *)passwords;

// Notification
// News Feed
- (BFTask*) notifyReadFeed: (NSNumber*) notificationID;

- (BFTask*) getUserNotifications: (NSNumber*) notificationID withType:(NSString*) type;

- (BFTask *) getFeedCountWithCompletion;

// Groups
- (BFTask*) getGroupBadge;

- (BFTask*) notifyReadGroup: (NSNumber*) notificationID;

- (BFTask *)getGroupNotifications: (NSNumber*) notificationID withType:(NSString*) type;

// News feed

- (BFTask *) getUserPostsFrom: (NSNumber *)postID withType:(NSString*) type;

- (BFTask *) sendLikeWithPostID:(NSNumber *)postID;

- (BFTask *) removeLikeWithPostID:(NSNumber *)postID;

- (BFTask*)addNewPostWithText:(NSString *)text image:(NSString *)image hashtags:(NSArray *)hashtags permission:(NSNumber *)permission video:(NSString *)video ;

- (BFTask*)editPostWithText:(NSString *)text image:(NSString *)image hashtags:(NSArray *)hashtags   permission: (NSNumber*) permisson video:(NSString *)video postID: (NSNumber*) postID;

- (BFTask*) getPostByID: (NSNumber*) postID;


// Chat

- (NSArray*) getContacts;

- (BFTask*) addUserToContacts: (NSNumber *)userID otherUserID: (NSNumber *)otherUserID;

- (BFTask*) removeUserFromContacts: (NSNumber *)userID otherUserID: (NSNumber *)otherUserID;


// User Profile
- (BFTask*) changeAvatarWithBase64String: (NSString*) base64Photo;

- (BFTask*) changeBio: (NSString*) bioText;

-(BFTask*)joinFacebook:(NSString *)accessToken;

-(BFTask*)joinTwitter:(NSString *)userName;

-(BFTask*)joinInstagram:(NSString *)accessToken;

- (BFTask*) updateAndGetUserWithCompletion;

-(BFTask *) getNewPostsFrom:(NSNumber *)postID withType: (NSString*) type;

- (BFTask*) searchPostByHashtag: (NSString*) hasTag fromPost: (NSNumber *)postID withType: (NSString*) type;

- (BFTask*) exploreSearchPopularWithKeyword:(NSString *) keyword fromPost:(NSNumber *)postID withinRadius: (NSNumber*) radius type: (NSString*) type;

-(BFTask*)deletePostByID:(NSNumber *)postID;

- (BFTask*)reportObject:(NSNumber *)objectType WithID:(NSNumber *)objectID;

- (BFTask* )getMyPostsWithOffset:(NSNumber *)offset;

// Comment

- (BFTask*)addNewCommentWithPostID:(NSNumber *)postID text:(NSString *)text permission:(NSNumber *)permission;

- (BFTask*)rateCommentWithCommentID:(NSNumber *)commentID statement:(NSNumber *)statement;

- (BFTask*) contactUs: (NSString*) email;




// Groups

- (BFTask*) getCategories:(NSString*) filter;

- (BFTask*) getGroups:(NSString*) filter inCategory: (NSNumber*) categoryID fromGroupID:(NSNumber*) groupID withType: (NSString*) type;

- (BFTask*) createNewGroupWithName:(NSString *)name description:(NSString *)description image:(NSString *)image categoryID:(NSNumber *)categoryID permission:(NSNumber *)permission;

- (BFTask*) getMyCreatedGroupsWithOffset: (NSString*) filter offset:(NSNumber*) offset;

- (BFTask*) getMyJoinedGroupsWithOffset: (NSString*) filter offset:(NSNumber*) offset;

- (BFTask*)createNewTopicWithGroupID:(NSNumber *)groupID text:(NSString *)text permission:(NSNumber *)permission;

- (BFTask*)joinGroupWithGroupID:(NSNumber *)groupID;

-(BFTask*)replyToTopic:(NSNumber *)topicID Text:(NSString *)text Permission:(NSNumber *)permission;

- (BFTask*) getGroupWithID:(NSNumber*) groupID;

@end

NS_ASSUME_NONNULL_END
