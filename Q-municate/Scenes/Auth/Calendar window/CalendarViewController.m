//
//  CalendarViewController.m
//  Pile
//
//  Created by Admin on 2016-11-14.
//  Copyright © 2016 Admin. All rights reserved.
//

#import "CalendarViewController.h"
#import "QMAlert.h"

@interface CalendarViewController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@end

@implementation CalendarViewController

-(BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.title = @"Birthday";
    self.contentSizeInPopup = CGSizeMake(300, 350);
    self.landscapeContentSizeInPopup = CGSizeMake(350, 300);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Select" style:UIBarButtonItemStylePlain target:self action:@selector(nextBtnDidTap)];
}

- (IBAction)nextBtnDidTap
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSDate *pickerDate = [_datePicker date];
    
    NSDate *restrctDate = [dateFormat dateFromString:@"2001-01-01"];
    
    if ([pickerDate compare:restrctDate] == NSOrderedDescending) {
        [QMAlert showAlertWithMessage:@"Sorry you must be born before 12/31/2000 to use this app" actionSuccess:NO inViewController:self];
        return;
    }

    [QMNetworkManager sharedManager].installDate = [dateFormat stringFromDate:pickerDate];
  //  [dateFormat setDateFormat:@"yyyy-MM-dd"];
 //   [QMNetworkManager sharedManager].installDateTemp = [dateFormat stringFromDate:pickerDate];
    [self.popupController dismiss];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
