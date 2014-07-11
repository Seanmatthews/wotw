//
//  MessageRepo.h
//  wotw
//
//  Created by sean matthews on 7/7/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

@import Foundation;
@import MapKit;

@interface MessageRepo : NSObject

@property (atomic, strong) NSMutableArray *messages;
@property (atomic, strong) NSMutableArray *mapMessages;

+ (id)sharedInstance;
- (void)refreshMessages;
- (void)refreshMapMessagesWithRegion:(MKCoordinateRegion)region;
- (void)writeOnWall:(NSString*)message;

@end
