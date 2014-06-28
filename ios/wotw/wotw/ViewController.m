//
//  ViewController.m
//  wotw
//
//  Created by sean matthews on 3/18/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import "ViewController.h"
#import "AmazonKeyChainWrapper.h"
#import "Response.h"
//#import "AmazonClientManager.h"


@interface ViewController ()

@end

@implementation ViewController

@synthesize listData;
@synthesize scrollView;
@synthesize toggleMapButton;
@synthesize activityIndicatorView;

const long int TWO_WEEKS_SECONDS = 1209600;
const double MESSAGES_RADIUS_METERS = 50.;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gastown_brick_wall_bg-35A.png"]];
    [self.view addSubview:bgImageView];
    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"gastown_brick_wall_bg-35A.png"]];
    
    nextNoteY = 30;
    locationMeasurements = [[NSMutableArray alloc] init];
    
    // Unsecure! Give our SimpleDB access and secret keys to the SimpleDB client
    sdbClient = [[AmazonSimpleDBClient alloc] initWithAccessKey:@"AKIAJ5UTQAKVNG2ZWGYA" withSecretKey:@"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"];
    
    // Start searching for GPS location
    // Create the manager object 
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    // This is the most important property to set for the manager. It ultimately determines how the manager will
    // attempt to acquire location and thus, the amount of power that will be consumed.
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;//[[setupInfo objectForKey:kSetupInfoKeyAccuracy] doubleValue];
    
    // Once configured, the location manager must be "started".
    NSLog(@"start update location");
    [locationManager startUpdatingLocation];
    
    // A timeout obviously-- look at Apple's LocateMe example to figure out exactly how it works.
    // Not using for now.
    //[self performSelector:@selector(stopUpdatingLocation:) withObject:@"Timed Out" afterDelay:[[setupInfo objectForKey:kSetupInfoKeyTimeout] doubleValue]];
    
    
    mapButtonImage = [UIImage imageNamed:@"map_button.png"];
    wallButtonImage = [UIImage imageNamed:@"wall_button.png"]; 
    
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    screenBounds.size.height -= 42;
    screenBounds.origin.y += 42;
    mapView = [[MKMapView alloc] initWithFrame:screenBounds];
    mapView.hidden = true;
    [self.view addSubview:mapView];
    
    // Clear messages
    while([self.scrollView.subviews count] > 0) {
        [[self.scrollView.subviews lastObject] removeFromSuperview];
    }
    
    // Load the messages in the area
    //[self refreshButtonPressed:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    
    activityIndicatorView.hidden = YES;
    [activityIndicatorView stopAnimating];
}

- (void)viewWillDisappear:(BOOL)animated
{
    activityIndicatorView.hidden = YES;
    [activityIndicatorView stopAnimating];
}

- (void)viewWillUnload
{
    activityIndicatorView.hidden = YES;
    [activityIndicatorView stopAnimating];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}

- (IBAction)mapViewButtonPressed:(id)sender
{
    // TODO: load map with message locations in a broader area
    // TODO: make this a member variable, and reload the map only when the user has traveled outside the initial radius
    if (mapView.hidden) {
        [self populateMapView];
        CLLocationCoordinate2D currentLocation = [[locationMeasurements lastObject] coordinate];
        mapView.centerCoordinate = currentLocation;
        [mapView setRegion:MKCoordinateRegionMakeWithDistance(currentLocation, 40000., 40000.)];
        mapView.hidden = NO;
        [toggleMapButton setImage:wallButtonImage forState:UIControlStateNormal];
    }
    else {
        mapView.hidden = YES;
        [toggleMapButton setImage:mapButtonImage forState:UIControlStateNormal];
        [mapView removeAnnotations:[mapView annotations]];
    }
    
}


// Populate the mapView with local messages
- (void)populateMapView
{
    NSMutableArray *items = [self getFields:@"lat,long" toDistance:[NSNumber numberWithDouble:40000.]];
    
    for (SimpleDBItem *item in items) {
        NSMutableArray *attributes = [item attributes];

        CLLocationCoordinate2D annotationCoord;
            
        // 
        NSString *latitudeStr = ((SimpleDBAttribute*)[attributes objectAtIndex:1]).value;
        NSString *longitudeStr = ((SimpleDBAttribute*)[attributes objectAtIndex:0]).value;
        
        NSLog(@"blegh %@, %@",latitudeStr, longitudeStr);
        
        double latitude = atof([latitudeStr cStringUsingEncoding:NSASCIIStringEncoding]);
        double longitude = atof([longitudeStr cStringUsingEncoding:NSASCIIStringEncoding]);
        
        latitude = (latitude / 1000000.) - 400.;
        longitude = (longitude / 1000000.) - 400.;
        
        NSLog(@"blegh %f, %f",latitude,longitude);
        
        annotationCoord.latitude = latitude;
        annotationCoord.longitude = longitude;
            
        MKPointAnnotation *annotationPoint = [[MKPointAnnotation alloc] init];
        annotationPoint.coordinate = annotationCoord;
        [mapView addAnnotation:annotationPoint]; 
    }
}

