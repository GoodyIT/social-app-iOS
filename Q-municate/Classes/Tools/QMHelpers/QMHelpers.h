//
//  QMHelpers.h
//  Q-municate
//
//  Created by Vitaliy Gorbachov on 7/19/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>

CGRect CGRectOfSize(CGSize size);

NSString *QMStringForTimeInterval(NSTimeInterval timeInterval);

NSInteger iosMajorVersion();

NSString* getTimeLog(NSString* date);

CGFloat getLabelHeight(UILabel* label);

extern void removeControllerFromNavigationStack(UINavigationController *navC, UIViewController *vc);
