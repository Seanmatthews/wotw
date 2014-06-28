//
//  ViewController.h
//  wotw
//
//  Created by sean matthews on 3/18/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <AWSiOSSDK/SimpleDB/AmazonSimpleDBClient.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <UITextFieldDelegate, UIScrollViewDelegate, CLLocationManagerDelegate>
{
    NSArray* __weak listData;
    CGFloat nextNoteY;
    AmazonSimpleDBClient *sdbClient;
    CLLocationManager *locationManager;
    NSMutableArray *locationMeasurements;
    CLLocation *bestEffortAtLocation;
    UIImageView *bgImageView;
    MKMapView *mapView;
    UIImage *mapButtonImage;
    UIImage *wallButtonImage;
}

- (IBAction)mapViewButtonPressed:(id)sender;
- (IBAction)refreshButtonPressed:(id)sender;
- (IBAction)textFieldDidBeginEditing:(UITextField *)textField;
- (IBAction)textFieldDidEndEditing:(UITextField *)textField;
- (void)animateTextField: (UITextField*)textField up:(BOOL)up;
- (NSArray*)coordsAtDistance:(NSNumber*)dist fromCoord:(CLLocationCoordinate2D)coord;
- (NSMutableArray*)getFields:(NSString*)fields toDistance:(NSNumber*)dist;
- (void)populateMapView;
- (void)refresh;
- (void)stopUpdatingLocation:(NSString *)state;
- (NSString *)GetUUID;


@property (weak, nonatomic) NSArray* listData;
@property (nonatomic, retain) IBOutlet UIScrollView* scrollView;
@property (nonatomic, retain) IBOutlet UIButton* toggleMapButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* activityIndicatorView;


@end
