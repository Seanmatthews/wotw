//
//  GetTokenRequest.m
//  wotw
//
//  Created by sean matthews on 4/9/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import "GetTokenRequest.h"
#import <AWSiOSSDk/AmazonAuthUtils.h>

@implementation GetTokenRequest

-(id)initWithEndpoint:(NSString *)theEndpoint andUid:(NSString *)theUid andKey:(NSString *)theKey usingSSL:(bool)usingSSL
{
    if ((self = [super init])) {
        endpoint = theEndpoint;
        uid      = theUid;
        key      = theKey;
        useSSL   = usingSSL;
    }
    
    return self;
}

-(NSString *)buildRequestUrl
{
    NSDate   *currentTime = [NSDate date];
    
    NSString *timestamp = [currentTime stringWithISO8601Format];
    NSString *signature = [AmazonAuthUtils HMACSign:[timestamp dataUsingEncoding:NSUTF8StringEncoding] withKey:key usingAlgorithm:kCCHmacAlgSHA256];
    
    return [NSString stringWithFormat:(useSSL ? SSL_GET_TOKEN_REQUEST:GET_TOKEN_REQUEST), endpoint, [uid stringWithURLEncoding], [timestamp stringWithURLEncoding], [signature stringWithURLEncoding]];
}



@end