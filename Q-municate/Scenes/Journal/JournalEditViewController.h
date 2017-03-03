//
//  JournalEditViewController.h
//  Reach-iOS
//
//  Created by VICTOR on 9/12/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JournalModel.h"

@interface JournalEditViewController : UIViewController 
@property (weak, nonatomic) IBOutlet UITextView *contentView;
@property (strong, nonatomic) JournalModel *dataModel;

@end
