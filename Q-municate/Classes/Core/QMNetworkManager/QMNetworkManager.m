//
//  QMNetworkManager.m
//  reach-ios
//
//  Created by Admin on 2016-11-30.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMNetworkManager.h"
#import "QMCore.h"
#import "QMContent.h"
#import "QMMessagesHelper.h"
#import "AFNetworking.h"
#import "NSError+Network.h"
#import <Flurry.h>
#import <Fabric/Fabric.h>

@interface QMNetworkManager ()

@property(nonatomic, strong) AFHTTPSessionManager  *manager;
@property(nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) BFTaskCompletionSource* source;

@end

@implementation QMNetworkManager
@synthesize myProfile;



+ (QMNetworkManager *)sharedManager {
    static QMNetworkManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[QMNetworkManager alloc] init];
    });
    
    return manager;
}

#pragma mark -  Lifecycle

- (instancetype)init {
    if (self = [super init]) {
        [self initManager];
    }
    
    return self;
}

- (void)initManager
{
    self.manager = [[AFHTTPSessionManager  alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
//    self.manager.session.configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
//    self.manager.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    
    self.manager.responseSerializer =  [AFJSONResponseSerializer serializer];
    self.manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", nil];
    
//    self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
    self.session = [NSURLSession sharedSession];
}

- (BFTask *)registerUserWithUsername:(NSString *)username
                       firstname:(NSString*)firstname
                        lastname:(NSString*)lastname
                        birthday:(NSString*)birthday
                           email:(NSString *)email
                        password:(NSString *)password
    {
    
    NSString *uuidString = [NSUUID UUID].UUIDString;
    NSString *deviceToken = (![DataManager sharedManager].notificationToken) ? @"" : [DataManager sharedManager].notificationToken;
    
    NSDictionary *parameters = @{ @"username":username,
                                  @"first_name":firstname,
                                  @"last_name":lastname,
                                  @"birthday":birthday,
                                  @"email":email,
                                  @"password":password,
                                  @"device_token": deviceToken,
                                  @"device_unique_id": uuidString,
                                  @"qbchat_id": [NSString stringWithFormat:@"%lu", (unsigned long)[QBSession currentSession].currentUser.ID]
                                  };

    return [self perfomRequestWithPath:registaration parameters:parameters];
}

- (BFTask*) updateAndGetUserWithCompletion
{
    NSDictionary *parameters = @{@"token":[TokenModel sharedInstance].token,
                                 @"qbchat_id": [NSString stringWithFormat:@"%lu", [QBSession currentSession].currentUser.ID]};
    
    return [self perfomRequestWithPath:usgetUserByToken parameters:parameters];
}
//
//- (BFTask *)updateLocate {
//    NSDictionary *parameters = @{
//                                 @"token":[TokenModel sharedInstance].token,
//                                 @"country_name": [QMNetworkManager sharedManager].countryName,
//                                 @"city_name": [QMNetworkManager sharedManager].cityName,
//                                 @"state_name": [QMNetworkManager sharedManager].stateName,
//                                 @"latitude": [NSNumber numberWithDouble: [QMNetworkManager sharedManager].oldLocation.latitude],
//                                 @"longitude": [NSNumber numberWithDouble: [QMNetworkManager sharedManager].oldLocation.longitude]
//                                 };
//    
//    if  ([[TokenModel sharedInstance].token isEqualToString:@""])
//    {
//        [[Mixpanel sharedInstance] track:@"Token - error "
//                              properties:@{
//                                           @"path": updateLocate,
//                                           @"params": parameters
//                                           }];
//        return nil;
//    }
//    
//   return [self perfomRequestWithPath:updateLocate parameters:parameters];
//}

- (BFTask *) restorePasswordWithEmail:(NSString *)email{
    NSDictionary *parameters = @{@"email":email};
    
    return  [self perfomRequestWithPath:forgotPassword parameters:parameters];
}

-(BFTask *)changePassword:(NSString *)oldPassword
               toPassword:(NSString *)newPassword
{
    NSDictionary *parameters = @{@"token":[TokenModel sharedInstance].token,
                                        @"old_password":oldPassword,
                                        @"new_password":newPassword};
    
    return [self perfomRequestWithPath:changePassword parameters:parameters];
    
}

-(BFTask *)changeEmailToEmail:(NSString *)email
{
    NSDictionary *parameters = @{@"token":[TokenModel sharedInstance].token,
                                 @"email":email};
    NSLog(@"Paramets: %@", parameters);
    
   return [self perfomRequestWithPath:changeEmail parameters:parameters];
}

- (BFTask *)getMainBadges: (NSNumber *)userID {
    NSDictionary *parameters = @{@"token" : [TokenModel sharedInstance].token,
                                 @"user_id" : userID};
   return [self perfomRequestWithPath:getBadges parameters:parameters];
}

-(BFTask *) getUserByID:(NSNumber *)userID
{
    NSDictionary *parameters = @{@"token" : [TokenModel sharedInstance].token,
                                 @"user_id" : userID};
    return [self perfomRequestWithPath:getUserByID parameters:parameters];
}

-(BFTask *)getUserByName:(NSString *)userName
{
    NSDictionary *parameters = @{@"token" : [TokenModel sharedInstance].token,
                                 @"username" : userName};
    return [self perfomRequestWithPath:getUserByName parameters:parameters];
}

- (BFTask *) getUserWithCompletion {
    NSDictionary *parameters = @{@"token":[TokenModel sharedInstance].token};
    
    return  [self perfomRequestWithPath:getUserByToken  parameters:parameters];
}

- (BFTask *)  loginUserWithEmail:(NSString *)email
                  password:(NSString *)password {
    
    NSString *uuidString = [NSUUID UUID].UUIDString;
    
    NSDictionary *parameters = @{
                                 @"email":email,
                                 @"password":password,
                                 @"device_token": (![DataManager sharedManager].notificationToken) ? @"" : [DataManager sharedManager].notificationToken,
                                 @"device_unique_id": uuidString
                                 //@"device_token": [TokenModel sharedInstance].notificationToken
                                 };
    return [self perfomRequestWithPath:login parameters:parameters];
}

// News feed notification

- (BFTask*) getUserNotifications: (NSNumber*) notificationID withType:(NSString*) type
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"notification_id":notificationID,
                                 @"type": type
                                 };
    
    return [self perfomRequestWithPath:userNotifications parameters:parameters];
}


