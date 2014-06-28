//
//  GetTokenResponse.m
//  wotw
//
//  Created by sean matthews on 4/9/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import "GetTokenResponse.h"

@implementation GetTokenResponse

@synthesize accessKey;
@synthesize secretKey;
@synthesize securityToken;
@synthesize expirationDate;

-(id)initWithAccessKey:(NSString *)theAccessKey andSecretKey:(NSString *)theSecurityKey andSecurityToken:(NSString *)theSecurityToken andExpirationDate:(NSString *)theExpirationDate
{
    if ((self = [super initWithCode:200 andMessage:nil])) {
        self.accessKey      = theAccessKey;
        self.secretKey      = theSecurityKey;
        self.securityToken  = theSecurityToken;
        self.expirationDate = theExpirationDate;
    }
    
    return self;
}


@end