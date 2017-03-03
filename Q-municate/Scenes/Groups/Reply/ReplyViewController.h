//
//  ReplyViewController.h
//  reach-ios
//
//  Created by Admin on 2016-12-29.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReplyViewController : UIViewController
@property (strong, nonatomic) TopicModel* topic;
@property (strong, nonatomic) NSNumber* topicID;
@property (strong, nonatomic) GroupModel* group;
@end
