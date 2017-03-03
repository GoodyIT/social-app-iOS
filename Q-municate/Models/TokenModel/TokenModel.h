//
//  TokenModel.h
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TokenModel : NSObject

@property (copy, nonatomic) NSString *token;
@property (copy, nonatomic) NSNumber *currentUserID;


+ (TokenModel *)sharedInstance;
- (void)clearToken;

@end
