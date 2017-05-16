    //
//  LocationManager.m
//  reach-ios
//
//  Created by DenningIT on 04/03/2017.
//  Copyright © 2017 Quickblox. All rights reserved.
//

#import "LocationManager.h"

@implementation LocationManager
@synthesize stateName;
@synthesize lastLoggedDateTime;
@synthesize cityName;
@synthesize countryName;
@synthesize serverStatus;

+ (LocationManager *)sharedManager {
    static LocationManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[LocationManager alloc] init];
    });
    
    return manager;
}

#pragma mark -  Lifecycle

- (instancetype)init {
    if (self = [super init]) {
        [self initManager];
    }
    
    return self;
}

- (void)initManager
{
    self.manager = [[AFHTTPSessionManager  alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    self.manager.responseSerializer =  [AFJSONResponseSerializer serializer];
    self.manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", nil];
    
//    self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
////    self.manager.requestSerializer.timeoutInterval= [[[NSUserDefaults standardUserDefaults] valueForKey:@"timeoutInterval"] longValue];
//    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//    [self.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    lastLoggedDateTime = [[NSDate alloc] init];
    cityName = @"";
    countryName = @"";
    serverStatus = @"";
}


-(void)goToLoginController{
    [[[QMCore instance] logout] continueWithBlock:^id _Nullable(BFTask * _Nonnull t) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Auth" bundle:nil];
        UINavigationController *loginController = [storyboard instantiateViewControllerWithIdentifier:@"startNavigationController"];
        
        UIView *snapShot = [[UIApplication sharedApplication].delegate.window snapshotViewAfterScreenUpdates:YES];
        [loginController.view addSubview:snapShot];
        [UIApplication sharedApplication].delegate.window.rootViewController = loginController;
        [UIView animateWithDuration:1.0 animations:^{
            snapShot.layer.opacity = 0;
            snapShot.layer.transform = CATransform3DMakeScale(1.5, 1.5, 1.5);
        } completion:^(BOOL __unused finished) {
            [snapShot removeFromSuperview];
            [[UIApplication sharedApplication].delegate.window makeKeyAndVisible];
        }];
        return nil;
    }];
}

- (void) updateLocate
{
    NSDictionary *params = @{
                                 @"token":[TokenModel sharedInstance].token,
                                 @"country_name": [LocationManager sharedManager].countryName,
                                 @"city_name": [LocationManager sharedManager].cityName,
                                 @"state_name": [LocationManager sharedManager].stateName,
                                 @"latitude": [NSNumber numberWithDouble: [LocationManager sharedManager].oldLocation.latitude],
                                 @"longitude": [NSNumber numberWithDouble: [LocationManager sharedManager].oldLocation.longitude]
                                 };
    
    [[Mixpanel sharedInstance] track:@"Location Update "
                          properties:@{
                                       @"path": @"appdelegate",
                                       @"state" : @"before upload",
                                       @"params": params
                                       }];
    
    if  ([[TokenModel sharedInstance].token isEqualToString:@""])
    {
        [[Mixpanel sharedInstance] track:@"Token - error "
                              properties:@{
                                           @"path": updateLocate,
                                           @"params": params
                                           }];
        return;
    }
    
    NSString *URLString = [baseURLString stringByAppendingString:updateLocate];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:URLString parameters:nil error:nil];
    
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [req setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    [req setTimeoutInterval:100.0];
    
    @weakify(self);
    [[self.manager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull __unused response, id  _Nullable __unused responseObject, NSError * _Nullable error) {
        @strongify(self);
        [LocationManager sharedManager].serverStatus = @"";
        if(error){
            [[Mixpanel sharedInstance] track:@"Location Update -error "
                                  properties:@{
                                               @"path": @"appdelegate",
                                               @"state" : @"before upload",
                                               @"param": params,
                                               @"error": error.localizedDescription
                                               }];
            if  ([error.localizedDescription isEqualToString:@"token doesn't exist"])
                [[Mixpanel sharedInstance] track:@"Token - error "
                                      properties:@{
                                                   @"path": updateLocate,
                                                   @"params": params,
                                                   @"error": error.localizedDescription
                                                   }];
            [self goToLoginController];
            return;
        }
    }]  resume];

//    
//    [self.manager POST:[baseURLString stringByAppendingString:updateLocate] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull __unused task, id  _Nullable __unused responseObject) {
//        
//
//    } failure:^(NSURLSessionDataTask * _Nullable __unused task, NSError * _Nonnull error) {
//        [[Mixpanel sharedInstance] track:@"Location Update -error "
//                              properties:@{
//                                           @"path": @"appdelegate",
//                                           @"state" : @"before upload",
//                                           @"param": params,
//                                           @"error": error.localizedDescription
//                                           }];
//        if([error.localizedDescription isEqualToString:@"token doesn't exist"]){
//            if  (error)
//                [[Mixpanel sharedInstance] track:@"Token - error "
//                                      properties:@{
//                                                   @"path": updateLocate,
//                                                   @"params": params,
//                                                   @"error": error.localizedDescription
//                                                   }];
//            [self goToLoginController];
//            return;
//        }
//    }];
}

@end
