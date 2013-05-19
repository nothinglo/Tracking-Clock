//
//  UGDataSource.h
//  Tracking Clock
//
//  Created by nothinglo on 13/5/14.
//  Copyright (c) 2013年 nothinglo. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const UGDataSourceDictKeyLocations;
extern NSString * const UGDataSourceDictKeyMembers;
extern NSString * const UGDataSourceDictKeyName;
extern NSString * const UGDataSourceDictKeyImage;
extern NSString * const UGDataSourceDictKeyLatitude;
extern NSString * const UGDataSourceDictKeyLongitude;

@interface UGDataSource : NSObject {
    NSDictionary *trackingList;
    NSCache *cache;
}
+ (UGDataSource *)sharedDataSource;
- (void)refresh;
- (void)cleanCache;
- (NSUInteger)numberOfLocations;
- (NSDictionary *)dictionaryOfLocationWithIndex:(NSUInteger)index;
- (NSArray *)arrayOfMembers;
- (NSArray *)arrayOfLocations;
- (NSArray *)arrayOfMembersInLocation:(NSDictionary *)location;
- (NSArray *)arrayOfAnnotations;
@end
