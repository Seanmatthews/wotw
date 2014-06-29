//
//  MessageAnnotationView.h
//  wotw
//
//  Created by sean matthews on 6/29/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MessageAnnotationView : MKPinAnnotationView

@property (nonatomic, strong) NSString* messageText;

@end
