//
//  GroupModel.h
//  Reach-iOS
//
//  Created by AlexFill on 03.02.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CategoryModel : NSObject

@property (strong, nonatomic) NSNumber *categoryID;
@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) NSNumber *countOfGroups;

+ (CategoryModel *)getCategoryFromResponse:(NSDictionary *)response;
+ (NSArray *)getListOfCategoriesFromResponse:(NSDictionary *)response;

@end
