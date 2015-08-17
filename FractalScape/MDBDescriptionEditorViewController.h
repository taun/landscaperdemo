//
//  MDBDescriptionEditorViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 08/16/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "FractalControllerProtocol.h"

@class MBLSFractalSummaryEditViewer;
@class MDBAppModel;


@interface MDBDescriptionEditorViewController : UIViewController <FractalControllerProtocol>

@property (nonatomic,weak) MDBAppModel                      *appModel;
@property (nonatomic,strong) MDBFractalDocument             *fractalDocument;
@property (nonatomic,weak) NSUndoManager                    *fractalUndoManager;
@property (weak,nonatomic) id<FractalControllerDelegate>    fractalControllerDelegate;

@property (weak, nonatomic) IBOutlet MBLSFractalSummaryEditViewer   *summaryEditView;

@end
