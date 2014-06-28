//
//  GetTokenRequest.h
//  wotw
//
//  Created by sean matthews on 4/9/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Request.h"

#define GET_TOKEN_REQUEST        @"http://%@/gettoken?uid=%@&timestamp=%@&signature=%@"
#define SSL_GET_TOKEN_REQUEST    @"https://%@/gettoken?uid=%@&timestamp=%@&signature=%@"

@interface GetTokenRequest:Request {
    NSString *endpoint;
    NSString *uid;
    NSString *key;
    bool     useSSL;
}

-(id)initWithEndpoint:(NSString *)theEndpoint andUid:(NSString *)theUid andKey:(NSString *)theKey usingSSL:(bool)usingSSL;

@end