//
//  JournalEditViewController.m
//  Reach-iOS
//
//  Created by VICTOR on 9/12/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "JournalEditViewController.h"
#import "DBGlobalManager.h"

@interface JournalEditViewController ()

@end

@implementation JournalEditViewController
@synthesize contentView;
@synthesize dataModel;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self initializeData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view endEditing:YES];
    // save data
    [self saveData];
    
    [super viewWillDisappear:animated];
}

- (void)initializeData {
    if([dataModel.content length] <= 0)
        self.contentView.text = @"";
    else
        self.contentView.text = dataModel.content;
    
    [contentView becomeFirstResponder];
}

- (IBAction)onBack:(id) __unused  sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveData {
    dataModel.content = contentView.text;
    int last = (int)[contentView.text length];
    if(last > 30)
        last = 30;
    dataModel.title = [contentView.text substringWithRange:NSMakeRange(0, last)];
    DBGlobalManager *dbManager = [DBGlobalManager getSharedInstance];
    [dbManager updateData:[dbManager getJournalTableName] data:dataModel];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
