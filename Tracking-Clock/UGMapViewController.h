//
//  UGMapViewController.h
//  Tracking Clock
//
//  Created by nothinglo on 13/5/17.
//  Copyright (c) 2013年 nothinglo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface UGMapViewController : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic) NSDictionary *locationInfo;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) MKPointAnnotation *locationAnnotation;
- (void) reSetAnnoations;

@end
