//
//  MBLSFractalEditViewController.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/27/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSFractal.h"
#import "FractalDefinitionKeyboardView.h"

@interface MBLSFractalEditViewController : UIViewController <FractalDefinitionKVCDelegate, UITextFieldDelegate>

@property (nonatomic, weak) NSManagedObjectContext* appManagedObjectContext;
@property (nonatomic, strong) LSFractal*            currentFractal;
@property (weak, nonatomic) IBOutlet UITextField    *fractalNameTextField;
@property (weak, nonatomic) IBOutlet UITextField    *fractalAxiomTextField;
@property (weak, nonatomic) IBOutlet UIView         *fractalLevelView0;
@property (weak, nonatomic) IBOutlet UIView         *fractalLevelView1;
@property (weak, nonatomic) IBOutlet UIView         *fractalLevelViewN;
@property (weak, nonatomic) IBOutlet UITextField    *lineLengthTextField;

@property (weak, nonatomic) UITextField*            activeTextField;

@property (strong, nonatomic) IBOutlet FractalDefinitionKeyboardView *fractalInputControl;

#pragma mark - Fractal Definition Input Protocol
- (void)keyTapped:(NSString*)title;
- (void)doneTapped;
- (IBAction)lineLengthInputChanged:(id)sender;

@end