- (BFTask*) notifyReadFeed: (NSNumber*) notificationID
{
    NSDictionary *parameters = @{
                                 @"token" : [TokenModel sharedInstance].token,
                                 @"notification_id": notificationID
                                 };
    return [self perfomRequestWithPath:notifyReadFeed parameters:parameters];
}

- (BFTask *) getFeedCountWithCompletion
{
    NSDictionary *parameters = @{@"token" : [TokenModel sharedInstance].token};
    return [self perfomRequestWithPath:getFeedCount parameters:parameters];
}

// Groups

- (BFTask *) getGroupBadge
{
    NSDictionary *parameters = @{@"token" : [TokenModel sharedInstance].token};
    return [self perfomRequestWithPath:getGroupBadge parameters:parameters];
}

- (BFTask*) notifyReadGroup: (NSNumber*) notificationID
{
    NSDictionary *parameters = @{
                                 @"token" : [TokenModel sharedInstance].token,
                                 @"notification_id": notificationID
                                 };
    return [self perfomRequestWithPath:notifyReadGroup parameters:parameters];
}

- (BFTask *)getGroupNotifications:(NSNumber*) notificationID withType:(NSString*) type {
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"notification_id":notificationID,
                                 @"type": type};
    
    return  [self perfomRequestWithPath:groupNotifications parameters:parameters];
}

- (BFTask*) searchPostByHashtag: (NSString*) hasTag fromPost: (NSNumber *)postID withType: (NSString*) type
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"hashtag":hasTag,
                                 @"post_id" : postID,
                                 @"type": type
                                 };

    return [self perfomRequestWithPath:searchByHashtag parameters:parameters];
}

- (BFTask*) exploreSearchPopularWithKeyword:(NSString *) keyword fromPost:(NSNumber *)postID withinRadius: (NSNumber*) radius type: (NSString*) type
{
    NSDictionary *parameters = @{
                                 @"token" : [TokenModel sharedInstance].token,
                                 @"keyword": keyword,
                                 @"radius": radius,
                                 @"post_id" : postID,
                                 @"type" : type
                                 };
    
    return [self perfomRequestWithPath:popularSearch parameters:parameters];
}

