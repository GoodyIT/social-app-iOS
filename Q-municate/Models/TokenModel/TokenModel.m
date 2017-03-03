//
//  TokenModel.m
//  Reach-iOS
//
//  Created by MaksymRachytskyy on 11/22/15.
//  Copyright © 2015 Maksym Rachytskyy. All rights reserved.
//

#import "TokenModel.h"
#import "KeychainWrapper.h"

@interface TokenModel()

@property (strong, nonatomic) KeychainWrapper *wrapper;

@end

@implementation TokenModel

+ (TokenModel *)sharedInstance {
    static TokenModel *model = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        model = [[TokenModel alloc] init];
    });
    
    return model;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.wrapper = [[KeychainWrapper alloc] init];
    }
    
    return self;
}

- (void)setToken:(NSString *)token {
//    [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"ReachToken"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.wrapper mySetObject:token forKey:(id)kSecAttrService];
}

- (NSString *)token {
   NSString* str = [self.wrapper myObjectForKey:(id)kSecAttrService];
//   NSString* str  = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReachToken"];
    return str != nil ? str : @"";
}

- (void)clearToken {
    [self.wrapper mySetObject:@"" forKey:(id)kSecAttrService];
//    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"ReachToken"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}



@end
