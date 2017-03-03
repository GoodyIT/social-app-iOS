//
//  JournalViewController.m
//  Reach-iOS
//
//  Created by VICTOR on 8/29/16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "JournalViewController.h"
#import "JournalTableViewCell.h"
#import "DBGlobalManager.h"
#import "JournalModel.h"
#import "JournalEditViewController.h"

@interface JournalViewController () {
    NSMutableArray *journalData;
}

@end

@implementation JournalViewController
@synthesize countLabel;
@synthesize tableViewObject;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableViewObject.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    [self initializeData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initializeData {
    // init value
    journalData = [[NSMutableArray alloc] init];
    // get data
    journalData = [[[DBGlobalManager getSharedInstance] getAllData:[[DBGlobalManager getSharedInstance] getJournalTableName]] mutableCopy];
    
    [tableViewObject reloadData];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onNewJournalAction:(id)__unused sender {
    DBGlobalManager *dbManager = [DBGlobalManager getSharedInstance];
    JournalModel *data = [[JournalModel alloc] init];
    data.tblID = [dbManager insertData:[dbManager getJournalTableName] data:data];
    
    [self performSegueWithIdentifier:kEditJournalSegue sender:data];
}

- (IBAction)onBackAction:(id)__unused sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)__unused tableView numberOfRowsInSection:(NSInteger)__unused section {
    NSInteger count = journalData.count;
    NSString *countStr = [NSString stringWithFormat:@"%ld notes", (long)count];
    countLabel.text = countStr;
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"cell";
    JournalTableViewCell *cell = (JournalTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if(cell == nil) {
        UINib *nib = [UINib nibWithNibName:@"JournalTableViewCell" bundle:nil];
        [tableView registerNib:nib forCellReuseIdentifier:cellIdentifier];
        cell = (JournalTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    }
    JournalModel *dataModel = [[JournalModel alloc] init];
    [dataModel initData:journalData[indexPath.row]];
    cell.titleLabel.text = dataModel.title;
    cell.timeLabel.text = dataModel.time;
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)__unused tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    JournalModel *dataModel = [[JournalModel alloc] init];
    [dataModel initData:journalData[indexPath.row]];
    [self performSegueWithIdentifier:kEditJournalSegue sender:dataModel];
}

- (void)tableView:(UITableView *)__unused tableView commitEditingStyle:(UITableViewCellEditingStyle)__unused editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    JournalModel *dataModel = [[JournalModel alloc] init];
    [dataModel initData:journalData[indexPath.row]];
    
    DBGlobalManager *dbManager = [DBGlobalManager getSharedInstance];
    [dbManager deleteRecord:[dbManager getJournalTableName] tableID:(int)dataModel.tblID];
    
    [self initializeData];
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id)sender {
    [self.view endEditing:YES];
    
    if ([segue.identifier isEqualToString:kEditJournalSegue]) {
        JournalEditViewController* journalEditViewController = segue.destinationViewController;
        
        journalEditViewController.dataModel = sender;
    }
}
@end
