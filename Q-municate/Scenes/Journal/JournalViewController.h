//
//  JournalViewController.h
//  Reach-iOS
//
//  Created by VICTOR on 8/29/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JournalViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableViewObject;
- (IBAction)onNewJournalAction:(id)sender;

- (IBAction)onBackAction:(id)sender;
@end