// Get DB items by specifying select message and distance from user
- (NSMutableArray*)getFields:(NSString*)fields toDistance:(NSNumber*)dist
{
    CLLocationCoordinate2D currentLocation = [[locationMeasurements lastObject] coordinate];
    NSLog(@"current coordinate: %f, %f",currentLocation.latitude,currentLocation.longitude);
    
    NSArray *array = [self coordsAtDistance:dist fromCoord:currentLocation];
    CLLocationCoordinate2D cmin = [[array objectAtIndex:0] coordinate];
    CLLocationCoordinate2D cmax = [[array objectAtIndex:1] coordinate];
    
    NSString *minLat = [[NSNumber numberWithInt:((cmin.latitude + 400.) * 1000000.)] stringValue];
    NSString *maxLat = [[NSNumber numberWithInt:((cmax.latitude + 400.) * 1000000.)] stringValue];
    NSString *minLong = [[NSNumber numberWithInt:((cmin.longitude + 400.) * 1000000.)] stringValue];
    NSString *maxLong = [[NSNumber numberWithInt:((cmax.longitude + 400.) * 1000000.)] stringValue];
    
    while ([minLat length] < 10) {
        minLat = [NSString stringWithFormat:@"%@%@", @"0", minLat];
    }
    while ([maxLat length] < 10) {
        maxLat = [NSString stringWithFormat:@"%@%@", @"0", maxLat];
    }
    while ([minLong length] < 10) {
        minLong = [NSString stringWithFormat:@"%@%@", @"0", minLong];
    }
    while ([maxLong length] < 10) {
        maxLong = [NSString stringWithFormat:@"%@%@", @"0", maxLong];
    }
    
    NSNumber *timestamp = [[NSNumber alloc] initWithLong:[[NSDate date] timeIntervalSince1970]];  
    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM `wotw-simpledb` WHERE timestamp IS NOT NULL AND lat > '%@' AND lat < '%@' AND long > '%@' AND long < '%@' AND timestamp > '%d' ORDER BY timestamp ASC", fields, minLat, maxLat, minLong, maxLong, ([timestamp longValue] - TWO_WEEKS_SECONDS)];
    
    
    NSLog(@" query string: %@",query);
    
    @try {
        SimpleDBSelectRequest *selectRequest = [[SimpleDBSelectRequest alloc] initWithSelectExpression:query];
        selectRequest.consistentRead = YES;
        
        SimpleDBSelectResponse *selectResponse = [sdbClient select:selectRequest];
        NSLog(@"num items: %d", selectResponse.items.count); 
        
        return selectResponse.items;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception : [%@]", exception);
    }
    
    return NULL;
}


- (void)refresh
{
    const CGFloat width = self.scrollView.frame.size.width;//320;
    const CGFloat height = 45;
    const CGFloat margin = 5; 
    //const CGFloat widthMargin = 15;

    // Clear messages
    while([self.scrollView.subviews count] > 0) {
        [[self.scrollView.subviews lastObject] removeFromSuperview];
    }
    
    NSMutableArray *items = [self getFields:@"message" toDistance:[NSNumber numberWithDouble:MESSAGES_RADIUS_METERS]];
    for (SimpleDBItem *item in items) {
        NSMutableArray *attributes = [item attributes];
        
        for (SimpleDBAttribute *attribute in attributes) {
            // This code takes the text from the text field and adds it to the scroll view.
            // We actually want to refresh the scroll view whenever someone sends a note, pulling
            // down all the messages in the area.
            UITextView *textview = [[UITextView alloc] initWithFrame:CGRectMake(0, nextNoteY, width, height)];
            textview.text = attribute.value;
            textview.editable = NO;
            textview.scrollEnabled = NO;
            textview.showsVerticalScrollIndicator = NO;
            textview.showsHorizontalScrollIndicator = NO;
            textview.alpha = 1;
            textview.opaque = YES;
            [scrollView addSubview:textview];
            nextNoteY += height + margin;
            scrollView.contentSize = CGSizeMake(width, nextNoteY + margin);
            CGPoint bottomOffset = CGPointMake(0, scrollView.contentSize.height - self.scrollView.bounds.size.height);
            //CGPoint bottomOffset = CGPointMake(0, self.scrollView.bounds.size.height - 200);                
            [scrollView setContentOffset:bottomOffset animated:NO];    
            
            NSLog(@"attribute: %@",attribute.value);
        }
    }

    activityIndicatorView.hidden = YES;
    [activityIndicatorView stopAnimating];

}


