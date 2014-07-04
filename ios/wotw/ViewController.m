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
#import "MessageTableViewCell.h"
#import <QuartzCore/QuartzCore.h>


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
- (void)refreshTable;
- (void)writeMessageWithText:(NSString*)text;
- (UIImage *)imageForButton:(UIButton *)button fromView:(UIView *)view;

@end

@implementation ViewController

const long int TWO_WEEKS_SECONDS = 1209600;
const double MESSAGES_RADIUS_METERS = 50.;
const short MESSAGE_CHAR_LIMIT = 100;


// This is called whenever the view is loaded through storyboard segues
- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super initWithCoder:coder]) {
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

    _mapButton.bgImage = [UIImage imageNamed:@"defaultMapButton.png"];
    _wallView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"brickwall.png"]];
    _wallView.hidden = NO;
    _mapView.hidden = YES;
    keyboardIsVisible = NO;
    [self refreshTable];
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
    if (keyboardIsVisible) {
        [_textField setText:@""];
        [_textField resignFirstResponder];
    }
    
    // Only need to do this once to clear the initial background image
    if (_mapButton.bgImage) {
        _mapButton.bgImage = nil;
        [_mapButton setNeedsDisplay];
    }
    
    [_wallButton setBackgroundImage:[self imageForButton:_wallButton fromView:_wallView]
                           forState:UIControlStateNormal];
    [_mapButton setBackgroundImage:nil forState:UIControlStateNormal];
    _mapView.hidden = NO;
    _wallView.hidden = YES;
}

