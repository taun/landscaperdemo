//
//  MBFractalPropertiesViewController.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalAxiomEditViewController.h"
#import "LSFractal+addons.h"
#import "MBLSRuleTableViewCell.h"
#import "LSReplacementRule.h"

#import "MBFractalPropertyTableHeaderView.h"


@interface MBFractalAxiomEditViewController ()

/*!
 for tracking which text input field has the current focus.
 allows using a custom input keyboard.
 Want to change to a popover at some point.
 */
@property (weak, nonatomic) UITextField             *activeTextField;
@property (nonatomic, readwrite) NSArray            *sortedReplacementRulesArray;


-(void) addReplacementRulesObserverFor: (LSFractal*)fractal;
-(void) removeReplacementRulesObserverFor: (LSFractal*)fractal;

@end

#pragma mark - Implementation
@implementation MBFractalAxiomEditViewController
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString: @"replacementRules"]) {
        self.sortedReplacementRulesArray = nil;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}
-(void) addReplacementRulesObserverFor:(LSFractal *)fractal {
    [fractal addObserver: self forKeyPath: @"replacementRules" options:0 context:NULL];
}
-(void) removeReplacementRulesObserverFor:(LSFractal *)fractal {
    [fractal removeObserver: self forKeyPath:@"replacementRules"];
}
#pragma Getters&Setters
-(void) setSortedReplacementRulesArray:(NSArray *)sortedReplacementRulesArray {
    if (sortedReplacementRulesArray!=_sortedReplacementRulesArray) {
        [self removeReplacementRulesObserverFor: self.fractal];
        _sortedReplacementRulesArray = sortedReplacementRulesArray;
    }
}
-(NSArray*) sortedReplacementRulesArray {
    if (_sortedReplacementRulesArray == nil) {
        _sortedReplacementRulesArray = [self.fractal newSortedReplacementRulesArray];
        [self addReplacementRulesObserverFor: self.fractal];
    }
    return _sortedReplacementRulesArray;
}

#pragma Initialisation
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma ViewController States
- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

/* on staartup, fractal should not be set until just before view didAppear */
-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.fractalName.text = self.fractal.name;
    self.fractalCategory.text = self.fractal.category;
    self.fractalDescriptor.text = self.fractal.descriptor;
    
    self.fractalAxiom.inputView = self.fractalInputControl.view;
    self.editing = YES;
}
-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self setSortedReplacementRulesArray: nil];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

-(NSMutableDictionary*) rulesCellIndexPaths {
    if (_rulesCellIndexPaths == nil) {
        _rulesCellIndexPaths = [[NSMutableDictionary alloc] initWithCapacity: 5];
    }
    return _rulesCellIndexPaths;
}



#pragma mark - TextView Delegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    return self.editing;
}

// TODO: change to sendActionsFor...
- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == self.fractalDescriptor) {
        self.fractal.descriptor = textView.text;
    }
}

#pragma mark - TextField Delegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    return self.editing;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}

// TODO: no need for this.
// Level is by a slider and axiom below does nothing
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL result = YES;
    //    if (textField == self.fractalAxiom) {
    //        // perform continuous updating?
    //        // Could cause problems when the axiom is invalid.
    //        // How to validate axiom? Such as matching brackets.
    //        // Always apply brackets as matching pair with insertion point between the two?
    //        NSLog(@"Axiom field being edited, range = %@; string = %@", NSStringFromRange(range), string);
    //    } else if (textField == self.fractalLevel) {
    //        NSString* newString = [textField.text stringByReplacingCharactersInRange: range withString: string];
    //        NSInteger value;
    //        NSScanner *scanner = [[NSScanner alloc] initWithString: newString];
    //        if (![scanner scanInteger:&value] || !scanner.isAtEnd) {
    //            result = NO;
    //        }
    //    }
    return result;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

// TODO: calls the ruleCell action twice
// Once directly from the field and once from here.
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    //    [textField sendActionsForControlEvents: UIControlEventEditingDidEnd];
    self.activeTextField = nil;
}


#pragma mark - Custom Keyboard Handling

- (void)keyTapped:(NSString*)text {
    // Convert the TextRange to an NSRange
    NSRange selectedNSRange;
    UITextRange* textRange = [self.activeTextField selectedTextRange];
    
    NSInteger start = [self.activeTextField offsetFromPosition: self.activeTextField.beginningOfDocument
                                                    toPosition: textRange.start];
    
    NSInteger length =  [self.activeTextField offsetFromPosition: textRange.start
                                                      toPosition: textRange.end];
    
    selectedNSRange = NSMakeRange(start, length);
    
    if ([text isEqualToString: @"done"]) {
        [self.activeTextField resignFirstResponder];
        
    } else
        if ([text isEqualToString: @"delete"]) {
            // backspace
            if ([self.activeTextField.delegate textField: self.activeTextField
                           shouldChangeCharactersInRange: selectedNSRange
                                       replacementString: text] ) {
                [self.activeTextField deleteBackward];
                
            }
            
        } else
            if (self.activeTextField == self.fractalAxiom) {
                if ([self.activeTextField.delegate textField: self.activeTextField
                               shouldChangeCharactersInRange: selectedNSRange
                                           replacementString: text] ) {
                    [self.activeTextField insertText: text];
                }
            } else {
                if ([self.activeTextField.delegate textField: self.activeTextField
                               shouldChangeCharactersInRange: selectedNSRange
                                           replacementString: text] ) {
                    [self.activeTextField insertText: text];
                }
            }
}
- (void)doneTapped {
    // resign first responder? does this ever get called?
}