//- (NSDictionary*) getUserPostsWithHashTagWithSync: (NSString*) hasTag withOffset: (NSNumber *)offset
//{
//    NSDictionary *parameters = @{
//                                 @"token":[TokenModel sharedInstance].token,
//                                 @"hashtag":hasTag,
//                                 @"offset" : offset
//                                 };
//    
//    __block dispatch_semaphore_t sem = dispatch_semaphore_create(0);
//    __block NSMutableArray* allPosts = [NSMutableArray new];
//    __block NSNumber *currentOffset;
//    (void)[[self syncPerfomRequestWithPath:searchByHashtag parameters:parameters] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
//        allPosts = [[PostModel getPostListFromResponse:serverTask.result] mutableCopy];
//        NSError *offsetError = [NSError errorWithDomain:@"99999" code:99999 userInfo:@{NSLocalizedDescriptionKey:[serverTask.result valueForKey:@"offset"]}];
//        currentOffset = @([offsetError.localizedDescription integerValue]);
//        dispatch_semaphore_signal(sem);
//        
//        return serverTask;
//    }];
//    
//    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
//    return @{ @"post": allPosts,  @"offset": currentOffset};
//}

-(BFTask *) getNewPostsFrom:(NSNumber *)postID withType: (NSString*) type
{
    NSDictionary *parameters = @{
                                 @"token": [TokenModel sharedInstance].token,
                                 @"post_id":postID,
                                 @"type": type
                                 };
    return [self perfomRequestWithPath:getNewPosts parameters:parameters];
}

- (BFTask *) getUserPostsFrom: (NSNumber *)postID withType:(NSString*) type
{
    NSDictionary *parameters = @{@"token":[TokenModel sharedInstance].token,
                                 @"post_id":postID,
                                 @"type": type
                                 };
    
    return [self perfomRequestWithPath:getAllPosts parameters:parameters];
}

- (BFTask* )getMyPostsWithOffset:(NSNumber *)offset {
    NSDictionary *parameters = @{@"token":[TokenModel sharedInstance].token,
                                 @"author_id": [QBSession currentSession].currentUser.login,
                                 @"offset":offset};
    
   return [self perfomRequestWithPath:getMyPosts parameters:parameters];
}

- (BFTask *) sendLikeWithPostID:(NSNumber *)postID
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"post_id": postID
                                 };
    return [self perfomRequestWithPath:sendLike parameters:parameters];
}

- (BFTask *) removeLikeWithPostID:(NSNumber *)postID
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"post_id": postID
                                 };
    return [self perfomRequestWithPath:removeLike parameters:parameters];
}

- (BFTask*)addNewPostWithText:(NSString *)text image:(NSString *)image hashtags:(NSArray *)hashtags permission:(NSNumber *)permission video:(NSString *)video {
    NSDictionary *parameters = @{
                                 @"token"       :[TokenModel sharedInstance].token,
                                 @"text"        :text,
                                 @"image"       :image,
                                 @"hashtags"    :hashtags,
                                 @"permission"  :permission,
                                 @"video"       :video
                                 };
    
    return [self perfomRequestWithPath:addNewPost
                     parameters:parameters];
}

- (BFTask*)editPostWithText:(NSString *)text image:(NSString *)image hashtags:(NSArray *)hashtags   permission: (NSNumber*) permisson video:(NSString *)video postID: (NSNumber*) postID
{
    NSDictionary *parameters = @{
                                 @"token"       :[TokenModel sharedInstance].token,
                                 @"text"        :text,
                                 @"image"       :image,
                                 @"video"       :video,
                                 @"hashtags"    :hashtags,
                                 @"permission"  :permisson,
                                 @"post_id"     : postID
                                 };
    
    return [self perfomRequestWithPath:editPost
                            parameters:parameters];
}


-(BFTask*)deletePostByID:(NSNumber *)postID
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"post_id": postID
                                 };
    return [self perfomRequestWithPath:deletePost parameters:parameters];
}

- (BFTask*)reportObject:(NSNumber *)objectType WithID:(NSNumber *)objectID {
    
    NSDictionary *parameters;
    if(objectType.intValue == 0){
        parameters = @{
                       @"token":[TokenModel sharedInstance].token,
                       @"post_id":objectID
                       };
    } else  if (objectType.intValue == 1){
        parameters = @{
                       @"token":[TokenModel sharedInstance].token,
                       @"comment_id":objectID
                       };
        
    } else {
        parameters = @{
                       @"token":[TokenModel sharedInstance].token,
                       @"circle_id":objectID
                       };
    }
    
    return [self perfomRequestWithPath:sendReportEmail parameters:parameters];
}

- (BFTask*) getPostByID: (NSNumber*) postID
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"post_id": postID
                                 };
    return [self perfomRequestWithPath:getPostByID parameters:parameters];
}

// Comment