// Pull notes from the server in a specific radius from the user
- (IBAction)refreshButtonPressed:(id)sender
{
    NSLog(@"Refresh button pressed");
    
    UIActivityIndicatorView  *tmpActIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    self.activityIndicatorView = tmpActIndicator;
    self.activityIndicatorView.hidden = NO;
    self.activityIndicatorView.center = self.view.center;
    
    [self.view addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
    
    [self performSelector:@selector(refresh) withObject:nil afterDelay:.1];
}


#pragma mark -
#pragma mark Area GPS coord calculations

// Given a GPS coordiante in the world, and a distance surrounding that coordinate,
// return an array with two CLLocation objects. The first denotes a minimum 
// latitude and longitude, the second denotes a maximum latitude and longitude.
// The two create a square around the origin coordinate.
- (NSArray*)coordsAtDistance:(NSNumber*)dist fromCoord:(CLLocationCoordinate2D)coord
{
    //Convert to radians
    double latitudeInRadians = coord.latitude * M_PI / 180.0;
    
    //Latitude is easy
    double latitudinalRange = [dist doubleValue] / 6378100.0;  //radius of the earth
    
    //Longitude is complicated
    double longitudinalRange = acos( (cos([dist doubleValue] / 6378100.0) - 
                                      sin(latitudeInRadians) * 
                                      sin(latitudeInRadians)) / 
                                      (cos(latitudeInRadians) * 
                                       cos(latitudeInRadians)) );
    
    //Convert back to latitude/longitude in degrees
    latitudinalRange = fabs(latitudinalRange) * 180.0 / M_PI;
    longitudinalRange = fabs(longitudinalRange) * 180.0 / M_PI;
    
    //Return lower and upper boundaries for latitude and longitude
    CLLocationCoordinate2D cmin, cmax;
    cmin.latitude = coord.latitude - latitudinalRange;
    cmin.longitude = coord.longitude - longitudinalRange;
    cmax.latitude = coord.latitude + latitudinalRange;
    cmax.longitude = coord.longitude + longitudinalRange;
    
    // Need to put coords in CLLocation objects because they are actually NSObjects--
    // CLLocationCoordinate2D objects are merely C structs.
    // To extract: CLLocationCoordinate2D coord = [[array lastObject] coordinate];
    CLLocation *minCoords = [[CLLocation alloc] initWithLatitude:cmin.latitude longitude:cmin.longitude];
    CLLocation *maxCoords = [[CLLocation alloc] initWithLatitude:cmax.latitude longitude:cmax.longitude];
    NSArray *array = [NSArray arrayWithObjects:minCoords, maxCoords, nil];
    
    return array;
}


#pragma mark - 
#pragma mark UITextField animations

// Call the animation to move the text field up with the keyboard
- (IBAction)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField: textField up: YES];
}


// Call the animation to move the text field down with the keyboard
- (IBAction)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField: textField up: NO];
}

// An animation to move the text field up when the user begins
// editing it (so the keyboard doesn't cover the text field)
- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 216; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}


#pragma mark -
#pragma mark UITextField delegate methods

// Limits the number of characters typed in the text field to 140
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > 140) ? NO : YES;
}

