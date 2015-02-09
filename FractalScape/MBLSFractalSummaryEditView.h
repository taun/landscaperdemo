//
//  MBLSFractalSummaryEditView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LSFractal+addons.h"

IB_DESIGNABLE


/*!
 View to show the fractal name, descriptor and category. Allows editing of the fields.
 */
@interface MBLSFractalSummaryEditViewer : UIView <UIPickerViewDataSource,
                                                    UIPickerViewDelegate,
                                                    UITextFieldDelegate,
                                                    UITextViewDelegate>

@property (nonatomic,strong) LSFractal                  *fractal;
@property (nonatomic,weak) IBOutlet UITextField         *name;
@property (nonatomic,weak) IBOutlet UITextView          *descriptor;
@property (nonatomic,weak) IBOutlet UIPickerView        *category;
@property (nonatomic,strong) IBInspectable UIColor      *borderColor;
@end