- (BFTask*)addNewCommentWithPostID:(NSNumber *)postID text:(NSString *)text permission:(NSNumber *)permission {
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"text":text,
                                 @"post_id":postID,
                                 @"permission":permission
                                 };
    
    return [self perfomRequestWithPath:addNewComment parameters:parameters];
}

- (BFTask*)rateCommentWithCommentID:(NSNumber *)commentID statement:(NSNumber *)statement
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"comment_id":commentID,
                                 @"statement":statement
                                 };
    return [self perfomRequestWithPath:rateComment parameters:parameters];
    
}

// Get the frieds list from the server
- (NSArray*) getContacts
{
   __block dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    NSDictionary *parameters = @{@"token": [TokenModel sharedInstance].token};
   __block NSMutableArray* allContactListItems = [NSMutableArray new];
    (void)[[self syncPerfomRequestWithPath:getContacts parameters:parameters] continueWithBlock:^id _Nullable(BFTask * _Nonnull serverTask) {
        allContactListItems = serverTask.result[@"request"];
        
        dispatch_semaphore_signal(sem);
        
        return serverTask;
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    NSMutableArray *friends = [NSMutableArray new];
    
    NSArray* allUsers = [[QMCore instance].usersService.usersMemoryStorage unsortedUsers]; // [[QMCore instance].contactManager allContactsSortedByFullName];
    for (NSDictionary* contact in allContactListItems) {
        for (QBUUser* user in allUsers) {
            NSLog(@"current session %@", [QBSession currentSession].currentUser.login);
            if([[contact[@"user"] objectForKey:@"id"] integerValue] ==  [user.login integerValue] && [[contact[@"user"] objectForKey:@"id"] integerValue] != [[QBSession currentSession].currentUser.login integerValue]){
                [friends addObject:user];
                break;
            }
            else if  ([contact[@"otheruser"] integerValue] == [user.login integerValue] && [contact[@"otheruser"] integerValue] != [[QBSession currentSession].currentUser.login integerValue])
            {
                [friends addObject:user];
                break;
            }
        }
    }
    
    return friends.copy;
}

- (BFTask*) addUserToContacts: (NSNumber *)userID otherUserID: (NSNumber *)otherUserID
{
    NSDictionary *parameters = @{@"token" : [TokenModel sharedInstance].token,
                                 @"user_id": userID,
                                 @"other_userid" : otherUserID};
    return [self perfomRequestWithPath:addUserToContacts parameters:parameters];
}

- (BFTask*) removeUserFromContacts: (NSNumber *)userID otherUserID: (NSNumber *)otherUserID
{
    NSDictionary *parameters = @{@"token" : [TokenModel sharedInstance].token,
                                 @"user_id": userID,
                                 @"other_userid" : otherUserID};
    return [self perfomRequestWithPath:removeUserFromContacts parameters:parameters];
}

/*
  Profile
 */

- (BFTask*) changeAvatarWithBase64String: (NSString*) base64Photo
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"avatar":base64Photo
                                 };
    return [self perfomRequestWithPath:changeAvatar parameters:parameters];
}

- (BFTask*) changeBio: (NSString*) bioText
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"biography":bioText
                                 };
    return [self perfomRequestWithPath:changeBio parameters: parameters];
}

-(BFTask*)joinFacebook:(NSString *)accessToken
{
    NSDictionary *parameters = @{
                                 @"token" : [TokenModel sharedInstance].token,
                                 @"access_token" : accessToken
                                 };
    return [self perfomRequestWithPath:joinFacebook parameters:parameters];
}

-(BFTask*)joinTwitter:(NSString *)userName
{
    NSDictionary *parameters = @{
                                 @"token" : [TokenModel sharedInstance].token,
                                 @"screen_name" : userName
                                 };
   return [self perfomRequestWithPath:joinTwitter parameters:parameters];
}

-(BFTask*)joinInstagram:(NSString *)accessToken
{
    NSDictionary *parameters = @{
                                 @"token" : [TokenModel sharedInstance].token,
                                 @"access_token" : accessToken
                                 };
  return  [self perfomRequestWithPath:joinInstagram parameters:parameters];
}

- (BFTask*) contactUs: (NSString*) email
{
    NSDictionary *parameters = @{
                                 @"email":email
                                 };

    return [self perfomRequestWithPath:@"user/contact-us/" parameters: parameters];
}


