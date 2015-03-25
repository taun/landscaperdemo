//
//  MDBFractalFiltersControllerViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 02/17/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;


#import "FractalControllerProtocol.h"


@interface MDBFractalFiltersControllerViewController : UIViewController <FractalControllerProtocol, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic,strong) MDBFractalDocument             *fractalDocument;
@property (nonatomic,weak) NSUndoManager                    *fractalUndoManager;
@property (weak,nonatomic) id<FractalControllerDelegate>    fractalControllerDelegate;
@property(nonatomic,assign) CGSize                          portraitSize;
@property(nonatomic,assign) CGSize                          landscapeSize;

@property (weak, nonatomic) IBOutlet UIPickerView *filterPicker;

@end
