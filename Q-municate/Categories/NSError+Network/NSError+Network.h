//
//  NSError+Network.h
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSError (Network)

+ (NSString *)errorLocalizedDescriptionForCode:(NSInteger)errorCode;

@end
