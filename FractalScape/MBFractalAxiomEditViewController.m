//
//  MBFractalPropertiesViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalAxiomEditViewController.h"
#import "LSFractal+addons.h"
#import "MBLSRuleTableViewCell.h"
#import "LSReplacementRule.h"

#import "MBFractalPropertyTableHeaderView.h"
#import "MBBasicLabelTextTableCell.h"
#import "MBTextViewTableCell.h"

#import "MBStyleKitButton.h"

@interface MBFractalAxiomEditViewController ()

/*!
 for tracking which text input field has the current focus.
 allows using a custom input keyboard.
 Want to change to a popover at some point.
 */
@property (weak, nonatomic) UITextField             *activeTextField;
@property (nonatomic, readwrite) NSArray            *sortedReplacementRulesArray;

@property (nonatomic,strong) NSArray                *tableSections;

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
    if (fractal) {
        [fractal addObserver: self forKeyPath: @"replacementRules" options:0 context:NULL];
//        NSLog(@"Add Observer: %@ for fractal: %@", self, fractal.name);
    }
}
-(void) removeReplacementRulesObserverFor:(LSFractal *)fractal {
    @try {
        if (fractal) {
            [fractal removeObserver: self forKeyPath:@"replacementRules"];
//            NSLog(@"Remove Observer: %@ for fractal: %@", self, fractal.name);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Exception Observer: %@ missing for fractal: %@", self, fractal.name);
    }
    @finally {
        //Code that gets executed whether or not an exception is thrown
    }
}
#pragma mark - Getters & Setters
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
-(FractalDefinitionKeyboardView*) fractalInputControl {
    if (_fractalInputControl == nil) {
        _fractalInputControl = [FractalDefinitionKeyboardView new];
        _fractalInputControl.delegate = self;
    }
    return _fractalInputControl;
}
#pragma mark - Initialisation
- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - ViewController States
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableSections = @[@"Description", @"Starting Rule", @"Replacement Rules"];
    
//    self.fractalPropertiesTableView.estimatedRowHeight = 44;
//    self.fractalPropertiesTableView.rowHeight = UITableViewAutomaticDimension;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

/* on staartup, fractal should not be set until just before view didAppear */
-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    self.fractalName.text = self.fractal.name;
//    self.fractalCategory.text = self.fractal.category;
//    self.fractalDescriptor.text = self.fractal.descriptor;
    [self.tableView reloadData];
//    self.fractalAxiom.inputView = self.fractalInputControl.view;

    [self setEditing: YES animated: NO];
}
-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // removes all fractal observers.
    [self setSortedReplacementRulesArray: nil];
    // nil out, so old fractal does not get re-used when controller starts to reappear.
    self.fractal = nil;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self.fractalPropertiesTableView setEditing:editing animated:YES];
//    if (editing) {
//        addButton.enabled = NO;
//    } else {
//        addButton.enabled = YES;
//    }
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
//    if (textView == self.fractalDescriptor) {
//        self.fractal.descriptor = textView.text;
//    }
    self.fractal.descriptor = textView.text;
    [self saveContext];
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
    [self saveContext];
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
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.tableSections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString* sectionHeader = (self.tableSections)[section];
    
    return sectionHeader;
}
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    NSString* sectionHeader = (self.tableSections)[section];
    
    UITableViewCell *sectionView = (MBBasicLabelTextTableCell *)[tableView dequeueReusableCellWithIdentifier: @"HeaderCell"];
    sectionView.textLabel.text = sectionHeader;
    
    return sectionView;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 1;
    if (section==0) {
        rows = 3;
    } else if (section == ([self.tableSections count] -1)) {
        // rules
        rows = [self.sortedReplacementRulesArray count];
    }
    return rows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    static NSString *NameCellIdentifier = @"NameCell";
    static NSString *CategoryCellIdentifier = @"CategoryCell";
    static NSString *DescriptionCellIdentifier = @"DescriptionCell";
    static NSString *RuleCellIdentifier = @"MBLSRuleCell";
    static NSString *AxiomCellIdentifier = @"MBLSAxiomCell";
    
    if (indexPath.section == 0) {
        // description
        if (indexPath.row==0) {
            //name
            MBBasicLabelTextTableCell *newCell = (MBBasicLabelTextTableCell *)[tableView dequeueReusableCellWithIdentifier: NameCellIdentifier];
            newCell.textLabel.text = @"Name:";
            newCell.textField.text = self.fractal.name;
            newCell.textField.delegate = self;
            [newCell.textField addTarget: self
                                 action: @selector(nameInputChanged:)
                       forControlEvents: (UIControlEventEditingChanged | UIControlEventEditingDidEnd)];
            cell = newCell;
        } else if (indexPath.row==1) {
            MBBasicLabelTextTableCell *newCell = (MBBasicLabelTextTableCell *)[tableView dequeueReusableCellWithIdentifier: CategoryCellIdentifier];
            newCell.textLabel.text = @"Category:";
            newCell.textField.text = self.fractal.category;
            newCell.textField.delegate = self;
            [newCell.textField addTarget: self
                                  action: @selector(categoryInputChanged:)
                        forControlEvents: (UIControlEventEditingChanged | UIControlEventEditingDidEnd)];
            cell = newCell;
        } else if (indexPath.row==2) {
            MBTextViewTableCell *newCell = (MBTextViewTableCell *)[tableView dequeueReusableCellWithIdentifier: DescriptionCellIdentifier];
//            newCell.textLabel.text = @"Description:";
            newCell.textView.text = self.fractal.descriptor;
            newCell.textView.delegate = self;
            cell = newCell;
        }
    } else if (indexPath.section == 1) {
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
        
    } else if (indexPath.section == 2) {
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
                     forControlEvents: (UIControlEventEditingChanged | UIControlEventEditingDidEnd)];
        
        cell = ruleCell;
        (self.rulesCellIndexPaths)[rule.contextString] = indexPath;
        
    } 
    
    return cell;
}
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    CGFloat rowHeight = tableView.rowHeight;
//    if (indexPath.section==0 && indexPath.row==2) {
//        // description cell
//        rowHeight = 91.0;
//    }
//    return rowHeight;
//}
- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;
    
    if (indexPath.section == 2) {
        // Rules
        if (indexPath.row == ([self.sortedReplacementRulesArray count] -1)) {
            editingStyle = UITableViewCellEditingStyleInsert;
        } else {
            editingStyle = UITableViewCellEditingStyleDelete;
        }
    }
    return editingStyle;
}
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
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Accessory view");
}
- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Edditing row %@", indexPath);
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
        [self saveContext];
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
    [self saveContext];
}
- (IBAction)axiomInputChanged:(UITextField*)sender {
    self.fractal.axiom = sender.text;
    [self saveContext];
}

- (IBAction)axiomInputEnded:(UITextField*)sender {
    // update rule editing table?
}
-(IBAction)nameInputChanged:(UITextField*)sender {
    self.fractal.name = sender.text;
}
-(IBAction)categoryInputChanged:(UITextField*)sender {
    self.fractal.category = sender.text;
}
-(IBAction)descriptorInputChanged:(UITextView*)sender {
    self.fractal.descriptor = sender.text;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.fractal.managedObjectContext;
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


@end