// Sends text field text to database, refreshes message list
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
	[textField resignFirstResponder];
    
    if (textField.text.length < 1) {
        [self refreshButtonPressed:self]; 
        return YES;
    }
    
    // Add latitude & longitude
    NSNumber *timestamp = [[NSNumber alloc] initWithInteger:[[NSDate date] timeIntervalSince1970]];    
    CLLocationCoordinate2D currentLocation = [[locationMeasurements lastObject] coordinate];
    NSString *longitude = [[NSNumber numberWithInt:((currentLocation.longitude + 400.) * 1000000.)] stringValue];
    NSString *latitude = [[NSNumber numberWithInt:((currentLocation.latitude + 400.) * 1000000.)] stringValue]; 
    
    // Pad the long and lat with leading zeroes to reach ten characters
    while ([longitude length] < 10) {
        longitude = [NSString stringWithFormat:@"0%@",longitude];
    }
    while ([latitude length] < 10) {
        latitude = [NSString stringWithFormat:@"0%@",latitude];
    }  
    
    
    SimpleDBPutAttributesRequest *putReq = [[SimpleDBPutAttributesRequest alloc] initWithDomainName:@"wotw-simpledb" andItemName:[self GetUUID] andAttributes:nil];    
    [putReq addAttribute:[[SimpleDBReplaceableAttribute alloc] initWithName:@"timestamp" andValue:[timestamp stringValue] andReplace:NO]];      
    [putReq addAttribute:[[SimpleDBReplaceableAttribute alloc] initWithName:@"message" andValue:textField.text andReplace:NO]];
    [putReq addAttribute:[[SimpleDBReplaceableAttribute alloc] initWithName:@"long" andValue:longitude andReplace:YES]];
    [putReq addAttribute:[[SimpleDBReplaceableAttribute alloc] initWithName:@"lat" andValue:latitude andReplace:YES]];
    
    // Send the put attributes request
    @try {
        //SimpleDBPutAttributesResponse *putRsp = [sdbClient putAttributes:putReq];
        [sdbClient putAttributes:putReq];
    }
    @catch (NSException *exception) {
        NSLog(@"Exception : [%@]", exception);
    }
    
    // Debugging, check that put was successful
    // How?
    
    // Clear text field
    [textField setText:@""];
    
    // Refresh message list
    [self refreshButtonPressed:self];   
    
	return YES;
}


#pragma mark -
#pragma mark CLLocationManagerDelegate required functions, and other location functions

/*
 * We want to get and store a location measurement that meets the desired accuracy. For this example, we are
 *      going to use horizontal accuracy as the deciding factor. In other cases, you may wish to use vertical
 *      accuracy, or both together.
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    //NSLog(@"got new gps");
    NSLog(@"got new gps location: %f, %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    
    // store all of the measurements, just so we can see what kind of data we might receive
    [locationMeasurements addObject:newLocation];
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return;
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
    // test the measurement to see if it is more accurate than the previous measurement
    if (bestEffortAtLocation == nil || bestEffortAtLocation.horizontalAccuracy > newLocation.horizontalAccuracy) {
        // store the location as the "best effort"
        bestEffortAtLocation = newLocation;
        // test the measurement to see if it meets the desired accuracy
        //
        // IMPORTANT!!! kCLLocationAccuracyBest should not be used for comparison with location coordinate or altitidue 
        // accuracy because it is a negative value. Instead, compare against some predetermined "real" measure of 
        // acceptable accuracy, or depend on the timeout to stop updating. This sample depends on the timeout.
        //
        if (newLocation.horizontalAccuracy <= locationManager.desiredAccuracy) {
            // we have a measurement that meets our requirements, so we can stop updating the location
            // 
            // IMPORTANT!!! Minimize power usage by stopping the location manager as soon as possible.
            //
            [self stopUpdatingLocation:NSLocalizedString(@"Acquired Location", @"Acquired Location")];
            // we can also cancel our previous performSelector:withObject:afterDelay: - it's no longer necessary
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopUpdatingLocation:) object:nil];
        }
    }
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // The location "unknown" error simply means the manager is currently unable to get the location.
    // We can ignore this error for the scenario of getting a single location fix, because we already have a 
    // timeout that will stop the location manager to save power.
    if ([error code] != kCLErrorLocationUnknown) {
        [self stopUpdatingLocation:NSLocalizedString(@"Error", @"Error")];
    }
}


- (void)stopUpdatingLocation:(NSString *)state {
    //self.stateString = state;

    NSLog(@"location manager failed with error: %@",state);
    
    [locationManager stopUpdatingLocation];
    locationManager.delegate = nil;
    
    //UIBarButtonItem *resetItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reset", @"Reset") style:UIBarButtonItemStyleBordered target:self action:@selector(reset)] autorelease];
    //[self.navigationItem setLeftBarButtonItem:resetItem animated:YES];;
}


#pragma mark -
#pragma mark Utility functions


- (NSString *)GetUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge_transfer NSString *)string;
}


@end


