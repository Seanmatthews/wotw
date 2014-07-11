//
//  SecondViewController.m
//  wotw
//
//  Created by sean matthews on 7/7/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

#import "SecondViewController.h"
#import "Location.h"
#import "MessageRepo.h"

@interface SecondViewController ()
{
    NSUInteger visibleAnnotationCount;
}

- (void)registerForNotifications;
- (void)receivedFirstLocation;
- (void)reloadMapAnnotations;
- (void)addAnnotationWithMessage:(NSString*)message atCoord:(CLLocationCoordinate2D)coord;

@end

@implementation SecondViewController


static int const PrivateKVOContextTwo;

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self registerForNotifications];
    _mapView.showsUserLocation = YES;
    visibleAnnotationCount = 0;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedFirstLocation)
                                                 name:@"LocationUpdateNotification"
                                               object:nil];
    
    // KVO
    [[MessageRepo sharedInstance] addObserver:self
                                   forKeyPath:@"mapMessages"
                                      options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                      context:nil];
}

- (void)reloadMapAnnotations
{
    
}


#pragma mark - Notifications

- (void)receivedFirstLocation
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LocationUpdateNotification" object:nil];
    
    // Center map on user location & set tracking
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([[Location sharedInstance] currentLocation], 800, 800);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    [_mapView setCenterCoordinate:[[Location sharedInstance] currentLocation] animated:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    NSLog(@"HERE");
    if (context == &PrivateKVOContextTwo) {
//        NSArray* oldChatList = [change objectForKey:@"mapMessages"];
        [self reloadMapAnnotations];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - UI Behaviors

- (IBAction)pressedLocateButton:(id)sender
{
    // TODO change zoom back to default region?
    [_mapView setCenterCoordinate:[[Location sharedInstance] currentLocation] animated:YES];
}


#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [[MessageRepo sharedInstance] refreshMapMessagesWithRegion:mapView.region];
    

}


// TODO need this??? This method only customizes the pin
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation
{
    MKPinAnnotationView *annotationView = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"AnnotationView"];
    if (annotationView) {
        annotationView.annotation = annotation;
    }
    else {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                         reuseIdentifier:@"AnnotationView"];
    }
    annotationView.canShowCallout = YES;
    
//    visibleAnnotationCount = 0;
//    for (MKPointAnnotation *annotation in _mapView.annotations) {
//        if (MKMapRectContainsPoint(_mapView.visibleMapRect, MKMapPointForCoordinate(annotation.coordinate))) {
//            visibleAnnotationCount++;
//        }
//    }
    
    return annotationView;
}

// TODO Need this??? Might need it to show a custom callout view
//- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
//{
//    // TODO need this?
//}


#pragma mark - Map Annotations

- (void)addAnnotationWithMessage:(NSString*)message atCoord:(CLLocationCoordinate2D)coord
{
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coord;
    
    // TODO add message to mkpointannotation ???
}


@end