#pragma mark - table delegate & source
enum TableSection {
    SectionAxiom=0,
    SectionRules,
    SectionAppearance
};


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString* sectionHeader = nil;
    
    if (section == SectionAxiom) {
        // axiom
        sectionHeader = @"Axiom";
        
    } else  if (section == SectionRules) {
        // rules
        sectionHeader = @"Rules";
    }
    
    return sectionHeader;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    
    if (section == SectionAxiom) {
        // axiom
        rows = 1;
        
    } else  if (section == SectionRules) {
        // rules
        rows = [self.sortedReplacementRulesArray count];
        
    }
    return rows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    static NSString *RuleCellIdentifier = @"MBLSRuleCell";
    static NSString *AxiomCellIdentifier = @"MBLSAxiomCell";
    
    if (indexPath.section == SectionAxiom) {
        // axiom
        
        MBLSRuleTableViewCell *ruleCell = (MBLSRuleTableViewCell *)[tableView dequeueReusableCellWithIdentifier: AxiomCellIdentifier];
        
        // Configure the cell with data from the managed object.
        UITextField* axiom = ruleCell.textRight;
        self.fractalAxiom = axiom; // may be unneccessary?
        axiom.text = self.fractal.axiom;
        
        axiom.inputView = self.fractalInputControl.view;
        axiom.delegate = self;
        [axiom addTarget: self
                  action: @selector(axiomInputChanged:)
        forControlEvents: (UIControlEventEditingChanged | UIControlEventEditingDidEnd)];
        
        cell = ruleCell;
        
    } else if (indexPath.section == SectionRules) {
        // rules
        
        MBLSRuleTableViewCell *ruleCell = (MBLSRuleTableViewCell *)[tableView dequeueReusableCellWithIdentifier: RuleCellIdentifier];
        LSReplacementRule* rule = (self.sortedReplacementRulesArray)[indexPath.row];
        
        // Configure the cell with data from the managed object.
        ruleCell.textLeft.text = rule.contextString;
        ruleCell.textRight.text = rule.replacementString;
        
        ruleCell.textRight.inputView = self.fractalInputControl.view;
        ruleCell.textRight.delegate = self;
        
        // notify textRight delegate of cell change
        // calls delegate back ruleCellTextRightEditingEnded:
        // a way to pass both fields of the rule cell
        [ruleCell.textRight addTarget: ruleCell
                               action: @selector(textRightEditingEnded:)
                     forControlEvents: UIControlEventEditingDidEnd];
        
        cell = ruleCell;
        (self.rulesCellIndexPaths)[rule.contextString] = indexPath;
        
    } else if (indexPath.section == 2) {
        // ?
    }
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Accessory view");
}

#pragma mark - Rule Cell Delegate
-(void)ruleCellTextRightEditingEnded:(id)sender {
    if ([sender isKindOfClass: [MBLSRuleTableViewCell class]]) {
        MBLSRuleTableViewCell* ruleCell = (MBLSRuleTableViewCell*) sender;
        
        NSString* ruleKey = ruleCell.textLeft.text;
        NSArray* rules = self.sortedReplacementRulesArray;
        
        // Find the relevant rule for this cell using the key
        // could do the following using a query
        for (LSReplacementRule* rule in rules) {
            if ([rule.contextString isEqualToString: ruleKey]) {
                rule.replacementString = ruleCell.textRight.text;
            }
        }
    }
}

-(NSNumberFormatter*) twoPlaceFormatter {
    if (_twoPlaceFormatter == nil) {
        _twoPlaceFormatter = [[NSNumberFormatter alloc] init];
        [_twoPlaceFormatter setAllowsFloats: YES];
        [_twoPlaceFormatter setMaximumFractionDigits: 2];
        [_twoPlaceFormatter setMaximumIntegerDigits: 3];
        [_twoPlaceFormatter setPositiveFormat: @"##0.00"];
        [_twoPlaceFormatter setNegativeFormat: @"-##0.00"];
    }
    return _twoPlaceFormatter;
}

#pragma mark - Actions
- (IBAction)nameInputDidEnd:(UITextField*)sender {
    self.fractal.name = sender.text;
}
- (IBAction)axiomInputChanged:(UITextField*)sender {
    self.fractal.axiom = sender.text;
}

- (IBAction)axiomInputEnded:(UITextField*)sender {
    // update rule editing table?
}



@end