- (IBAction)pressedWallButton:(id)sender
{
    [self refreshTable];
    [_mapButton setBackgroundImage:[self imageForButton:_mapButton fromView:_mapView]
                          forState:UIControlStateNormal];
    [_wallButton setBackgroundImage:nil forState:UIControlStateNormal];
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

// Get DB items by specifying select message and distance from user
- (NSMutableArray*)getFields:(NSString*)fields toDistance:(NSNumber*)dist
{
    CLLocationCoordinate2D currentLocation = [[Location sharedInstance] currentLocation];
    NSLog(@"current coordinate: %f, %f",currentLocation.latitude,currentLocation.longitude);
    
    NSArray *array = [[Location sharedInstance] coordsAtDistance:dist];
    CLLocationCoordinate2D cmin = [[array objectAtIndex:0] coordinate];
    CLLocationCoordinate2D cmax = [[array objectAtIndex:1] coordinate];
    
    // Pad with zeroes in the front until we have 10 characters, C style
    NSString *minLat = [NSString stringWithFormat:@"%010lu",(unsigned long)((cmin.latitude + 400.) * 1000000.)];
    NSString *maxLat = [NSString stringWithFormat:@"%010lu",(unsigned long)((cmax.latitude + 400.) * 1000000.)];
    NSString *minLong = [NSString stringWithFormat:@"%010lu",(unsigned long)((cmin.longitude + 400.) * 1000000.)];
    NSString *maxLong = [NSString stringWithFormat:@"%010lu",(unsigned long)((cmax.longitude + 400.) * 1000000.)];

//    NSNumber *timestamp = [[NSNumber alloc] initWithLong:[[NSDate date] timeIntervalSince1970]];
//    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM `wotw-simpledb` WHERE timestamp IS NOT NULL AND lat > '%@' AND lat < '%@' AND long > '%@' AND long < '%@' AND timestamp > '%d' ORDER BY timestamp ASC", fields, minLat, maxLat, minLong, maxLong, ([timestamp longValue] - TWO_WEEKS_SECONDS)];
    
    // NOTE: This version has no two week limit on messages
    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM `wotw-simpledb` WHERE timestamp IS NOT NULL AND lat > '%@' AND lat < '%@' AND long > '%@' AND long < '%@' ORDER BY timestamp ASC", fields, minLat, maxLat, minLong, maxLong];
//    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM `wotw-simpledb`", fields];
    NSLog(@" query string: %@",query);
    
    @try {
        SimpleDBSelectRequest *selectRequest = [[SimpleDBSelectRequest alloc] initWithSelectExpression:query];
        selectRequest.consistentRead = YES;
        
        NSLog(@"client %@", sdbClient);
        SimpleDBSelectResponse *selectResponse = [sdbClient select:selectRequest];
        NSLog(@"num messages: %lu", (unsigned long)selectResponse.items.count);
        return selectResponse.items;
    }
    @catch (NSException *exception) {
        NSLog(@"Exception : [%@]", exception);
    }
    
    return NULL;
}

// Fill the "model" with NSString messages
- (void)refreshTable
{
    // array of SimpleDBItem
    NSMutableArray *items = [self getFields:@"message" toDistance:[NSNumber numberWithDouble:MESSAGES_RADIUS_METERS]];
    
    NSArray *anew = [[NSArray alloc] init];;
    for (SimpleDBItem *item in items) {
        NSMutableArray *attrs = [item attributes];
        anew = [anew arrayByAddingObjectsFromArray:attrs];
    }
    messages = [anew valueForKey:@"value"];
    [_tableView reloadData];
    
    if (messages.count > 0) {
        NSIndexPath* path = [NSIndexPath indexPathForRow:messages.count-1 inSection:0];
        [_tableView scrollToRowAtIndexPath:path
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:NO];
    }
}

- (void)writeMessageWithText:(NSString*)text
{
    _charactersLeft.text = [NSString stringWithFormat:@"%d characters left", MESSAGE_CHAR_LIMIT];
    
    // Add latitude & longitude
    NSNumber *timestamp = [[NSNumber alloc] initWithInteger:[[NSDate date] timeIntervalSince1970]];
    
    // Pad the long and lat with leading zeroes to reach ten characters
    NSString *latitude = [NSString stringWithFormat:@"%010llu",[[Location sharedInstance] currentLat]];
    NSString *longitude = [NSString stringWithFormat:@"%010llu",[[Location sharedInstance] currentLong]];
    
    NSLog(@"lat: %@, long: %@, ts: %@, message: %@",latitude,longitude,[timestamp stringValue],text);
    SimpleDBPutAttributesRequest *putReq = [[SimpleDBPutAttributesRequest alloc]
                                            initWithDomainName:@"wotw-simpledb"
                                            andItemName:[[[UIDevice currentDevice] identifierForVendor] UUIDString]
                                            andAttributes:nil];
    [putReq addAttribute:[[SimpleDBReplaceableAttribute alloc] initWithName:@"timestamp" andValue:[timestamp stringValue] andReplace:NO]];
    [putReq addAttribute:[[SimpleDBReplaceableAttribute alloc] initWithName:@"message" andValue:text andReplace:NO]];
    [putReq addAttribute:[[SimpleDBReplaceableAttribute alloc] initWithName:@"long" andValue:longitude andReplace:YES]];
    [putReq addAttribute:[[SimpleDBReplaceableAttribute alloc] initWithName:@"lat" andValue:latitude andReplace:YES]];
    
    // Send the put attributes request
    @try {
        SimpleDBPutAttributesResponse *putRsp = [sdbClient putAttributes:putReq];
//        [sdbClient putAttributes:putReq];
        NSLog(@"%@",putRsp);
    }
    @catch (NSException *exception) {
        NSLog(@"Exception : [%@]", exception);
    }
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    if ([textField.text length] > 0) {
        [self writeMessageWithText:textField.text];
    }
    [textField setText:@""];
    [self refreshTable];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (newString.length >= MESSAGE_CHAR_LIMIT) {
        // Send message automatically
        [textField resignFirstResponder];
        [self writeMessageWithText:textField.text];
        [textField setText:@""];
        [self refreshTable];
    }
    _charactersLeft.text = [NSString stringWithFormat:@"%d characters left",
                            MESSAGE_CHAR_LIMIT - textField.text.length - string.length];
    return YES;
}


#pragma mark - UITableViewDelegate methods

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 66.; // TODO: adjust
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
    MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        // Try to changes the size and shape of the textLabel built into the UITableViewCell
        cell = [[MessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.editing = NO;
        cell.textLabel.layer.cornerRadius = 10;
        cell.textLabel.layer.masksToBounds = YES;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.firstLineHeadIndent = 4;
    style.headIndent = 4;
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:messages[indexPath.row]
                                                                    attributes:@{NSParagraphStyleAttributeName: style}];
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


#pragma mark - Button graphics

- (UIImage *)imageForButton:(UIButton *)button fromView:(UIView *)view
{
    
    UIGraphicsBeginImageContext(self.view.window.bounds.size);
    [self.view.window.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGRect rect = [button convertRect:button.bounds toView:self.view];
    NSLog(@"rect %f, %f, %f, %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return cropped;
}




@end
