//
//  AmazonKeyChainWrapper.m
//  wotw
//
//  Created by sean matthews on 4/9/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import "AmazonKeyChainWrapper.h"
#import <AWSiOSSDK/AmazonLogger.h>


static NSString *kKeychainAccessKeyIdentifier      = @"AWSiOSDemoTVM.com.amazon.aws.demo.AWSAccessKey";
static NSString *kKeychainSecretKeyIdentifier      = @"AWSiOSDemoTVM.com.amazon.aws.demo.AWSSecretKey";
static NSString *kKeychainSecrutiyTokenIdentifier  = @"AWSiOSDemoTVM.com.amazon.aws.demo.AWSSecurityToken";
static NSString *kKeychainExpirationDateIdentifier = @"AWSiOSDemoTVM.com.amazon.aws.demo.AWSExpirationDate";

static NSString *kKeychainUidIdentifier = @"AWSiOSDemoTVM.com.amazon.aws.demo.UID";
static NSString *kKeychainKeyIdentifier = @"AWSiOSDemoTVM.com.amazon.aws.demo.KEY";


@implementation AmazonKeyChainWrapper

+(bool)areCredentialsExpired
{
    AMZLogDebug(@"areCredentialsExpired");
    
    NSString *expiration = [AmazonKeyChainWrapper getValueFromKeyChain:kKeychainExpirationDateIdentifier];
    if (expiration == nil) {
        return YES;
    }
    else {
        NSDate *expirationDate = [AmazonKeyChainWrapper convertStringToDate:expiration];
        
        AMZLog(@"expirationDate : %@, %@", expiration, expirationDate);
        
        return [AmazonKeyChainWrapper isExpired:expirationDate];
    }
}

+(void)registerDeviceId:(NSString *)uid andKey:(NSString *)key
{
    [AmazonKeyChainWrapper storeValueInKeyChain:uid forKey:kKeychainUidIdentifier];
    [AmazonKeyChainWrapper storeValueInKeyChain:key forKey:kKeychainKeyIdentifier];
}

+(NSString *)getKeyForDevice
{
    return [AmazonKeyChainWrapper getValueFromKeyChain:kKeychainKeyIdentifier];
}

+(NSString *)getUidForDevice
{
    return [AmazonKeyChainWrapper getValueFromKeyChain:kKeychainUidIdentifier];
}

+(AmazonCredentials *)getCredentialsFromKeyChain
{
    NSString *accessKey     = [AmazonKeyChainWrapper getValueFromKeyChain:kKeychainAccessKeyIdentifier];
    NSString *secretKey     = [AmazonKeyChainWrapper getValueFromKeyChain:kKeychainSecretKeyIdentifier];
    NSString *securityToken = [AmazonKeyChainWrapper getValueFromKeyChain:kKeychainSecrutiyTokenIdentifier];
    
    if ((accessKey != nil) && (secretKey != nil) && (securityToken != nil)) {
        if (![AmazonKeyChainWrapper areCredentialsExpired]) {
            AmazonCredentials *credentials = [[AmazonCredentials alloc] initWithAccessKey:accessKey withSecretKey:secretKey];
            credentials.securityToken = securityToken;
            
            return credentials;
        }
    }
    
    return nil;
}

+(void)storeCredentialsInKeyChain:(NSString *)theAccessKey secretKey:(NSString *)theSecretKey securityToken:(NSString *)theSecurityToken expiration:(NSString *)theExpirationDate
{
    [AmazonKeyChainWrapper storeValueInKeyChain:theAccessKey forKey:kKeychainAccessKeyIdentifier];
    [AmazonKeyChainWrapper storeValueInKeyChain:theSecretKey forKey:kKeychainSecretKeyIdentifier];
    [AmazonKeyChainWrapper storeValueInKeyChain:theSecurityToken forKey:kKeychainSecrutiyTokenIdentifier];
    [AmazonKeyChainWrapper storeValueInKeyChain:theExpirationDate forKey:kKeychainExpirationDateIdentifier];
}

+(bool)isExpired:(NSDate *)date
{
    NSDate *soon = [NSDate dateWithTimeIntervalSinceNow:(15 * 60)];  // Fifteen minutes from now.
    
    if ( [soon compare:date] == NSOrderedDescending) {
        return YES;
    }
    else {
        return NO;
    }
}

