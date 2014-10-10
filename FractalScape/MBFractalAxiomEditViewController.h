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
#import "FractalDefinitionKeyboardView.h"

@class LSFractal;

@interface MBFractalAxiomEditViewController : UITableViewController <FractalControllerProtocol,
                                                                        UICollectionViewDelegate,
                                                                        UIGestureRecognizerDelegate,
                                                                        UITextFieldDelegate,
                                                                        UITextViewDelegate,
                                                                        MBLSRuleTableViewCellDelegate,
                                                                        FractalDefinitionKVCDelegate>
//{
//    __strong NSArray        *_sortedReplacementRulesArray;
//}

@property (nonatomic,weak) LSFractal                                *fractal;
@property (nonatomic,weak) NSUndoManager                            *fractalUndoManager;


#pragma mark - Production Fields

//@property (nonatomic, readonly) NSArray                                 *sortedReplacementRulesArray;

/*!
 Custom keyboard for inputting fractal axioms and rules.
 Change to a popover?
 */
@property (strong, nonatomic) FractalDefinitionKeyboardView             *fractalInputControl;
@property (nonatomic, strong) NSMutableDictionary                       *rulesCellIndexPaths;

@property (nonatomic, strong) NSNumberFormatter                         *twoPlaceFormatter;

//-(void) reloadLabels;

#pragma mark - Fractal Definition Input Protocol
- (void)keyTapped:(NSString*)title;
- (void)doneTapped;

#pragma mark - Production Control Actions
- (IBAction)axiomInputChanged:(UITextField*)sender;
- (IBAction)axiomInputEnded:(UITextField*)sender;
- (IBAction)nameInputDidEnd:(UITextField*)sender;
- (IBAction)nameInputChanged:(id)sender;
- (IBAction)descriptorInputChanged:(id)sender;
- (IBAction)categoryInputChanged:(id)sender;
- (IBAction)categoryInputDidEnd:(UITextField*)sender;
- (IBAction)ruleLongPress:(UILongPressGestureRecognizer *)sender;

@end
