//
//  MBFractalPropertiesViewController.h
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalControllerProtocol.h"
#import "MBLSRuleTableViewCell.h"

@class LSFractal;

@interface MBFractalAxiomEditViewController : UITableViewController <FractalControllerProtocol,
                                                                        UIGestureRecognizerDelegate,
                                                                        UIPickerViewDataSource,
                                                                        UIPickerViewDelegate,
                                                                        UITextViewDelegate>

@property (nonatomic,strong) LSFractal                                *fractal;
@property (nonatomic,weak) NSUndoManager                            *fractalUndoManager;


#pragma mark - Production Fields

@property (nonatomic, strong) NSMutableDictionary                       *rulesCellIndexPaths;

@property (nonatomic, strong) NSNumberFormatter                         *twoPlaceFormatter;


#pragma mark - Production Control Actions
- (IBAction)nameInputDidEnd:(UITextField*)sender;
- (IBAction)nameInputChanged:(id)sender;
//- (IBAction)descriptorInputChanged:(id)sender;
- (IBAction)categoryInputChanged:(id)sender;
- (IBAction)categoryInputDidEnd:(UITextField*)sender;
- (IBAction)replacementRuleLongPress:(UILongPressGestureRecognizer *)sender;
- (IBAction)rulesSourceLongPress:(UILongPressGestureRecognizer *)sender;
- (IBAction)axiomRuleLongPress:(id)sender;
- (IBAction)placeholderLongPress:(id)sender;

@end