- (BFTask*) syncPerfomRequestWithPath:(NSString *)path
                       parameters:(NSDictionary *)parameters{
    BFTaskCompletionSource* syncSource = [BFTaskCompletionSource taskCompletionSource];
    
    NSString *URLString = [baseURLString stringByAppendingString:path];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
//    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:URLString parameters:nil error:nil];
    
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    
    NSMutableDictionary* responseObject = nil;
    @weakify(responseObject);
    @weakify(sem);
    [[self.session dataTaskWithRequest:req
                                     completionHandler:^(NSData *data, NSURLResponse __unused *response, NSError *error) {
                                         
                                         if (!error) {
                                             if (error) {
                                                 if([error.localizedDescription isEqualToString:@"token doesn't exist"]){
                                                     [syncSource trySetError:error];
                                                 }
                                                 [syncSource trySetError:error];
                                             } else {
                                                 @strongify(responseObject);
                                                 if (error == nil) {
                                                     responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                                                 }
                                                 if ([responseObject valueForKey:@"error"] != nil) {
                                                     NSDictionary *userInfo = @{
                                                                                NSLocalizedDescriptionKey: [NSError errorLocalizedDescriptionForCode:[[responseObject valueForKey:@"error"] intValue]]
                                                                                };
                                                     error = [NSError errorWithDomain:NSRegistrationDomain
                                                                                 code:[[responseObject valueForKey:@"error"] intValue]
                                                                             userInfo:userInfo];
                                                     if ([responseObject valueForKey:@"post"]) {
                                                         [syncSource trySetResult:[PostModel getPostInfoFromResponse:[responseObject valueForKey:@"post"]]];
                                                     } else {
                                                         [syncSource trySetError:error];
                                                     }
                                                 } else {
                                                     [syncSource trySetResult:responseObject];
                                                 }
                                             }
                                         } else {
                                             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                             if([error.localizedDescription isEqualToString:@"token doesn't exist"]){
                                                 [syncSource trySetError:error];
                                             }
                                             
                                             if (error.code == NSURLErrorTimedOut) {
                                                 [syncSource trySetError:error];
                                             }
                                             
                                             [syncSource trySetError:error];
                                             
                                         }
                                         
                                         @strongify(sem);
                                         dispatch_semaphore_signal(sem);  
                                     }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return syncSource.task;
}

-(void)goToLoginController{
    [[[QMCore instance] logout] continueWithBlock:^id _Nullable(BFTask * _Nonnull __unused t) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Auth" bundle:nil];
        UINavigationController *loginController = [storyboard instantiateViewControllerWithIdentifier:@"startNavigationController"];
        
        UIView *snapShot = [[UIApplication sharedApplication].delegate.window snapshotViewAfterScreenUpdates:YES];
        [loginController.view addSubview:snapShot];
        [UIApplication sharedApplication].delegate.window.rootViewController = loginController;
        [UIView animateWithDuration:1.0 animations:^{
            snapShot.layer.opacity = 0;
            snapShot.layer.transform = CATransform3DMakeScale(1.5, 1.5, 1.5);
        } completion:^(BOOL __unused finished) {
            [snapShot removeFromSuperview];
            [[UIApplication sharedApplication].delegate.window makeKeyAndVisible];
        }];
        return nil;
    }];
}


/*
  Groups
 */

- (BFTask*) getCategories:(NSString*) filter
{
    NSDictionary *parameters = @{
                                 @"token" : [TokenModel sharedInstance].token,
                                 @"keyword": filter
                                 };
    
    return [self perfomRequestWithPath:getAllCategories parameters:parameters];
}

- (BFTask*) getGroups:(NSString*) filter inCategory: (NSNumber*) categoryID  fromGroupID:(NSNumber*) groupID withType: (NSString*) type
{
    NSDictionary *parameters = @{
                                 @"token" : [TokenModel sharedInstance].token,
                                 @"keyword": filter,
                                 @"group_id": categoryID,
                                 @"circle_id": groupID,
                                 @"type" : type
                                 };
    
    return [self perfomRequestWithPath:getAllGroups parameters:parameters];
}

- (BFTask*)createNewGroupWithName:(NSString *)name description:(NSString *)description image:(NSString *)image categoryID:(NSNumber *)categoryID permission:(NSNumber *)permission
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"name":name,
                                 @"description":description,
                                 @"image":image,
                                 @"group_id":categoryID,
                                 @"permission":permission
                                 };
    return [self perfomRequestWithPath:createNewGroup parameters:parameters];
}

