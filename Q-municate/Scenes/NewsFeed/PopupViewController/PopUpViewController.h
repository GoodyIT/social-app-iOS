//
//  PopUpViewController.h
//  Reach-iOS
//
//  Created by AlexFill on 05.02.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PopUpViewController : UIViewController

@property (copy, nonatomic) NSString *commentText;
@property (nonatomic, copy) void (^typeChoosedCallback)(NSNumber *);
@property (weak, nonatomic) IBOutlet UILabel *donwLabel;

@end
