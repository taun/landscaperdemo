//
//  MDBFilterControlView.h
//  FractalScapes
//
//  Created by Taun Chapman on 04/12/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MBImageFilter.h"

/*!
 UIView subclass for laying out the controls for a CIFilter 
 and updating the values of the filter based on user interaction with the controls.
 
 Take the imageFilter, investigate the inputAttributes and lay them out based on type, ...
 */
@interface MDBFilterControlView : UIView

@property(nonatomic,strong) MBImageFilter           *imageFilter;

@end