- (BFTask*) getMyCreatedGroupsWithOffset: (NSString*) filter offset:(NSNumber*) offset
{
    NSDictionary *parameters = @{
                                 @"token" : [TokenModel sharedInstance].token,
                                 @"keyword": filter,
                                 @"offset": offset
                                 };
    
    return [self perfomRequestWithPath:getCreatedGroups parameters:parameters];
}

- (BFTask*) getMyJoinedGroupsWithGroupID: (NSNumber*) groupID withType: (NSString*) type
{
    NSDictionary *parameters = @{
                                 @"token" : [TokenModel sharedInstance].token,
                                 @"type": type,
                                 @"circle_id":groupID
                                 };
    
    return [self perfomRequestWithPath:getJoinedGroups parameters:parameters];
}

- (BFTask*)createNewTopicWithGroupID:(NSNumber *)groupID text:(NSString *)text permission:(NSNumber *)permission
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"circle_id":groupID,
                                 @"text":text,
                                 @"permission":permission
                                 };
    
    return [self perfomRequestWithPath:createTopic parameters:parameters];
}

- (BFTask*)joinGroupWithGroupID:(NSNumber *)groupID
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"circle_id":groupID
                                 };
    
    return [self perfomRequestWithPath:joinGroup parameters:parameters];
}

-(BFTask*)replyToTopic:(NSNumber *)topicID Text:(NSString *)text Permission:(NSNumber *)permission
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"topic_id":topicID,
                                 @"text":text,
                                 @"permission":permission
                                 };
    return [self perfomRequestWithPath:sendReplyToTopic parameters:parameters];
}

- (BFTask*) getGroupWithID:(NSNumber*) groupID
{
    NSDictionary *parameters = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"circle_id":groupID
                                 };
    return [self perfomRequestWithPath:getGroup parameters:parameters];
    
}

- (BFTask *) perfomRequestWithPath:(NSString *)path
                   parameters:(NSDictionary *)parameters{

    
    BFTaskCompletionSource* source = [BFTaskCompletionSource taskCompletionSource];
    
    NSString *URLString = [baseURLString stringByAppendingString:path];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:URLString parameters:nil error:nil];
    
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    [req setTimeoutInterval:100.0];
    
    @weakify(self);
    [[self.manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        @strongify(self);
        id _responseObject = [responseObject copy];
        
        if (response)
            [[Mixpanel sharedInstance] track:@"Network "
                                  properties:@{@"url": response.URL, @"params": parameters}];
           
        if  (error)
            [[Mixpanel sharedInstance] track:@"Token - error "
                                  properties:@{
                                               @"path": path,
                                               @"params": parameters
                                               }];
        
        if (!error && _responseObject != nil) {
            if (error) {
                if([error.localizedDescription isEqualToString:@"token doesn't exist"]){
                    if  (error)
                        [[Mixpanel sharedInstance] track:@"Token - error "
                                              properties:@{
                                                           @"path": path,
                                                           @"params": parameters
                                                           }];
                    [self goToLoginController];
                    return;
                }
                
                [source trySetError:error];
                
            } else {
                if ([_responseObject valueForKey:@"error"] != nil) {
                    NSDictionary *userInfo = @{
                                               NSLocalizedDescriptionKey: [NSError errorLocalizedDescriptionForCode:[[_responseObject valueForKey:@"error"] intValue]]
                                               };
                    error = [NSError errorWithDomain:NSRegistrationDomain
                                                         code:[[_responseObject valueForKey:@"error"] intValue]
                                                     userInfo:userInfo];
                    
                    
                    if ([_responseObject valueForKey:@"post"]) {
                        [source trySetResult:[PostModel getPostInfoFromResponse:[_responseObject valueForKey:@"post"]]];
                    }
                    else {
                        if([error.localizedDescription isEqualToString:@"token doesn't exist"]){
                            if  (error)
                                [[Mixpanel sharedInstance] track:@"Token - error "
                                                      properties:@{
                                                                   @"path": path,
                                                                   @"params": parameters
                                                                   }];
                            [self goToLoginController];
                            return;
                        }
                        [source setError:error];
                    }
                } else {
                    [source setResult:_responseObject];
                }
            }
        } else {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            if([error.localizedDescription isEqualToString:@"token doesn't exist"]){
                [[Mixpanel sharedInstance] track:@"Token - error "
                                      properties:@{
                                                   @"path": path,
                                                   @"params": parameters
                                                   }];
                [self goToLoginController];
                return;
            }            

            [source setError:error];
        }
    }] resume];

    return source.task;
}
@end
