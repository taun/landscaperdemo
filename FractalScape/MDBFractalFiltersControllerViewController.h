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

#pragma message "TODO create an ObjectTile class for holding the filter information"
/*!
 Further details:
 
 Create an object which implements ObjectTile and has the necessary properties to define a CIFilter
 Generate an array of filter tiles
 Use a view/collection similar to the color layout
    a shelf for the filters to apply
    a source of possible filters with thumbnails of result or just icon?
    area for adjusting selected filter on shelf
 
    add ObjectList property to LSFractal for storing the filter
 */

@interface MDBFractalFiltersControllerViewController : UIViewController <FractalControllerProtocol, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic,strong) MDBFractalDocument             *fractalDocument;
@property (nonatomic,weak) NSUndoManager                    *fractalUndoManager;
@property (weak,nonatomic) id<FractalControllerDelegate>    fractalControllerDelegate;
@property(nonatomic,assign) CGSize                          portraitSize;
@property(nonatomic,assign) CGSize                          landscapeSize;

@property (weak, nonatomic) IBOutlet UIPickerView *filterPicker;

@end
