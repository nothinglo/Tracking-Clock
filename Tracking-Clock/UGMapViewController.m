//
//  UGMapViewController.m
//  Tracking Clock
//
//  Created by nothinglo on 13/5/17.
//  Copyright (c) 2013年 nothinglo. All rights reserved.
//

#import "UGMapViewController.h"
#import "UGDataSource.h"
#import "UGImagePin.h"

@interface UGMapViewController ()

@end

@implementation UGMapViewController

- (void)dealloc {
    self.mapView.delegate = nil;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = (self.locationInfo)[UGDataSourceDictKeyName];
    CLLocationDegrees latitude = [(self.locationInfo)[UGDataSourceDictKeyLatitude] doubleValue];
    CLLocationDegrees longitude = [(self.locationInfo)[UGDataSourceDictKeyLongitude] doubleValue];
    self.location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    self.locationAnnotation = [MKPointAnnotation new];
    self.locationAnnotation.coordinate = self.location.coordinate;
    self.locationAnnotation.title = self.title;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) reSetAnnoations {
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotations:[[UGDataSource sharedDataSource] arrayOfAnnotations]];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reSetAnnoations];
    CLLocationCoordinate2D centerCoordinate = self.location.coordinate;
    MKCoordinateSpan newSpan = MKCoordinateSpanMake(0.01,0.01);
    [self.mapView setRegion:MKCoordinateRegionMake(centerCoordinate, newSpan)animated:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if([annotation class] == MKUserLocation.class || [annotation class] == [MKPointAnnotation class])
        return nil;
    UGImagePin *pin = (UGImagePin *)annotation;
    MKAnnotationView *annView;
    NSString * const ReuseIdentifier = @"UGImagePinAnnotation";
    annView = [mapView dequeueReusableAnnotationViewWithIdentifier:ReuseIdentifier];
    if( !annView ) {
        annView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ReuseIdentifier];       
    }
    annView.image = pin.image;
    annView.frame = CGRectMake(0, 0, 55, 55);
    annView.canShowCallout = YES;
    return annView;
}
@end
