//
//  ViewController.h
//  wotw
//
//  Created by sean matthews on 6/28/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

@import UIKit;
@import iAd;
@import CoreLocation;
@import MapKit;

@interface ViewController : UIViewController <ADBannerViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) IBOutlet UIView *wallView;
@property (nonatomic, strong) IBOutlet UITextField *textField;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UILabel *charactersLeft;

- (IBAction)pressedMapButton:(id)sender;
- (IBAction)pressedWallButton:(id)sender;

@end
