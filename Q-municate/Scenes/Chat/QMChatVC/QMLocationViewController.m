//
//  QMLocationViewController.m
//  Q-municate
//
//  Created by Vitaliy Gorbachov on 7/4/16.
//  Copyright © 2016 Quickblox. All rights reserved.
//

#import "QMLocationViewController.h"

#import "QMMapView.h"
#import "QMLocationButton.h"
#import "QMLocationPinView.h"

static const CGFloat kQMLocationButtonSize = 44.0f;
static const CGFloat kQMLocationButtonSpacing = 16.0f;

static const CGFloat kQMLocationPinXShift = 3.5f;

@interface QMLocationViewController () <CLLocationManagerDelegate, MKMapViewDelegate>
{
    QMMapView *_mapView;
    QMLocationButton *_locationButton;
    QMLocationPinView *_pinView;
    
    CLLocationManager *_locationManager;
    
    BOOL _initialPin;
    BOOL _userLocationChanged;
    BOOL _regionChanged;
}

@end

@implementation QMLocationViewController

#pragma mark - Construction

- (instancetype)init {
    
    self = [super init];
    if (self != nil) {
        
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithState:(QMLocationVCState)state {
    
    self = [super init];
    if (self != nil) {
        
        [self commonInit];
        
        _state = state;
        
        switch (state) {
                
            case QMLocationVCStateView:
                break;
                
            case QMLocationVCStateSend:
                [self configureSendState];
                break;
        }
    }
    
    return self;
}

- (instancetype)initWithState:(QMLocationVCState)state locationCoordinate:(CLLocationCoordinate2D)locationCoordinate {
    
    self = [self initWithState:state];
    if (self != nil) {
        
        [self setLocationCoordinate:locationCoordinate];
    }
    
    return self;
}

- (void)commonInit {
    
    self.title = NSLocalizedString(@"QM_STR_LOCATION", nil);
    
    _mapView = [[QMMapView alloc] initWithFrame:self.view.bounds];
    [_mapView setManipulationsEnabled:YES];
    [self applyEffect];
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _mapView.delegate = self;
    
    [self.view addSubview:_mapView];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 25, 13, 23)];
    [backButton setBackgroundImage:[UIImage imageNamed:@"close_blue"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(dismissScreen) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:backButton];
}

- (void)applyEffect
{
    // gradient effect at the top
    UIView *upperView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, _mapView.frame.size.width, 160.0f)];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = upperView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:255 green:255 blue:255 alpha:0.5] CGColor], (id)[[UIColor colorWithRed:255 green:255 blue:255 alpha:0] CGColor], nil];
    [upperView.layer insertSublayer:gradient atIndex:0];
    [_mapView addSubview:upperView];
    
    // gradient effect at the bottom
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, self.view.frame.size.height-140, self.view.frame.size.width, 140)];
    CAGradientLayer *bottomGradient = [CAGradientLayer layer];
    bottomGradient.frame = bottomView.bounds;
    bottomGradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:255 green:255 blue:255 alpha:0] CGColor], (id)[[UIColor colorWithRed:255 green:255 blue:255 alpha:1] CGColor], nil];
    [bottomView.layer insertSublayer:bottomGradient atIndex:0];
    [_mapView addSubview:bottomView];
}

- (void)configureSendState {
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    [_locationManager requestWhenInUseAuthorization];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"QM_STR_SEND", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_sendAction)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"QM_STR_CANCEL", nil) style:UIBarButtonItemStylePlain target:self action:@selector(_cancelAction)];
    
    CGFloat shift = kQMLocationButtonSize + kQMLocationButtonSpacing;
    _locationButton = [[QMLocationButton alloc]
                       initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds) - shift,
                                                CGRectGetHeight(self.view.bounds) - shift,
                                                kQMLocationButtonSize,
                                                kQMLocationButtonSize)];
    _locationButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [_locationButton addTarget:self action:@selector(_updateUserLocation) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_locationButton];
    
    _pinView = [[QMLocationPinView alloc] init];
    _pinView.frame = CGRectMake(CGRectGetWidth(_mapView.frame) / 2.0f - QMLocationPinViewOriginPinCenter,
                                CGRectGetHeight(_mapView.frame) / 2.0f - kQMLocationPinXShift,
                                CGRectGetWidth(_pinView.frame),
                                CGRectGetHeight(_pinView.frame));
    _pinView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    [_mapView addSubview:_pinView];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
 //   self.navigationController.navigationBarHidden = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    self.navigationController.navigationBarHidden = NO;

//    UIBarButtonItem *backButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
//    
//    [self.navigationItem setLeftBarButtonItems:@[backButtonItem] animated:YES];
}

- (void) dismissScreen
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Setters

- (void)setLocationCoordinate:(CLLocationCoordinate2D)locationCoordinate {
    
    [_mapView markCoordinate:locationCoordinate animated:NO];
}

#pragma mark - Private

- (void)_sendAction {
    
    self.sendButtonPressed(_mapView.centerCoordinate);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_cancelAction {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_showLocationRestrictedAlert {
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:NSLocalizedString(@"QM_STR_LOCATION_ERROR", nil)
                                          message:NSLocalizedString(@"QM_STR_NO_PERMISSIONS_TO_LOCATION", nil)
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_CANCEL", nil)
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction * _Nonnull __unused action) {
                                                          
                                                      }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"QM_STR_SETTINGS", nil)
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull __unused action) {
                                                          if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
                                                              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]  options:@{}
                                                                                       completionHandler:nil];
                                                          } else {
                                                              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                                                          }
                       
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)_updateUserLocation {
    
    if (_userLocationChanged || _regionChanged) {
        
        [_locationButton setLoadingState:YES];
        [self _setRegionForCoordinate:_mapView.userLocation.coordinate];
        
        _userLocationChanged = NO;
        _regionChanged = NO;
    }
}

- (void)_setRegionForCoordinate:(CLLocationCoordinate2D)coordinate {
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, MKCoordinateSpanDefaultValue, MKCoordinateSpanDefaultValue);
    [_mapView setRegion:region animated:YES];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)__unused manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    switch (status) {
            
        case kCLAuthorizationStatusNotDetermined:
            break;
            
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            
            _locationButton.hidden = YES;
            [self _showLocationRestrictedAlert];
            break;
            
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            
            _locationButton.hidden = NO;
            _mapView.showsUserLocation = YES;
            break;
    }
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)__unused mapView didUpdateUserLocation:(MKUserLocation *)__unused userLocation {
    
    _userLocationChanged = YES;
    
    if (!_initialPin) {
        
        [self _updateUserLocation];
        _initialPin = YES;
    }
}

- (void)mapView:(MKMapView *)__unused mapView regionWillChangeAnimated:(BOOL)__unused animated {
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [_pinView setPinRaised:YES animated:YES];
}

- (void)mapView:(MKMapView *)__unused mapView regionDidChangeAnimated:(BOOL)__unused animated {
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    if (_locationButton.loadingState) {
        
        [_locationButton setLoadingState:NO];
    }
    else {
        
        _regionChanged = YES;
    }
    
    [_pinView setPinRaised:NO animated:YES];
}

@end
