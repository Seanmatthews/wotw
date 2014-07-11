//
//  SecondViewController.h
//  wotw
//
//  Created by sean matthews on 7/7/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

@import UIKit;
@import MapKit;

@interface SecondViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic, strong) IBOutlet MKMapView *mapView;

- (IBAction)pressedLocateButton:(id)sender;

@end
