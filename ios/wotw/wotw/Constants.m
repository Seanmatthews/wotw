//
//  Constants.m
//  wotw
//
//  Created by sean matthews on 4/9/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import "Constants.h"

@implementation Constants


+(UIAlertView *)credentialsAlert
{
    return [[UIAlertView alloc] initWithTitle:@"AWS Credentials" message:CREDENTIALS_ALERT_MESSAGE delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
}

+(UIAlertView *)errorAlert:(NSString *)message
{
    return [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
}

+(UIAlertView *)expiredCredentialsAlert
{
    return [[UIAlertView alloc] initWithTitle:@"AWS Credentials" message:@"Credentials Expired, retry your request." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
}

@end
