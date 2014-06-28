//
//  GetTokenResponse.h
//  wotw
//
//  Created by sean matthews on 4/9/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Response.h"

@interface GetTokenResponse:Response {
    NSString *__weak accessKey;
    NSString *__weak secretKey;
    NSString *__weak securityToken;
    NSString *__weak expirationDate;
}

@property (weak, nonatomic) NSString *accessKey;
@property (weak, nonatomic) NSString *secretKey;
@property (weak, nonatomic) NSString *securityToken;
@property (weak, nonatomic) NSString *expirationDate;

-(id)initWithAccessKey:(NSString *)theAccessKey andSecretKey:(NSString *)theSecurityKey andSecurityToken:(NSString *)theSecurityToken andExpirationDate:(NSString *)theExpirationDate;

@end