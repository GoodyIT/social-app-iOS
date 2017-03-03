//
//  SettingsSwitchTableViewCell.h
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SettingsCell) {
    SettingsCellPhoneCall,
    SettingsCellPhoneVibration
};

@interface SettingsSwitchTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UISwitch *typeSwitch;
@property (assign, nonatomic) SettingsCell cellType;

@end
