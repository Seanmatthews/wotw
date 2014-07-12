//
//  CustomAnnotation.m
//  wotw
//
//  Created by sean matthews on 7/12/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

#import "CustomAnnotation.h"

@implementation CustomAnnotation

@synthesize coordinate;
@synthesize title;
@synthesize subtitle;


- (id)initWithLocation:(CLLocationCoordinate2D)coord {
    self = [super init];
    if (self) {
        coordinate = coord;
    }
    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    coordinate = newCoordinate;
}

@end
