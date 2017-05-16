//
//  LocationManager.h
//  reach-ios
//
//  Created by DenningIT on 04/03/2017.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>

@interface LocationManager : NSObject

@property(nonatomic, strong) AFHTTPSessionManager  *manager;

@property (strong, nonatomic) NSDate*       lastLoggedDateTime;
@property (assign, nonatomic) CLLocationCoordinate2D     oldLocation;
@property(strong, nonatomic) NSString       *countryName;
@property(strong, nonatomic) NSString       *cityName;
@property(strong, nonatomic) NSString       *stateName;

@property(strong, nonatomic) NSString       *serverStatus;

+ (LocationManager *)sharedManager;

- (void)updateLocate;

@end
