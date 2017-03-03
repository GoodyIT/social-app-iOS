//
//  HashtagModel.h
//  Reach-iOS
//
//  Created by AlexFill on 21.01.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HashtagModel : NSObject

@property (nonatomic) NSNumber *hashtagID;
@property (copy, nonatomic) NSString *hashtagText;

+ (HashtagModel *)getHashtagFromDictionary:(NSDictionary *)dictonary;

@end
