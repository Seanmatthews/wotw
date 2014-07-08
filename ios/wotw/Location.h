//
//  Location.h
//  wotw
//
//  Created by sean matthews on 7/7/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

@import Foundation;
@import CoreLocation;


@interface Location : NSObject <CLLocationManagerDelegate>

@property (atomic) long long currentLat;
@property (atomic) long long currentLong;
@property (atomic) CLLocationCoordinate2D currentLocation;

- (id)init;
- (void)startService;
- (void)stopService;
- (CGFloat)milesToCurrentLocationFrom:(CLLocationCoordinate2D)coords;
- (NSUInteger)metersToCurrentLocationFrom:(CLLocationCoordinate2D)coords;
- (NSArray*)coordsAtDistance:(NSNumber*)dist;

+ (id)sharedInstance;
+ (double)fromLongLong:(long long)storedCoord;
+ (CLLocationCoordinate2D)fromLongLongLatitude:(long long)latitude Longitude:(long long)longitude;
+ (long long)toLongLong:(double)coord;
+ (CGFloat)milesBetweenSource:(CLLocationCoordinate2D)firstCoords andDestination:(CLLocationCoordinate2D)secondCoords;
+ (long long)metersFromMiles:(CGFloat)miles;

@end
