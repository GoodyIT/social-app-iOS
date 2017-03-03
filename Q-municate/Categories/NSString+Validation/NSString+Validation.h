//
//  NSString+Validation.h
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Validation)

- (BOOL)isEmptyOrWhiteSpace;
- (BOOL)isEmailValid;
- (BOOL)isHashtagValid;


@end
