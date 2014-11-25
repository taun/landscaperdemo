//
//  MBFractalRulesEditorViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalControllerProtocol.h"
#import "MBLSFractalSummaryEditView.h"
#import "MBLSRulesListTileView.h"


@class LSFractal;

@interface MBFractalRulesEditorViewController : UIViewController <FractalControllerProtocol>

@property (nonatomic,strong) LSFractal          *fractal;
@property (nonatomic,weak) NSUndoManager        *fractalUndoManager;

@property (weak, nonatomic) IBOutlet MBLSFractalSummaryEditView *fractalSummaryEditView;
@property (weak, nonatomic) IBOutlet MBLSRulesListTileView *fractalStartRulesListView;

@end
