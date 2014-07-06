//
//  TabButton.m
//  wotw
//
//  Created by sean matthews on 7/4/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

#import "TabButton.h"

@interface TabButton()
{
    UIImage *backgroundImage;
}

@end

@implementation TabButton


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _bgImage = nil;
        _shadow = YES;
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    NSLog(@"draw rect");
    CGContextRef context = UIGraphicsGetCurrentContext();

    [_bgImage drawInRect:self.bounds];
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
//    if (_shadow) {
    // TODO try putting this in a separate area?
        NSLog(@"SHADOW");
        CGContextSetLineWidth(context, 3.0);
        
        // Set stroke & shadow
        CGFloat shadowComponents[] = {0.0, 0.0, 0.0, 0.65};
        CGColorRef darkShadow = CGColorCreate(colorspace, shadowComponents);
        CGContextSetStrokeColorWithColor(context, darkShadow);
    
        // Draw this line against the view on top
//        CGContextMoveToPoint(context, rect.size.width, 0);
//        CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
//        CGContextStrokePath(context);
    
        CGContextSetShadowWithColor(context, CGSizeMake(2.0, 2.0), 0.5, darkShadow);
//    }

    // Reset stroke color & width
    CGFloat components[] = {0.5, 0.5, 0.5, 1.0};
    CGColorRef color = CGColorCreate(colorspace, components);
    CGContextSetStrokeColorWithColor(context, color);
    CGContextSetLineWidth(context, 5.0);
    
    CGContextMoveToPoint(context, rect.size.width, 0);
    CGContextAddLineToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextAddLineToPoint(context, 5, rect.size.height);
    
    CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddArcToPoint(context, 0, 0, rect.size.width, 0, 15);
    
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddArcToPoint(context, 0, rect.size.width, rect.size.width, rect.size.height, 15);
    
    CGContextStrokePath(context);
    CGColorSpaceRelease(colorspace);
    CGColorRelease(color);
}


@end
