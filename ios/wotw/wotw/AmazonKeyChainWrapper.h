//
//  AmazonKeyChainWrapper.h
//  wotw
//
//  Created by sean matthews on 4/9/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSiOSSDK/AmazonCredentials.h>


@interface AmazonKeyChainWrapper:NSObject {
}

+(bool)areCredentialsExpired;
+(AmazonCredentials *)getCredentialsFromKeyChain;
+(void)storeCredentialsInKeyChain:(NSString *)theAccessKey secretKey:(NSString *)theSecretKey securityToken:(NSString *)theSecurityToken expiration:(NSString *)theExpirationDate;

+(NSString *)getValueFromKeyChain:(NSString *)key;
+(void)storeValueInKeyChain:(NSString *)value forKey:(NSString *)key;

+(void)registerDeviceId:(NSString *)uid andKey:(NSString *)key;
+(NSString *)getUidForDevice;
+(NSString *)getKeyForDevice;

+(NSDate *)convertStringToDate:(NSString *)expiration;
+(bool)isExpired:(NSDate *)date;

+(void)wipeKeyChain;
+(void)wipeCredentialsFromKeyChain;
+(NSMutableDictionary *)createKeychainDictionaryForKey:(NSString *)key;

@end
