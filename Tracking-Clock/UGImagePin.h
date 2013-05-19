//
//  UGImagePin.h
//  Tracking Clock
//
//  Created by nothinglo on 13/5/17.
//  Copyright (c) 2013年 nothinglo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface UGImagePin : NSObject <MKAnnotation> {
    CLLocationCoordinate2D coordinate;
    NSString *title;
    NSString *subtitle;
    UIImage *image;
}
@property(nonatomic, assign) CLLocationCoordinate2D coordinate;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *subtitle;
@property(nonatomic, copy) UIImage *image;

@end
