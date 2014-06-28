//
//  Response.h
//  wotw
//
//  Created by sean matthews on 4/9/12.
//  Copyright (c) 2012 Blink Gear. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Response:NSObject {
    int      code;
    NSString *__weak message;
}

@property (nonatomic) int              code;
@property (weak, nonatomic) NSString *message;

-(id)initWithCode:(int)code andMessage:(NSString *)message;
-(bool)wasSuccessful;

@end