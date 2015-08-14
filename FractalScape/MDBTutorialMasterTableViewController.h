//
//  MDBTutorialMasterTableViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 07/19/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;

@class MDBTutorialSource;

@interface MDBTutorialMasterTableViewController : UITableViewController

@property(strong,nonatomic)IBOutlet MDBTutorialSource        *tutorialSource;

@property(strong,nonatomic)NSString                             *defaultController;

@end
