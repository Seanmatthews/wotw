//
//  Constants.h
//  wotw
//
//  Created by sean matthews on 4/9/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * This is the the DNS domain name of the endpoint your Token Vending
 * Machine is running.  (For example, if your TVM is running at
 * http://mytvm.elasticbeanstalk.com this parameter should be set to
 * mytvm.elasticbeanstalk.com.)
 */
#define TOKEN_VENDING_MACHINE_URL    @"wotwtvm2.elasticbeanstalk.com"

/**
 * This indiciates whether or not the TVM is supports SSL connections.
 */
#define USE_SSL                      NO


#define CREDENTIALS_ALERT_MESSAGE    @"Please update the Constants.h file with your credentials or Token Vending Machine URL."
#define ACCESS_KEY_ID                @"USED_ONLY_FOR_TESTING"  // Leave this value as is.
#define SECRET_KEY                   @"USED_ONLY_FOR_TESTING"  // Leave this value as is.


@interface Constants:NSObject {
}

+(UIAlertView *)credentialsAlert;
+(UIAlertView *)errorAlert:(NSString *)message;
+(UIAlertView *)expiredCredentialsAlert;

@end
