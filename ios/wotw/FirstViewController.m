//
//  FirstViewController.m
//  wotw
//
//  Created by sean matthews on 7/7/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

#import "FirstViewController.h"
#import "MessageRepo.h"
#import "MessageTableViewCell.h"
#import "Location.h"



@interface FirstViewController ()

- (void)registerForNotifications;
- (void)refreshTable:(UIRefreshControl*)refreshControl;

@end


@implementation FirstViewController


static int const PrivateKVOContextOne;
const NSUInteger TABBAR_HEIGHT_ = 49;
const short MESSAGE_CHAR_LIMIT = 100;


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self registerForNotifications];

    _tableView.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"brickwall.png"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[MessageRepo sharedInstance] refreshMessages];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedFirstLocation)
                                                 name:@"LocationUpdateNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // KVO
    [[MessageRepo sharedInstance] addObserver:self
                                   forKeyPath:@"messages"
                                      options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionNew
                                      context:nil];
}


#pragma mark - UI Behaviors

- (IBAction)pressedRefreshButton:(id)sender
{
    [[MessageRepo sharedInstance] refreshMessages];
    [self refreshTable:nil];
}

// Fill the "model" with NSString messages
- (void)refreshTable:(UIRefreshControl *)refreshControl
{
    [[MessageRepo sharedInstance] refreshMessages];
    
    if (refreshControl) {
        [refreshControl endRefreshing];
    }
    
    NSUInteger messageCount = [[[MessageRepo sharedInstance] messages] count];
    if (messageCount > 0) {
        [_tableView reloadData];
        NSIndexPath* path = [NSIndexPath indexPathForRow:messageCount-1 inSection:0];
        [_tableView scrollToRowAtIndexPath:path
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:NO];
        
    }
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
//    keyboardIsVisible = YES;
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // Animate the current view out of the way
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    CGRect rect = self.view.frame;
    rect.origin.y -= kbSize.height - TABBAR_HEIGHT_;
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
//    keyboardIsVisible = NO;
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // Animate the current view back to where it was
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    CGRect rect = self.view.frame;
    rect.origin.y += kbSize.height - TABBAR_HEIGHT_;
    self.view.frame = rect;
    [UIView commitAnimations];
}


#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 66.;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[MessageRepo sharedInstance] messages] count];
}

// This function is for recovering cells, or initializing a new one.
// It is not for filling in cell data.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"CellIdentifier";
    MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                           reuseIdentifier:CellIdentifier];
    }
    
    // Add padding to the text in the cell
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.firstLineHeadIndent = 4;
    style.headIndent = 4;
    style.lineBreakMode = NSLineBreakByWordWrapping;
    style.alignment = NSTextAlignmentCenter;
    cell.textLabel.attributedText = [[NSAttributedString alloc]
                                     initWithString:[[MessageRepo sharedInstance] messages][indexPath.row]
                                         attributes:@{NSParagraphStyleAttributeName: style}];
    return cell;
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString* text = [textField text];
    if ([text length] > 0) {
        // Send message to server
        [[MessageRepo sharedInstance] writeOnWall:text];
    }
    _charactersLeftLabel.text = [NSString stringWithFormat:@"%d characters left", MESSAGE_CHAR_LIMIT];
    [textField setText:@""];
    [textField resignFirstResponder];
    [self refreshTable:nil];
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    BOOL shouldChange = (newLength > MESSAGE_CHAR_LIMIT) ? NO : YES;
    
    if (shouldChange) {
        _charactersLeftLabel.text = [NSString stringWithFormat:@"%d characters left",
                                     MESSAGE_CHAR_LIMIT - newLength];
    }
    
    return shouldChange;
}


#pragma mark - Notifications

- (void)receivedFirstLocation
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LocationUpdateNotification" object:nil];
    [self refreshTable:nil];
}

// Using this in a very simplistic manner-- when the messages array changes, reload the table
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context == &PrivateKVOContextOne) {
//        NSLog(@"change %@",change[NSKeyValueChangeNewKey]);
        [_tableView reloadData];
    }
}


@end
