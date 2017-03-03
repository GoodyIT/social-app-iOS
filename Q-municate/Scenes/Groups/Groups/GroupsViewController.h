//
//  CircleViewController.h
//  reach-ios
//
//  Created by Admin on 2016-12-27.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GroupsViewController : UITableViewController

@property (strong, nonatomic) NSNumber* categoryID;
@property (strong, nonatomic) NSString* categoryName;
@property (strong, nonatomic) GroupModel* myGroup;
@end
