//
//  MBFractalPropertiesViewController.h
//  LandscaperDemo
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
                                                                        UITextFieldDelegate,
                                                                        UITextViewDelegate,
                                                                        MBLSRuleTableViewCellDelegate,
                                                                        FractalDefinitionKVCDelegate>
{
    __strong NSArray        *_sortedReplacementRulesArray;
}

@property (nonatomic,weak) LSFractal        *fractal;
@property (nonatomic,weak) NSUndoManager    *fractalUndoManager;


@property (weak, nonatomic) IBOutlet UITableView  *fractalPropertiesTableView;
//@property (weak, nonatomic) IBOutlet UIView       *fractalPropertyTableHeaderView;
//@property (weak, nonatomic) IBOutlet UITextField  *fractalName;
//@property (weak, nonatomic) IBOutlet UITextField  *fractalCategory;
//@property (weak, nonatomic) IBOutlet UITextView   *fractalDescriptor;

#pragma mark - Production Fields
@property (weak, nonatomic) IBOutlet UITextField                        *fractalAxiom;

@property (nonatomic, readonly) NSArray                                 *sortedReplacementRulesArray;

/*!
 Custom keyboard for inputting fractal axioms and rules.
 Change to a popover?
 */
@property (strong, nonatomic) IBOutlet FractalDefinitionKeyboardView    *fractalInputControl;
@property (nonatomic, strong) NSMutableDictionary                       *rulesCellIndexPaths;

@property (nonatomic, strong) NSNumberFormatter                         *twoPlaceFormatter;

//-(void) reloadLabels;

#pragma mark - Fractal Definition Input Protocol
- (void)keyTapped:(NSString*)title;
- (void)doneTapped;

#pragma mark - Production Control Actions
- (IBAction)axiomInputChanged:(UITextField*)sender;
- (IBAction)axiomInputEnded:(UITextField*)sender;


@end
