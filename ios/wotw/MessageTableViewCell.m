//
//  MessageTableViewCell.m
//  wotw
//
//  Created by sean matthews on 7/1/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

#import "MessageTableViewCell.h"

@implementation MessageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.frame = CGRectMake(60, 2, 250, self.textLabel.frame.size.height-4);
//    self.textLabel.frame = CGRectMake(10, 2, 300, self.textLabel.frame.size.height-4);
    self.textLabel.layer.cornerRadius = 10;
    self.textLabel.layer.masksToBounds = YES;
    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.textLabel.numberOfLines = 0;
    self.textLabel.font = [UIFont systemFontOfSize:13.];
    [self.textLabel setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.75]];
}

@end
