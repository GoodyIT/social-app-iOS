//
//  QMHelpers.m
//  Q-municate
//
//  Created by Vitaliy Gorbachov on 7/19/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMHelpers.h"

CGRect CGRectOfSize(CGSize size) {
    
    return (CGRect) {CGPointZero, size};
}

NSString *QMStringForTimeInterval(NSTimeInterval timeInterval) {
    
    NSInteger minutes = (NSInteger)(timeInterval / 60);
    NSInteger seconds = (NSInteger)timeInterval % 60;
    
    NSString *timeStr = [NSString stringWithFormat:@"%zd:%02zd", minutes, seconds];
    
    return timeStr;
}

NSInteger iosMajorVersion() {
    
    static NSInteger version = 0;
    
    if (version == 0) {
        
        version = [UIDevice currentDevice].systemVersion.integerValue;
    }
    
    return version;
}

NSString* getTimeLog(NSString* date) {
    NSString* timeLog;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss yyyy:MM:dd"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:[[NSTimeZone localTimeZone] secondsFromGMT]/3600]];//[NSTimeZone
    
    NSDate *creationDate = [formatter dateFromString:date];
    
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    unsigned int unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitSecond | NSCalendarUnitYear;
    NSDateComponents *conversionInfo = [sysCalendar components:unitFlags fromDate:creationDate  toDate:[NSDate date] options:0];
    
    if (conversionInfo.year > 0) {
        timeLog = [NSString stringWithFormat:@"%ld years", (long)conversionInfo.year];
    } else if (conversionInfo.month > 0) {
        timeLog = [NSString stringWithFormat:@"%ld month", (long)conversionInfo.month];
    } else if (conversionInfo.day > 0) {
        timeLog = [NSString stringWithFormat:@"%ld days", (long)conversionInfo.day];
    } else if (conversionInfo.hour > 0) {
        timeLog = [NSString stringWithFormat:@"%ld hours", (long)conversionInfo.hour];
    } else if (conversionInfo.minute ) {
        timeLog = [NSString stringWithFormat:@"%ld minutes", (long)conversionInfo.minute ];
    } else  if (conversionInfo.second ){
        timeLog = [NSString stringWithFormat:@"%ld seconds", (long)conversionInfo.second ];
    } else {
        timeLog = @"Now";
    }
    return timeLog;
}

CGFloat getLabelHeight(UILabel* label)
{
    CGSize constraint = CGSizeMake(label.frame.size.width, CGFLOAT_MAX);
    CGSize size;
    
    NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
    CGSize boundingBox = [label.text boundingRectWithSize:constraint
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:@{NSFontAttributeName:label.font}
                                                  context:context].size;
    
    size = CGSizeMake(ceil(boundingBox.width), ceil(boundingBox.height));
    
    return size.height + 10;
}




inline void removeControllerFromNavigationStack(UINavigationController *navC, UIViewController *vc) {
    
    NSMutableArray *viewControllers = [navC.viewControllers mutableCopy];
    [viewControllers removeObject:vc];
    [navC setViewControllers:[viewControllers copy]];
}
