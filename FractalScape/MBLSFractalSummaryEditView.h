//
//  MBLSFractalSummaryEditView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;


@class MDBFractalDocument;

IB_DESIGNABLE


/*!
 View to show the fractal name, descriptor and category. Allows editing of the fields.
 */
@interface MBLSFractalSummaryEditViewer : UIView <  UITextFieldDelegate,
                                                    UITextViewDelegate>

@property (nonatomic,strong) MDBFractalDocument         *fractalDocument;
@property (nonatomic,weak) IBOutlet UITextField         *name;
@property (nonatomic,weak) IBOutlet UITextView          *descriptor;
@property (nonatomic,strong) IBInspectable UIColor      *borderColor;

- (IBAction)descriptorTextViewTapped:(UITapGestureRecognizer *)sender;

@end
