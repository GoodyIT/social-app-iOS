//
//  HashtagModel.m
//  Reach-iOS
//
//  Created by AlexFill on 21.01.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "HashtagModel.h"

@implementation HashtagModel

+ (HashtagModel *)getHashtagFromDictionary:(NSDictionary *)dictonary {
    HashtagModel *hashtag = [HashtagModel new];
    
    hashtag.hashtagID = [dictonary valueForKey:@"id"];
    hashtag.hashtagText = [dictonary valueForKey:@"hashtag"];
    
    return hashtag;
}

@end
