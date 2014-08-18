//
//  MessageRepo.m
//  wotw
//
//  Created by sean matthews on 7/7/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

#import "MessageRepo.h"
#import <AWSSimpleDB/AWSSimpleDB.h>
#import "Location.h"

@interface MessageRepo()
{
    AmazonSimpleDBClient *sdbClient;
}

- (void)registerForNotifications;
- (void)receivedFirstLocation;
- (NSArray*)performQuery:(NSString*)query;
- (NSArray*)getFields:(NSString*)fields toDistance:(NSNumber*)dist withLimit:(NSUInteger)limit;

@end

@implementation MessageRepo

const long int TWO_WEEKS_SECONDS = 1209600;
const double MESSAGES_RADIUS_METERS = 50.;
const CGFloat METERS_PER_LATITUDE_DEGREE = 111000.;
const long long MAX_SIMPLEDB_ELEMENTS = 2500;


- (id)init
{
    self = [super init];
    if (self) {
        _messages = [[NSMutableArray alloc] init];
        _mapMessages = [[NSMutableArray alloc] init];
        [self registerForNotifications];
        sdbClient = [[AmazonSimpleDBClient alloc]
                     initWithAccessKey:@"AKIAJ5UTQAKVNG2ZWGYA"
                     withSecretKey:@"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"];
    }
    return self;
}

+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
        // Additional initialization can go here
    });
    return _sharedObject;
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedFirstLocation)
                                                 name:@"LocationUpdateNotification"
                                               object:nil];
}

- (void)receivedFirstLocation
{
    NSLog(@"Received first location");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LocationUpdateNotification" object:nil];
    [self refreshMessages];
}

// Check for new messages at user location
- (void)refreshMessages
{
    // array of SimpleDBItem
    NSArray *items = [self getFields:@"message" toDistance:[NSNumber numberWithDouble:MESSAGES_RADIUS_METERS] withLimit:0];
    
    if (!items) {
        NSLog(@"No items");
        return;
    }
    
    NSArray *anew = [[NSArray alloc] init];
    for (SimpleDBItem *item in items) {
        NSMutableArray *attrs = [item attributes];
        anew = [anew arrayByAddingObjectsFromArray:attrs];
    }
    
    // This is getting all messages every time--
    // TODO only search for and insert new messages.
    NSArray *allMessages = [anew valueForKey:@"value"];
    NSLog(@"message count %d", [allMessages count]);
   [[self mutableArrayValueForKey:@"messages"] removeAllObjects]; // This will not trigger KVO observers
    [[self mutableArrayValueForKey:@"messages"] addObjectsFromArray:allMessages];
}

- (void)refreshMapMessagesWithRegion:(MKCoordinateRegion)region
{
    NSNumber *dist = [NSNumber numberWithFloat:(region.span.latitudeDelta * METERS_PER_LATITUDE_DEGREE)];
    
    // array of SimpleDBItem
    NSArray *items = [self getFields:@"message, lat, long" toDistance:dist withLimit:0];
    
    if (!items) {
        NSLog(@"No items");
        return;
    }
    
    NSMutableArray *messageDicts = [[NSMutableArray alloc] init];;
    for (SimpleDBItem *item in items) {
        
        NSMutableArray *attrs = [item attributes];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        for (SimpleDBAttribute *attr in attrs) {
            [dict setObject:[attr valueForKey:@"value"] forKey:[attr valueForKey:@"name"]];
        }
        [messageDicts addObject:dict];
    }
    
    // Speedy concurrent bock enumeration
    [messageDicts enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        double lat = [Location fromLongLong:[[obj objectForKey:@"lat"] longLongValue]];
        double lon = [Location fromLongLong:[[obj objectForKey:@"long"] longLongValue]];
        [obj setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
        [obj setObject:[NSNumber numberWithDouble:lon] forKey:@"long"];
    }];
    
    for (id d in messageDicts) {
        if (![_mapMessages containsObject:d]) {
            [[self mutableArrayValueForKey:@"mapMessages"] addObject:d];
        }
    }
    
//    [[self mutableArrayValueForKey:@"mapMessages"] removeAllObjects]; // Will this trigger KVO observers
//    [[self mutableArrayValueForKey:@"mapMessages"] addObjectsFromArray:messageDicts];
    
    
}


#pragma mark - AWS interface

