//
//  MDBWelcomeViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 07/28/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MDBAppModel;

@interface MDBWelcomeViewController : UIViewController

@property (nonatomic,weak) MDBAppModel                                    *appModel;

- (IBAction)welcomeDone:(UIButton *)sender;

@end
