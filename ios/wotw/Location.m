//
//  Location.m
//  wotw
//
//  Created by sean matthews on 7/7/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

#import "Location.h"
@import MapKit;


@implementation Location
{
    CLLocationManager *locationManager;
    NSMutableArray *locationMeasurements;
    CLLocation *bestEffortAtLocation;
    dispatch_queue_t backgroundQueue;
    dispatch_source_t timerSource;
}

static const double kDegreesToRadians = M_PI / 180.0;
//static const double kRadiansToDegrees = 180.0 / M_PI;
static const double MILES_METERS = 1609.34;

- (id)init
{
    self = [super init];
    if (self) {
        // Location services
        locationMeasurements = [[NSMutableArray alloc] init];
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        // This is the most important property to set for the manager.
        // It ultimately determines how the manager will attempt to
        // acquire location and thus, the amount of power that
        // will be consumed.
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters; //kCLLocationAccuracyBest;//[[setupInfo objectForKey:kSetupInfoKeyAccuracy] doubleValue];
        
        _currentLocation = CLLocationCoordinate2DMake([Location fromLongLong:_currentLat], [Location fromLongLong:_currentLong]);
    }
    return self;
}

+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
        // Additional initialization can go here
    });
    return _sharedObject;
}

- (void)startService
{
    [locationManager startUpdatingLocation];
}

- (void)stopService
{
    [locationManager stopUpdatingLocation];
}


#pragma mark - CoreLocation functions

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    _currentLocation = [(CLLocation*)[locations lastObject] coordinate];
    _currentLat = [Location toLongLong:_currentLocation.latitude];
    _currentLong = [Location toLongLong:_currentLocation.longitude];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationUpdateNotification" object:self];
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // The location "unknown" error simply means the manager
    // is currently unable to get the location.
    // We can ignore this error for the scenario of getting
    // a single location fix, because we already have a
    // timeout that will stop the location manager to save power.
    if ([error code] != kCLErrorLocationUnknown) {
        [self stopService];
    }
}


#pragma mark - Utility Class Methods

+ (double)fromLongLong:(long long)storedCoord
{
    return (((double)storedCoord/1000000.) - 400.);
}

+ (long long)toLongLong:(double)coord
{
    return (long long)((coord + 400.) * 1000000.);
}

+ (CLLocationCoordinate2D)fromLongLongLatitude:(long long)latitude Longitude:(long long)longitude
{
    CLLocationCoordinate2D ret;
    ret.latitude = [Location fromLongLong:latitude];
    ret.longitude = [Location fromLongLong:longitude];
    return ret;
}

+ (CGFloat)milesBetweenSource:(CLLocationCoordinate2D)firstCoords andDestination:(CLLocationCoordinate2D)secondCoords
{
    
    double earthRadius = 6371.01; // Earth's radius in Kilometers
	
	// Get the difference between our two points then convert the difference into radians
	double nDLat = (firstCoords.latitude - secondCoords.latitude) * kDegreesToRadians;
	double nDLon = (firstCoords.longitude - secondCoords.longitude) * kDegreesToRadians;
	
	double fromLat =  secondCoords.latitude * kDegreesToRadians;
	double toLat =  firstCoords.latitude * kDegreesToRadians;
	
	double nA =	pow ( sin(nDLat/2), 2 ) + cos(fromLat) * cos(toLat) * pow ( sin(nDLon/2), 2 );
	
	double nC = 2 * atan2( sqrt(nA), sqrt( 1 - nA ));
	double nD = earthRadius * nC;
	
	return nD * 1000. / MILES_METERS; // Return our calculated distance in MILES
}

+ (long long)metersFromMiles:(CGFloat)miles
{
    return (long long)(MILES_METERS * miles);
}

// Given a GPS coordiante in the world, and a distance surrounding that coordinate,
// return an array with two CLLocation objects. The first denotes a minimum
// latitude and longitude, the second denotes a maximum latitude and longitude.
// The two create a square around the origin coordinate.
- (NSArray*)coordsAtDistance:(NSNumber*)dist
{
    MKCoordinateRegion region =  MKCoordinateRegionMakeWithDistance(_currentLocation,
                                                                    [dist doubleValue],
                                                                    [dist doubleValue]);
    CLLocation *minCoords = [[CLLocation alloc]
                             initWithLatitude:(region.center.latitude - region.span.latitudeDelta)
                             longitude:(region.center.longitude - region.span.longitudeDelta)];
    CLLocation *maxCoords = [[CLLocation alloc]
                             initWithLatitude:(region.center.latitude + region.span.latitudeDelta)
                             longitude:(region.center.longitude + region.span.longitudeDelta)];
    
    return [NSArray arrayWithObjects:minCoords, maxCoords, nil];
}


#pragma mark - Utility Member Methods

- (CGFloat)milesToCurrentLocationFrom:(CLLocationCoordinate2D)coords
{
    return [Location milesBetweenSource:_currentLocation andDestination:coords];
}

- (NSUInteger)metersToCurrentLocationFrom:(CLLocationCoordinate2D)coords
{
    return [self milesToCurrentLocationFrom:coords] * MILES_METERS;
}


@end

