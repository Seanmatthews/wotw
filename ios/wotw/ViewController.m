//
//  ViewController.m
//  wotw
//
//  Created by sean matthews on 6/28/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

#import "ViewController.h"
#import <AWSSimpleDB/AWSSimpleDB.h>
#import "Location.h"
#import "MessageAnnotationView.h"


@interface ViewController ()
{
    BOOL keyboardIsVisible;
    AmazonSimpleDBClient *sdbClient;
    NSArray *messages;
    NSMutableDictionary *annotationDict;
}

- (void)registerForNotifications;
- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWillBeHidden:(NSNotification*)aNotification;
- (void)loadAnnotationsForRegion:(MKCoordinateRegion)region;

@end

@implementation ViewController

const long int TWO_WEEKS_SECONDS = 1209600;
const double MESSAGES_RADIUS_METERS = 50.;

- (id)init
{
    self = [super init];
    if (self) {
        // TODO: Use TVM
        sdbClient = [[AmazonSimpleDBClient alloc]
                     initWithAccessKey:@"AKIAJ5UTQAKVNG2ZWGYA"
                     withSecretKey:@"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"];
        messages = [[NSArray alloc] init];
        annotationDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self registerForNotifications];
	self.canDisplayBannerAds = YES;
    _wallView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"brickwall.png"]];
    _wallView.hidden = NO;
    _mapView.hidden = YES;
    keyboardIsVisible = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (IBAction)pressedMapButton:(id)sender
{
    _mapView.hidden = NO;
    _wallView.hidden = YES;
    if (keyboardIsVisible) {
        [_textField setText:@""];
        [_textField resignFirstResponder];
    }
}

- (IBAction)pressedWallButton:(id)sender
{
    _wallView.hidden = NO;
    _mapView.hidden = YES;
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    keyboardIsVisible = YES;
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // Animate the current view out of the way
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    CGRect rect = _wallView.frame;
    rect.origin.y -= kbSize.height;
    _wallView.frame = rect;
    
    [UIView commitAnimations];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    keyboardIsVisible = NO;
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // Animate the current view back to where it was
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    CGRect rect = _wallView.frame;
    rect.origin.y += kbSize.height;
    _wallView.frame = rect;
    [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString* text = [textField text];
    if ([text length] > 0) {
        
    }
    [textField setText:@""];
    [textField resignFirstResponder];
    return YES;
}

// Get DB items by specifying select message and distance from user
- (NSMutableArray*)getFields:(NSString*)fields toDistance:(NSNumber*)dist
{
    CLLocationCoordinate2D currentLocation = [[Location sharedInstance] currentLocation];
    NSLog(@"current coordinate: %f, %f",currentLocation.latitude,currentLocation.longitude);
    
    NSArray *array = [[Location sharedInstance] coordsAtDistance:dist];
    CLLocationCoordinate2D cmin = [[array objectAtIndex:0] coordinate];
    CLLocationCoordinate2D cmax = [[array objectAtIndex:1] coordinate];
    
    // Pad with zeroes in the front until we have 10 characters, C style
    NSString *minLat = [NSString stringWithFormat:@"%010d",(NSUInteger)((cmin.latitude + 400.) * 1000000.)];
    NSString *maxLat = [NSString stringWithFormat:@"%010d",(NSUInteger)((cmax.latitude + 400.) * 1000000.)];
    NSString *minLong = [NSString stringWithFormat:@"%010d",(NSUInteger)((cmin.longitude + 400.) * 1000000.)];
    NSString *maxLong = [NSString stringWithFormat:@"%010d",(NSUInteger)((cmax.longitude + 400.) * 1000000.)];

//    NSNumber *timestamp = [[NSNumber alloc] initWithLong:[[NSDate date] timeIntervalSince1970]];
//    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM `wotw-simpledb` WHERE timestamp IS NOT NULL AND lat > '%@' AND lat < '%@' AND long > '%@' AND long < '%@' AND timestamp > '%d' ORDER BY timestamp ASC", fields, minLat, maxLat, minLong, maxLong, ([timestamp longValue] - TWO_WEEKS_SECONDS)];
    
    // NOTE: This version has no two week limit on messages
    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM `wotw-simpledb` WHERE timestamp IS NOT NULL AND lat > '%@' AND lat < '%@' AND long > '%@' AND long < '%@' ORDER BY timestamp ASC", fields, minLat, maxLat, minLong, maxLong];
    NSLog(@" query string: %@",query);
    
    @try {
        SimpleDBSelectRequest *selectRequest = [[SimpleDBSelectRequest alloc] initWithSelectExpression:query];
        selectRequest.consistentRead = YES;
        
        SimpleDBSelectResponse *selectResponse = [sdbClient select:selectRequest];
        NSLog(@"num messages: %d", selectResponse.items.count);
        return selectResponse.items;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception : [%@]", exception);
    }
    
    return NULL;
}

// Fill the "model" with NSString messages
- (void)refresh
{
    NSMutableArray *items = [self getFields:@"message" toDistance:[NSNumber numberWithDouble:MESSAGES_RADIUS_METERS]];
    messages = [[items valueForKey:@"attributes"] valueForKey:@"value"];
    [_tableView reloadData];
}


#pragma mark - UITableViewDelegate methods

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.; // TODO: adjust
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [messages count];
}

// This function is for recovering cells, or initializing a new one.
// It is not for filling in cell data.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"%ld_%ld",(long)indexPath.section,(long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        // Try to changes the size and shape of the textLabel built into the UITableViewCell
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell setBackgroundColor:[UIColor clearColor]];
        cell.textLabel.frame = CGRectMake(20, 0, 300, 44); // TODO: adjust
        [cell.textLabel setBackgroundColor:[UIColor whiteColor]];
        cell.textLabel.layer.cornerRadius = 15;
        cell.textLabel.layer.masksToBounds = YES;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.font = [UIFont systemFontOfSize:13.];
    }
    cell.textLabel.text = messages[indexPath.row];
    return cell;
}


#pragma mark - MKMapViewDelegate methods

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self loadAnnotationsForRegion:mapView.region];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id < MKAnnotation >)annotation
{
    MessageAnnotationView* annotationView = nil;
    annotationView = (MessageAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"AnnotationView"];
    if (annotationView) {
        annotationView.annotation = annotation;
        annotationView.messageText = [[annotationDict objectForKey:[annotation description]] valueForKey:@"message"];
    }
    else {
        annotationView = [[MessageAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"AnnotationView"];
    }
    annotationView.canShowCallout = YES;
    return annotationView;
}


#pragma mark - Map Annotations

- (void)loadAnnotationsForRegion:(MKCoordinateRegion)region
{
    // TODO: Is there a way we can not load pins that already loaded?
    
    NSNumber *dist = [NSNumber numberWithDouble:MAX(region.span.latitudeDelta, region.span.longitudeDelta)];
    NSMutableArray *items = [self getFields:@"message,latitude,longitude" toDistance:dist];
    
    for (SimpleDBItem *item in items) {
        MKPointAnnotation* mpa = [[MKPointAnnotation alloc] init];
        CLLocationCoordinate2D coord;
        coord.latitude = [Location fromLongLong:(long long)[item valueForKey:@"latitude"]];
        coord.longitude = [Location fromLongLong:(long long)[item valueForKey:@"longitude"]];
        mpa.coordinate = coord;
    
        // Only add the annotation to the map if we haven't received it before
        if ([annotationDict objectForKey:mpa.description] == nil) {
            [_mapView addAnnotation:mpa];
            [annotationDict setObject:item forKey:mpa.description];
        }
    }
}

@end
