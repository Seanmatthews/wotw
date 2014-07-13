//
//  CustomAnnotation.h
//  wotw
//
//  Created by sean matthews on 7/12/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

@import Foundation;
@import MapKit;

@interface CustomAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
//@property (nonatomic, copy) NSString *subtitle;

- (id)initWithLocation:(CLLocationCoordinate2D)coord;
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;

@end
