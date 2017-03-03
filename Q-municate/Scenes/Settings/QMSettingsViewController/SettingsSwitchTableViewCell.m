//
//  SettingsSwitchTableViewCell.m
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import "SettingsSwitchTableViewCell.h"
#import "DataManager.h"

@implementation SettingsSwitchTableViewCell


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    
    // Configure the view for the selected state
}

- (IBAction)switchValueChange:(id) __unused sender {
    if (self.cellType == SettingsCellPhoneCall) {
        [[DataManager sharedManager] setIsCallRing:[NSNumber numberWithBool:self.typeSwitch.isOn]];
    } else {
        [[DataManager sharedManager] setIsCallVibrate:[NSNumber numberWithBool:self.typeSwitch.isOn]];
    }
}

@end
