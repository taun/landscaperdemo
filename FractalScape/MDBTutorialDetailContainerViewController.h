//
//  MDBTutorialDetailContainerViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 07/19/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MDBTutorialDetailContainerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *detailViewContainer;
@property (strong,nonatomic) NSString       *embeddedControllerIdentifier;
@property (strong,nonatomic) NSString       *nextControllerIdentifier;

@end
