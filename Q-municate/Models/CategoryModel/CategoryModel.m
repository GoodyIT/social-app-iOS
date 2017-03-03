//
//  GroupModel.m
//  Reach-iOS
//
//  Created by AlexFill on 03.02.16.
//  Copyright © 2016 Maksym Rachytskyy. All rights reserved.
//

#import "CategoryModel.h"

@implementation CategoryModel

+ (CategoryModel *)getCategoryFromResponse:(NSDictionary *)response {
    CategoryModel *category = [CategoryModel new];
    
    category.categoryID = [response valueForKey:@"id"];
    category.name = [response valueForKey:@"name"];
    category.countOfGroups = [response valueForKey:@"count_circles"];
    
    return category;
}

+ (NSArray *)getListOfCategoriesFromResponse:(NSDictionary *)response {
    NSMutableArray *categories = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dictionary in response) {
        [categories addObject:[CategoryModel getCategoryFromResponse:dictionary]];
    }
    
    return [categories mutableCopy];
}



@end
