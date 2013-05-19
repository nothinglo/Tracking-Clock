//
//  UGDataSource.m
//  Tracking Clock
//
//  Created by nothinglo on 13/5/14.
//  Copyright (c) 2013年 nothinglo. All rights reserved.
//

#import "UGDataSource.h"
#import <MapKit/MapKit.h>
#import "UGImagePin.h"

static NSString * const resouce = @"tracking";
static NSString * const resouceType = @"plist";

static NSString *UGDataSourceCacheKeyMembers = @"UGDataSource.Cache.%@.members";
static NSString *UGDataSourceCacheKeyAnnotations = @"UGDataSource.Cache.Annotations";

NSString * const UGDataSourceDictKeyLocations = @"Locations";
NSString * const UGDataSourceDictKeyMembers = @"Members";
NSString * const UGDataSourceDictKeyName = @"Name";
NSString * const UGDataSourceDictKeyImage = @"Image";
NSString * const UGDataSourceDictKeyLatitude = @"Latitude";
NSString * const UGDataSourceDictKeyLongitude = @"Longitude";

const CGFloat distanceRadius = 1000;

@implementation UGDataSource

+ (UGDataSource *)sharedDataSource {
    static dispatch_once_t once;
    static UGDataSource *sharedDataSource = nil;
    dispatch_once(&once, ^ {
        sharedDataSource = [[self alloc] init];
    });
    return sharedDataSource;
}
- (id)init {
    if (self = [super init]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:resouce ofType:resouceType];
        trackingList = [NSDictionary dictionaryWithContentsOfFile:path];
        cache = [[NSCache alloc] init];
    }
    return self;
}

- (void)refresh {
    NSString *path = [[NSBundle mainBundle] pathForResource:resouce ofType:resouceType];
    trackingList = [NSDictionary dictionaryWithContentsOfFile:path];
    [self cleanCache];
}

- (void)cleanCache {
    [cache removeAllObjects];
}
- (NSUInteger)numberOfLocations {
    return [trackingList[UGDataSourceDictKeyLocations] count];
}
- (NSDictionary *)dictionaryOfLocationWithIndex:(NSUInteger)index {
    if([self numberOfLocations] <= index) return nil;
    return trackingList[UGDataSourceDictKeyLocations][index];
}
- (NSArray *)arrayOfMembers {
    return trackingList[UGDataSourceDictKeyMembers];
}
- (NSArray *)arrayOfLocations {
    return trackingList[UGDataSourceDictKeyLocations];
}
- (NSArray *)arrayOfMembersInLocation:(NSDictionary *)location {
    NSString *cacheKey = [NSString stringWithFormat:UGDataSourceCacheKeyMembers, location];
    NSArray *members = [cache objectForKey:cacheKey];
    
    if (!members) {
        NSArray *allMembers = [self arrayOfMembers];
        NSArray *locations = [self arrayOfLocations];
        NSMutableArray *result = [NSMutableArray new];
        for(NSDictionary *memberDic in allMembers) {
            CLLocationDegrees latitude = [memberDic[UGDataSourceDictKeyLatitude] doubleValue];
            CLLocationDegrees longitude = [memberDic[UGDataSourceDictKeyLongitude] doubleValue];
            CLLocation *loc = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
            CGFloat distance = distanceRadius;
            NSString *dic = nil;
            for(NSDictionary *locationDic in locations) {
                CLLocationDegrees latitude2 = [locationDic[UGDataSourceDictKeyLatitude] doubleValue];
                CLLocationDegrees longitude2 = [locationDic[UGDataSourceDictKeyLongitude] doubleValue];
                CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:latitude2 longitude:longitude2];
                if([loc distanceFromLocation:loc2] < distance) {
                    distance = [loc distanceFromLocation:loc2];
                    dic = locationDic[UGDataSourceDictKeyName];
                }
            }
            if([dic isEqualToString:location[UGDataSourceDictKeyName]]) {
                [result addObject:memberDic];
            }
        }
        members = [NSArray arrayWithArray:result];
        [cache setObject:members forKey:cacheKey];
    }
    return members;
}
- (NSArray *)arrayOfAnnotations {
    NSString *cacheKey = UGDataSourceCacheKeyAnnotations;
    NSArray *annotations = [cache objectForKey:cacheKey];
    if(!annotations) {
        NSArray *locations = [self arrayOfLocations];
        NSMutableArray *result = [NSMutableArray new];
        for(NSDictionary *locationDic in locations) {
            NSArray *members = [self arrayOfMembersInLocation:locationDic];
            MKPointAnnotation *ann = [MKPointAnnotation new];
            CLLocationDegrees latitude = [locationDic[UGDataSourceDictKeyLatitude] doubleValue];
            CLLocationDegrees longitude = [locationDic[UGDataSourceDictKeyLongitude] doubleValue];
            ann.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
            ann.title = locationDic[UGDataSourceDictKeyName];
            [result addObject:ann];
            for(NSDictionary *member in members) {
                UGImagePin *annotation = [UGImagePin new];
                CLLocationDegrees latitude = [member[UGDataSourceDictKeyLatitude] doubleValue];
                CLLocationDegrees longitude = [member[UGDataSourceDictKeyLongitude] doubleValue];
                annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
                annotation.title = member[UGDataSourceDictKeyName];
                UIImage *image = [UIImage imageNamed:member[UGDataSourceDictKeyImage]];
                CGFloat width = image.size.width;
                CGFloat height = image.size.height;
                CGFloat border = (width > height) ? height : width;
                CGImageRef ref = CGImageCreateWithImageInRect(image.CGImage, CGRectMake(0, 0, border, border));
                annotation.image = [UIImage imageWithCGImage:ref];
                CGImageRelease(ref);
                [result addObject:annotation];
            }
        }
        annotations = [NSArray arrayWithArray:result];
        [cache setObject:annotations forKey:cacheKey];
    }
    return annotations;
}

@end