+(NSDate *)convertStringToDate:(NSString *)expiration
{
    if (expiration != nil) {
        long long exactSecondOfExpiration = (long long)([expiration longLongValue] / 1000);
        return [[NSDate alloc] initWithTimeIntervalSince1970:exactSecondOfExpiration];
    }
    else {
        return nil;
    }
}

+(NSString *)getValueFromKeyChain:(NSString *)key
{
    AMZLogDebug(@"Get Value for KeyChain key:[%@]", key);
    
    NSMutableDictionary *queryDictionary = [[NSMutableDictionary alloc] init];
    
    [queryDictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecAttrGeneric];
    [queryDictionary setObject:(id) kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    [queryDictionary setObject:(__bridge id) kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [queryDictionary setObject:(id) kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [queryDictionary setObject:(__bridge id) kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    CFDataRef attributes;
    //NSDictionary *returnedDictionary = [[NSMutableDictionary alloc] init];
    //OSStatus     keychainError       = SecItemCopyMatching((__bridge CFDictionaryRef)queryDictionary, (CFTypeRef *)&returnedDictionary);
    OSStatus     keychainError       = SecItemCopyMatching((__bridge_retained CFDictionaryRef)queryDictionary, (CFTypeRef*)&attributes);
    if (keychainError == noErr)
    {
        //NSData *rawData = [returnedDictionary objectForKey:(__bridge id)kSecValueData];
        NSData* rawData=(__bridge_transfer NSData*) attributes; 
        return [[NSString alloc] initWithBytes:[rawData bytes] length:[rawData length] encoding:NSUTF8StringEncoding];
    }
    else
    {
        return nil;
    }
}

+(void)storeValueInKeyChain:(NSString *)value forKey:(NSString *)key
{
    AMZLogDebug(@"Storing value:[%@] in KeyChain as key:[%@]", value, key);
    
    NSMutableDictionary *keychainDictionary = [[NSMutableDictionary alloc] init];
    [keychainDictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding]      forKey:(__bridge id)kSecAttrGeneric];
    [keychainDictionary setObject:(__bridge id) kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [keychainDictionary setObject:[value dataUsingEncoding:NSUTF8StringEncoding]    forKey:(__bridge id)kSecValueData];
    [keychainDictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding]      forKey:(__bridge id)kSecAttrAccount];
    [keychainDictionary setObject:(__bridge id) kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    
    OSStatus keychainError = SecItemAdd((__bridge CFDictionaryRef)keychainDictionary, NULL);
    if (keychainError == errSecDuplicateItem) {
        SecItemDelete((__bridge CFDictionaryRef)keychainDictionary);
        SecItemAdd((__bridge CFDictionaryRef)keychainDictionary, NULL);
    }
}

+(void)wipeKeyChain
{
    OSStatus keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey : kKeychainAccessKeyIdentifier]);
    
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey : kKeychainSecretKeyIdentifier]);
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey : kKeychainSecrutiyTokenIdentifier]);
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey : kKeychainExpirationDateIdentifier]);
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey : kKeychainUidIdentifier]);
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey : kKeychainKeyIdentifier]);
}

+(void)wipeCredentialsFromKeyChain
{
    OSStatus keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey : kKeychainAccessKeyIdentifier]);
    
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey : kKeychainSecretKeyIdentifier]);
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey : kKeychainSecrutiyTokenIdentifier]);
    keychainError = SecItemDelete((__bridge CFDictionaryRef)[AmazonKeyChainWrapper createKeychainDictionaryForKey : kKeychainExpirationDateIdentifier]);
}

+(NSMutableDictionary *)createKeychainDictionaryForKey:(NSString *)key
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    [dictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding]      forKey:(__bridge id)kSecAttrGeneric];
    [dictionary setObject:(__bridge id) kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [dictionary setObject:[key dataUsingEncoding:NSUTF8StringEncoding]      forKey:(__bridge id)kSecAttrAccount];
    [dictionary setObject:(__bridge id) kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    
    return dictionary;
}

@end