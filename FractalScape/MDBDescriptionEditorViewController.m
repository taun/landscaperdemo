//
//  MDBDescriptionEditorViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/16/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBDescriptionEditorViewController.h"
#import "LSFractal.h"
#import "MBLSFractalSummaryEditView.h"

@interface MDBDescriptionEditorViewController ()

@end

@implementation MDBDescriptionEditorViewController


-(void)setFractalDocument:(MDBFractalDocument *)fractalDocument
{
    if (_fractalDocument != fractalDocument)
    {
        _fractalDocument = fractalDocument;
        self.summaryEditView.fractalDocument = _fractalDocument;
    }
}

@end
