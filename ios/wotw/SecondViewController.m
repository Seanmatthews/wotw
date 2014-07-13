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
#import "CustomAnnotation.h"
#import "CalloutMapAnnotationView.h"

@interface SecondViewController ()

- (void)registerForNotifications;
- (void)receivedFirstLocation;
- (void)addAnnotationWithMessage:(NSString*)message atCoord:(CLLocationCoordinate2D)coord;
- (void)centerOnUserWithLatDelta:(CGFloat)d1 longDelta:(CGFloat)d2;

@end

@implementation SecondViewController

@synthesize mapView = _mapView;


- (void)viewDidLoad
{
    [super viewDidLoad];
	[self registerForNotifications];
    _mapView.userTrackingMode = MKUserTrackingModeFollow;
    [self centerOnUserWithLatDelta:0.2 longDelta:0.2];
    
    UIPanGestureRecognizer* panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDragMap:)];
    [panRec setDelegate:self];
    [_mapView addGestureRecognizer:panRec];
    
    [[MessageRepo sharedInstance] refreshMapMessagesWithRegion:_mapView.region];
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
    if ([keyPath isEqual:@"mapMessages"]) {
        for (id d in change[NSKeyValueChangeNewKey]) {
            if (d) {
                CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([[d objectForKey:@"lat"] doubleValue],
                                                                          [[d objectForKey:@"long"] doubleValue]);
                [self addAnnotationWithMessage:[d objectForKey:@"message"]
                                       atCoord:coord];
            }
        }
    }
}


#pragma mark - UI Behaviors

- (IBAction)pressedLocateButton:(id)sender
{
    [_mapView setCenterCoordinate:[[Location sharedInstance] currentLocation] animated:YES];
}


#pragma mark - MKMapViewDelegate

//- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
//{
//    [_mapView removeAnnotations:_mapView.annotations];
//    [[MessageRepo sharedInstance] refreshMapMessagesWithRegion:mapView.region];
//}

- (void)centerOnUserWithLatDelta:(CGFloat)d1 longDelta:(CGFloat)d2
{
    MKCoordinateRegion mapRegion;
    mapRegion.center = [[Location sharedInstance] currentLocation];
    mapRegion.span.latitudeDelta = d1;
    mapRegion.span.longitudeDelta = d2;

    [_mapView setRegion:mapRegion animated: YES];
}

//-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
//{
//    MKCoordinateRegion mapRegion;
//    mapRegion.center = mapView.userLocation.coordinate;
//    mapRegion.span.latitudeDelta = 0.2;
//    mapRegion.span.longitudeDelta = 0.2;
//    
//    [mapView setRegion:mapRegion animated: YES];
//}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
	if ([view.annotation isKindOfClass:[BasicMapAnnotation class]]) {
        
		if (_calloutAnnotation == nil) {
			_calloutAnnotation = [[CustomAnnotation alloc] initWithLocation:view.annotation.coordinate];
		} else {
			_calloutAnnotation.coordinate = view.annotation.coordinate;
		}
        
        _calloutAnnotation.title = view.annotation.title;
		[_mapView addAnnotation:_calloutAnnotation];
		_selectedAnnotationView = view;
	}
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
	if (_calloutAnnotation && [view.annotation isKindOfClass:[BasicMapAnnotation class]]) {
		[_mapView removeAnnotation: _calloutAnnotation];
	}
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	if ([annotation isKindOfClass:[CustomAnnotation class]] ) {
		CalloutMapAnnotationView *calloutMapAnnotationView = (CalloutMapAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"CalloutAnnotation"];
        
		if (!calloutMapAnnotationView) {
			calloutMapAnnotationView = [[CalloutMapAnnotationView alloc] initWithAnnotation:annotation
																			 reuseIdentifier:@"CalloutAnnotation"];
			calloutMapAnnotationView.contentHeight = 78.0f;
            UILabel *messageLabel = [[UILabel alloc] init];
            messageLabel.frame = CGRectMake(20, 2, 258, 74);
            messageLabel.backgroundColor = [UIColor clearColor];
            messageLabel.font = [UIFont systemFontOfSize:13.];
            messageLabel.numberOfLines = 0;
            messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
			[calloutMapAnnotationView.contentView addSubview:messageLabel];
		}
        for (id view in calloutMapAnnotationView.contentView.subviews) {
            if ([view isKindOfClass:[UILabel class]]) {
                ((UILabel *)view).text = annotation.title;
            }
        }
        
		calloutMapAnnotationView.parentAnnotationView = _selectedAnnotationView;
		calloutMapAnnotationView.mapView = self.mapView;
		return calloutMapAnnotationView;
	}
    else if ([annotation isKindOfClass:[BasicMapAnnotation class]]) {
		MKPinAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
																			   reuseIdentifier:@"CustomAnnotation"];
		annotationView.canShowCallout = NO;
		annotationView.pinColor = MKPinAnnotationColorRed;
        annotationView.annotation = annotation;
        
		return annotationView;
	}
	
	return nil;
}


#pragma mark - Map Annotations

- (void)addAnnotationWithMessage:(NSString*)message atCoord:(CLLocationCoordinate2D)coord
{
    BasicMapAnnotation *annotation = [[BasicMapAnnotation alloc] init];
    annotation.title = message;
    annotation.coordinate = coord;
    
    [_mapView addAnnotation:annotation];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

// Use this instead of regiondidchange because region changes happen even when a user doesn't drag the map
- (void)didDragMap:(UIGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded){
//        [_mapView removeAnnotations:_mapView.annotations];
        [[MessageRepo sharedInstance] refreshMapMessagesWithRegion:_mapView.region];
    }
}


@end
