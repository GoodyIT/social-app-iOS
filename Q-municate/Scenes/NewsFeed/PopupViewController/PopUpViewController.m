//
//  PopUpViewController.m
//  Reach-iOS
//
//  Created by AlexFill on 05.02.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "PopUpViewController.h"

@interface PopUpViewController ()
@property (weak, nonatomic) IBOutlet UITextView *commentTextView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIView *popUpContentView;

@end

@implementation PopUpViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareUI];
    // Do any additional setup after loading the view.
}

#pragma mark - Private

- (void)prepareUI {    
    self.commentTextView.text = self.commentText;
    self.popUpContentView.layer.cornerRadius = 5.f;
    
    UIImage *image = [[UIImage imageNamed:@"close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.closeButton setImage:image forState:UIControlStateNormal];
    self.closeButton.tintColor = [UIColor blackColor];
}

#pragma mark - IBActions

- (IBAction)privatelyTouched:(id) __unused sender {
    if (!self.typeChoosedCallback) {
        return;
    }
    
    self.typeChoosedCallback([NSNumber numberWithBool:NO]);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)publiclyTouched:(id) __unused sender {
    if (!self.typeChoosedCallback) {
        return;
    }
    
    self.typeChoosedCallback([NSNumber numberWithBool:YES]);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)closeTouched:(id) __unused sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