// Get DB items by specifying select message and distance from user
- (NSArray*)getFields:(NSString*)fields toDistance:(NSNumber*)dist withLimit:(NSUInteger)limit
{
    NSArray *array = [[Location sharedInstance] coordsAtDistance:dist];
    CLLocationCoordinate2D cmin = [[array objectAtIndex:0] coordinate];
    CLLocationCoordinate2D cmax = [[array objectAtIndex:1] coordinate];
    
    // Pad with zeroes in the front until we have 10 characters, C style
    NSString *minLat = [NSString stringWithFormat:@"%010lu",(unsigned long)[Location toLongLong:cmin.latitude]];
    NSString *maxLat = [NSString stringWithFormat:@"%010lu",(unsigned long)[Location toLongLong:cmax.latitude]];
    NSString *minLong = [NSString stringWithFormat:@"%010lu",(unsigned long)[Location toLongLong:cmin.longitude]];
    NSString *maxLong = [NSString stringWithFormat:@"%010lu",(unsigned long)[Location toLongLong:cmax.longitude]];
    
    //    NSNumber *timestamp = [[NSNumber alloc] initWithLong:[[NSDate date] timeIntervalSince1970]];
    //    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM `wotw-simpledb` WHERE timestamp IS NOT NULL AND lat > '%@' AND lat < '%@' AND long > '%@' AND long < '%@' AND timestamp > '%d' ORDER BY timestamp ASC", fields, minLat, maxLat, minLong, maxLong, ([timestamp longValue] - TWO_WEEKS_SECONDS)];
    
    // NOTE: This version has no two week limit on messages
    NSString *query = [NSString stringWithFormat:@"SELECT %@ FROM `wotw-simpledb` WHERE timestamp IS NOT NULL AND lat > '%@' AND lat < '%@' AND long > '%@' AND long < '%@' ORDER BY timestamp ASC",
                       fields, minLat, maxLat, minLong, maxLong];
    
    if (limit > 0) {
        query = [query stringByAppendingString:[NSString stringWithFormat:@" LIMIT %d", limit]];
    }
    NSLog(@" query string: %@",query);
    
//    @try {
//        SimpleDBSelectRequest *selectRequest = [[SimpleDBSelectRequest alloc] initWithSelectExpression:query];
//        selectRequest.consistentRead = YES;
//        SimpleDBSelectResponse *selectResponse = [sdbClient select:selectRequest];
//        return selectResponse.items;
//    }
//    @catch (NSException *exception) {
//        NSLog(@"Exception : [%@]", exception);
//    }
    
    return [self performQuery:query];
}

- (void)writeOnWall:(NSString*)message
{
    //    _charactersLeft.text = [NSString stringWithFormat:@"%d characters left", MESSAGE_CHAR_LIMIT];
    
    // Add latitude & longitude
    NSNumber *timestamp = [[NSNumber alloc] initWithInteger:[[NSDate date] timeIntervalSince1970]];
    
    // Pad the long and lat with leading zeroes to reach ten characters
    NSString *latitude = [NSString stringWithFormat:@"%010llu",[[Location sharedInstance] currentLat]];
    NSString *longitude = [NSString stringWithFormat:@"%010llu",[[Location sharedInstance] currentLong]];
    
    NSLog(@"lat: %@, long: %@, ts: %@, message: %@",latitude,longitude,[timestamp stringValue],message);
    SimpleDBPutAttributesRequest *putReq = [[SimpleDBPutAttributesRequest alloc]
                                            initWithDomainName:@"wotw-simpledb"
                                            andItemName:[[[UIDevice currentDevice] identifierForVendor] UUIDString]
                                            andAttributes:nil];
    [putReq addAttribute:[[SimpleDBReplaceableAttribute alloc] initWithName:@"timestamp" andValue:[timestamp stringValue] andReplace:NO]];
    [putReq addAttribute:[[SimpleDBReplaceableAttribute alloc] initWithName:@"message" andValue:message andReplace:NO]];
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

- (NSArray*)performQuery:(NSString*)query
{
    NSMutableArray* items = [[NSMutableArray alloc] init];
    SimpleDBSelectRequest *selectRequest = nil;
    SimpleDBSelectResponse *selectResponse = nil;
    
    @try {
        do {
            selectRequest = [[SimpleDBSelectRequest alloc] initWithSelectExpression:query];
            selectRequest.consistentRead = YES;
            selectResponse = [sdbClient select:selectRequest];
            [items addObjectsFromArray:selectResponse.items];
            selectRequest.nextToken = selectResponse.nextToken;
        }
        while (selectResponse.nextToken);
    }
    @catch (NSException *exception) {
        NSLog(@"Exception : [%@]", exception);
    }
    
    return [items copy];
}

@end
