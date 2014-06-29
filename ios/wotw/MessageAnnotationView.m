//
//  MessageAnnotationView.m
//  wotw
//
//  Created by sean matthews on 6/29/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

#import "MessageAnnotationView.h"

@interface MessageAnnotationView()
{
    UILabel *calloutView;
}

@end

@implementation MessageAnnotationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        calloutView = nil;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (selected) {
        if (calloutView == nil) {
            CGRect calloutFrame = CGRectMake(0, 0, 0, 0); // TODO
            calloutView = [[UILabel alloc] initWithFrame:calloutFrame];
            calloutView.numberOfLines = 0;
            calloutView.lineBreakMode = NSLineBreakByWordWrapping;
            [self addSubview:calloutView];
        }
        calloutView.hidden = NO;
    }
    else {
        for (UIView *view in self.subviews) {
            if ([view isKindOfClass:[UILabel class]]) {
                view.hidden = YES;
            }
        }
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
