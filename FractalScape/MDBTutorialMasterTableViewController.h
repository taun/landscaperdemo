//
//  MDBTutorialMasterTableViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 07/19/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;

@class MDBTutorialPageSource;

@interface MDBTutorialMasterTableViewController : UITableViewController

@property(strong,nonatomic)IBOutlet MDBTutorialPageSource           *tutorialSource;

@property(strong,nonatomic)NSString                                 *defaultController;

@end
