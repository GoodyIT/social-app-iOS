//
//  NetworkManagerConstants.h
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>

// constants

#define kNotificationDelay          4

static int THE_CELL_HEIGHT = 450;
#define kEndTransition             @"EndTransition"
#define kBeginTransition           @"BeginTransition"

#pragma mark - baseURL

//static NSString *const baseURLString = @"http://ec2-35--163-215-176.us-west-2.compute.amazonaws.com/api/v1/";
//static NSString *const imagesURLString = @"http://ec2-35--163-215-176.us-west-2.compute.amazonaws.com";
static NSString *const baseURLString = @"https://reachmobileapp.us/api/v1/";
static NSString *const imagesURLString = @"https://reachmobileapp.us";

#pragma mark - Keyboard Switch
static int const constraintForEmoji = 35;

#pragma mark - Push Notification
static NSString *const sendPushNotification = @"user/send-notification/";
static NSString *const readChatNotification = @"user/read-chat-notification/";
static NSString *const getBadges = @"user/get-notification-badge/";
static NSString *const deleteNotification = @"user/delete-notification-badge/";

#pragma mark - Sign Up

static NSString *const registaration = @"registration/";
static NSString *const login = @"login/";
static NSString *const forgotPassword = @"forgot-password/";

#pragma mark - Change login parametrs

static NSString *const changePassword = @"user/change-password/";
static NSString *const changeEmail = @"user/change-email/";


#pragma mark - Locate Section
static NSString *const createNewLocateGroup = @"locate/create-new-group/";

#pragma mark - User
static NSString *const getUserByToken = @"user/get-user-by-token/";
static NSString *const usgetUserByToken = @"user/uget-user-by-token/";                           // update qbchat_id and get user information by token_id
static NSString *const getUserForEditProfileByToken = @"user/get-user-profile-by-token/";
static NSString *const getUserForEditProfileByUserID = @"user/get-user-profile-by-id/";
static NSString *const changeBio = @"user/change-bio/";
static NSString *const updateLocate = @"user/update-locate/";
static NSString *const changeAvatar = @"user/change-avatar/";
static NSString *const getUserByID = @"user/get-user-by-id/";
static NSString *const getUsers = @"user/get-user-nearby/";
static NSString *const getUserByName = @"user/get-user-by-name/";
static NSString *const searchUsersByName = @"user/search-user-by-name/";
static NSString *const blockUser = @"user/report-user/";
static NSString *const unBlockUser = @"user/remove-reported-user/";
static NSString *const checkBlockUserByToken = @"user/check-report-user-by-token/";
static NSString *const checkBlockUserById = @"user/check-report-user-by-id/";
static NSString *const blockedUsersList = @"user/get-reported-users/";
static NSString *const userNotifications = @"feed/get-user-feed/";
static NSString *const joinFacebook = @"user/social/facebook/";
static NSString *const joinTwitter = @"user/social/twitter/";
static NSString *const joinInstagram = @"user/social/instagram/";
static NSString *const getContactAccepts = @"user/get-contact-accept-notification/";
static NSString *const unfriendTask = @"user/unfriend-task/";

#pragma mark - Chat
//static NSString *const contactRequest = @"user/contact-request/";
//static NSString *const getContactRequest = @"user/get-contact-request/";
//static NSString *const deleteContactRequest = @"user/delete-contact-request/";
//static NSString *const acceptContactRequest = @"user/accept-contact-request/";

// new api
static NSString *const getContacts = @"user/get-contact-request/";
static NSString *const addUserToContacts = @"user/contact-request/";
static NSString *const removeUserFromContacts = @"user/delete-contact-request/";
#pragma mark - Posts

static NSString *const addNewPost = @"post/add-new-post/";
static NSString *const editPost = @"post/edit-post/";
static NSString *const getAllPosts = @"post/get-user-posts/";
static NSString *const sendLike = @"post/send-like/";
static NSString *const removeLike = @"post/remove-like/";
static NSString *const addNewComment = @"post/add-new-comment/";
static NSString *const searchByHashtag = @"search/hashtag/";
static NSString *const sendReportEmail = @"user/send-report-email/";// отправляет репорт на юзера
static NSString *const deletePost = @"post/remove-post/";
static NSString *const getNewPosts = @"post/get-user-new-posts/";
static NSString *const getMyPosts = @"post/get-my-post/";

static NSString *const getPostByID = @"post/get-single-post/";

static NSString *const sendCall = @"voip/start-call/";  // отправляет оповещение о звонке

#pragma mark - Comments

static NSString *const rateComment = @"post/rate-comment/";

#pragma mark - Circles

static NSString *const getAllGroups = @"circle/search/";
static NSString *const getCreatedGroups = @"circle/get-created-circles/";
static NSString *const getJoinedGroups = @"circle/get-joined-circles/search/";
static NSString *const createNewGroup = @"circle/create-new-circle/";
static NSString *const getGroup = @"circle/get-circle/";
static NSString *const joinGroup = @"circle/join-circle/";
static NSString *const searchAllGroups = @"circle/get-all-circles/search/";
static NSString *const searchJoinedGroups = @"circle/get-joined-circles/search/";
static NSString *const searchCreatedGroups = @"circle/get-created-circles/search/";
static NSString *const categoryGroups = @"circle/get-circle-by-group/";
static NSString *const groupNotifications = @"circle/get-circle-notification/";
static NSString *const getGroupBadge =  @"circle/get-unread-notifications/";
static NSString *const notifyReadGroup = @"circle/read-notifications/";

#pragma mark - Explore

static NSString *const exploreGetPopular = @"explore/get-popular/";
static NSString *const exploreGetDailyUpvotes = @"explore/get-daily-upvotes/";
static NSString *const exploreGetMostUpvoted = @"explore/get-most-upvoted/";

static NSString *const popularSearch = @"explore/get-popular/search/";
static NSString *const dailyUpvotesSearch = @"explore/get-daily-upvotes/search/";
static NSString *const mostUpvotedSearch = @"explore/get-most-upvoted/search/";

#pragma mark - Groups

static NSString *const getAllCategories = @"groups/get-groups/";

#pragma mark - Topics

static NSString *const createTopic = @"topic/create-new-topic/";
static NSString *const sendReplyToTopic = @"reply/send-reply/";

#pragma mark - Rate

static NSString *const rateUser = @"rate/rate-user/";

#pragma mark - Direct

static NSString *const sendRequest = @"direct/send-request/";
static NSString *const allowRequest = @"direct/allow-request/";
static NSString *const checkRequest = @"direct/check-request-status/";

#pragma mark - Send Message

static NSString *const sendMessage = @"message/send-message/";


#pragma mark - Feed

static NSString *const notifyReadFeed = @"feed/read-feed/";
static NSString *const getFeedCount = @"feed/count-unread-feed/";

