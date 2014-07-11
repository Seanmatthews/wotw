//
//  FirstViewController.h
//  wotw
//
//  Created by sean matthews on 7/7/14.
//  Copyright (c) 2014 Rowboat Entertainment. All rights reserved.
//

@import UIKit;

@interface FirstViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UILabel *charactersLeftLabel;

- (IBAction)pressedRefreshButton:(id)sender;

@end
