//
//  MainAnimViewController.h
//  Reach-iOS
//
//  Created by VICTOR on 8/28/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainAnimViewController : CustomViewController

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *newsfeed_leading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *newsfeed_top;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calls_leading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *calls_top;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *Messages_leading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *Messages_top;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locate_leading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locate_top;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *circles_leading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *circles_top;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *settting_leading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *setting_top;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *journal_leading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *journal_top;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *group_leading;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *group_top;

@property (weak, nonatomic) IBOutlet UIView *mainSuperView;

@property (weak, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UIView *newsView;
@property (weak, nonatomic) IBOutlet UIView *callsView;
@property (weak, nonatomic) IBOutlet UIView *messagesView;
@property (weak, nonatomic) IBOutlet UIView *locateView;
@property (weak, nonatomic) IBOutlet UIView *circleView;
@property (weak, nonatomic) IBOutlet UIView *settingView;
@property (weak, nonatomic) IBOutlet UIView *journalView;
@property (weak, nonatomic) IBOutlet UIView *groupView;

@property (strong, nonatomic) QBChatDialog *chatDialogFromPush;


- (IBAction)onNewsFeedAction:(id)sender;
- (IBAction)onChatAction:(id)sender;
- (IBAction)onSettingAction:(id)sender;
- (IBAction)onJournalAction:(id)sender;
- (IBAction)onGroupAction:(id)sender;

- (void)initializeData;
//- (void) checkPushNotification;
//- (void)getBadges ;

- (void) updateChatBadges;

@end
