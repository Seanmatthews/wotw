//
//  ViewController.m
//  wotw
//
//  Created by sean matthews on 6/28/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()
{
    BOOL keyboardIsVisible;
}

- (void)registerForNotifications;
- (void)keyboardWasShown:(NSNotification*)aNotification;
- (void)keyboardWillBeHidden:(NSNotification*)aNotification;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self registerForNotifications];
	self.canDisplayBannerAds = YES;
    _wallView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"brickwall.png"]];
    _wallView.hidden = NO;
    _mapView.hidden = YES;
    keyboardIsVisible = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (IBAction)pressedMapButton:(id)sender
{
    _mapView.hidden = NO;
    _wallView.hidden = YES;
    if (keyboardIsVisible) {
        [_textField setText:@""];
        [_textField resignFirstResponder];
    }
}

- (IBAction)pressedWallButton:(id)sender
{
    _wallView.hidden = NO;
    _mapView.hidden = YES;
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    keyboardIsVisible = YES;
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // Animate the current view out of the way
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    CGRect rect = _wallView.frame;
    rect.origin.y -= kbSize.height;
    _wallView.frame = rect;
    
    [UIView commitAnimations];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    keyboardIsVisible = NO;
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // Animate the current view back to where it was
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    CGRect rect = _wallView.frame;
    rect.origin.y += kbSize.height;
    _wallView.frame = rect;
    [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString* text = [textField text];
    if ([text length] > 0) {
        
    }
    [textField setText:@""];
    [textField resignFirstResponder];
    return YES;
}

@end
