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


@interface MBLSFractalSummaryEditViewer : UIView <UIPickerViewDataSource,
                                                    UIPickerViewDelegate,
                                                    UITextFieldDelegate,
                                                    UITextViewDelegate>

@property (nonatomic,strong) LSFractal              *fractal;
@property (nonatomic,strong) UITextField            *name;
@property (nonatomic,strong) UITextView             *descriptor;
@property (nonatomic,strong) UIPickerView           *category;
@property (nonatomic,strong) IBInspectable UIColor  *borderColor;
@end
