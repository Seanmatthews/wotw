//
//  Response.m
//  wotw
//
//  Created by sean matthews on 4/9/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import "Response.h"

@implementation Response

@synthesize code;
@synthesize message;

-(id)initWithCode:(int)theCode andMessage:(NSString *)theMessage
{
    if ((self = [super init])) {
        code         = theCode;
        self.message = theMessage;
    }
    
    return self;
}

-(bool)wasSuccessful
{
    return self.code == 200;
}


@end
