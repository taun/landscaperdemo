//
//  MBFractalPropertiesViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBFractalAxiomEditViewController.h"
#import "LSFractal+addons.h"
#import "LSDrawingRule+addons.h"
#import "LSDrawingRuleType+addons.h"
#import "LSReplacementRule+addons.h"
//#import "MBFractalPropertyTableHeaderView.h"

#import "MBFractalTableDataSource.h"
#import "MBAxiomEditorTableSection.h"

#import "MBStyleKitButton.h"
#import "MBDraggingRule.h"

@interface MBFractalAxiomEditViewController ()

/*!
 for tracking which text input field has the current focus.
 allows using a custom input keyboard.
 Want to change to a popover at some point.
 */
@property (weak, nonatomic) UITextField                         *activeTextField;

@property (nonatomic,strong) NSDictionary                       *cachedRulesDictionary;
@property (nonatomic,strong) IBOutlet MBFractalTableDataSource  *fractalTableSource;
@property (nonatomic,strong) NSMutableArray                     *fractalTableData;
@property (nonatomic,assign) BOOL                               fractalDataChanged;
@property (nonatomic,strong) MBDraggingRule                     *draggingRule;

-(void) addReplacementRulesObserverFor: (LSFractal*)fractal;
-(void) removeReplacementRulesObserverFor: (LSFractal*)fractal;

@end

#pragma mark - Implementation
@implementation MBFractalAxiomEditViewController
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString: @"replacementRules"]) {
//        self.sortedReplacementRulesArray = nil;
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
//-(void) setSortedReplacementRulesArray:(NSArray *)sortedReplacementRulesArray {
//    if (sortedReplacementRulesArray!=_sortedReplacementRulesArray) {
//        [self removeReplacementRulesObserverFor: self.fractal];
//        _sortedReplacementRulesArray = sortedReplacementRulesArray;
//    }
//}
//-(NSArray*) sortedReplacementRulesArray {
//    if (_sortedReplacementRulesArray == nil) {
//        _sortedReplacementRulesArray = [self.fractal newSortedReplacementRulesArray];
//        [self addReplacementRulesObserverFor: self.fractal];
//    }
//    return _sortedReplacementRulesArray;
//}
-(void) setFractal:(LSFractal *)fractal {
    if (_fractal != fractal) {
        _fractal = fractal;
        
        self.cachedRulesDictionary = nil;
        self.fractalTableSource.fractalData = self.fractalTableData;
        
        [self.tableView reloadData];
//        for (id key in self.rulesCollectionsDict) {
//            
//            UICollectionView* collection = (UICollectionView*)self.rulesCollectionsDict[key];
//            [collection reloadData];
//        }
    }
}
-(NSDictionary*) cachedRulesDictionary {
    if (!_cachedRulesDictionary) {
        _cachedRulesDictionary = self.fractal.drawingRulesType.rulesDictionary;
    }
    return _cachedRulesDictionary;
}
-(NSArray*) fractalTableData {
    if (_fractal && (!_fractalTableData || self.fractalDataChanged)) {
        self.fractalDataChanged = NO;
        if (!_fractalTableData) {
            _fractalTableData = [[NSMutableArray alloc] initWithCapacity: 4];
        }
        
        [_fractalTableData removeAllObjects];
        
        MBAxiomEditorTableSection* desc = [MBAxiomEditorTableSection newWithTitle: @"Description"];
        desc.data = @[self.fractal.name, self.fractal.category, self.fractal.descriptor];
        
        MBAxiomEditorTableSection* start = [MBAxiomEditorTableSection newWithTitle: @"Starting Rule"];
        start.data = [self.fractal.drawingRulesType rulesArrayFromRuleString: _fractal.axiom];
        
        MBAxiomEditorTableSection* replace = [MBAxiomEditorTableSection newWithTitle:  @"Replacement Rules"];
        NSMutableArray* repRuleObjects = [NSMutableArray new];
        NSOrderedSet* repRules = self.fractal.replacementRules;
        for (LSReplacementRule* repRule in repRules) {
            NSArray* repRuleObject = @[self.cachedRulesDictionary[repRule.contextString],[self.fractal.drawingRulesType rulesArrayFromRuleString: repRule.replacementString]];
            [repRuleObjects addObject: repRuleObject];
        }
        replace.data = [repRuleObjects copy];
        replace.shouldIndentWhileEditing = YES;
        
        MBAxiomEditorTableSection* rules = [MBAxiomEditorTableSection newWithTitle: @"Available Rules"];
        rules.data = @[[self.fractal.drawingRulesType.rules array]];
        
    
        [_fractalTableData addObjectsFromArray: @[desc,start,replace,rules]];
    }
    return _fractalTableData;
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
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44;
    

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
//    self.fractalAxiom.inputView = self.fractalInputControl.view;

    [self setEditing: YES animated: NO];
}
-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // removes all fractal observers.
//    [self setSortedReplacementRulesArray: nil];
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
    [self.tableView setEditing:editing animated:YES];
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



#pragma mark - table delegate & source
- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    MBAxiomEditorTableSection* tableSection = (self.fractalTableData)[indexPath.section];
    return tableSection.shouldIndentWhileEditing;
}
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    MBAxiomEditorTableSection* tableSection = (self.fractalTableData)[section];
    NSString* sectionHeader = tableSection.title;

    if (section == 3) {
        // section == "Available Rules"
        NSString* newHeader = [NSString stringWithFormat: @"%@ - press and hold to drag rule ^",sectionHeader];
        sectionHeader = newHeader;
    }

    UITableViewCell *sectionView = [tableView dequeueReusableCellWithIdentifier: @"HeaderCell"];
    sectionView.textLabel.text = sectionHeader;

    return sectionView;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    MBAxiomEditorTableSection* tableSection = (self.fractalTableData)[indexPath.section];

    //Set default value
    UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;

    if (indexPath.section == TableSectionsReplacement) {
        // Rules
        if (indexPath.row == ([tableSection.data count] -1)) {
            editingStyle = UITableViewCellEditingStyleInsert;
        } else {
            editingStyle = UITableViewCellEditingStyleDelete;
        }
    }
    return editingStyle;
}
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Accessory view");
}
- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Edditing row %@", indexPath);
}

#pragma message "TODO: fix collectionView layout to be flexible height"
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    CGFloat estimatedRowHeight = tableView.estimatedRowHeight;
//    if (indexPath.section == TableSectionsAxiom) {
//        // description cell
//        estimatedRowHeight = 1*30.0;
//    } else if (indexPath.section == TableSectionsReplacement) {
//        estimatedRowHeight = 30.0;
//    } else if (indexPath.section == TableSectionRules) {
//        // description cell
//        estimatedRowHeight = 4.0*46.0;
//    }
//    return estimatedRowHeight;
//}
// Override to support editing the table view.
#pragma mark - Rule Cell Delegate
//-(void)ruleCellTextRightEditingEnded:(id)sender {
//    if ([sender isKindOfClass: [MBLSRuleTableViewCell class]]) {
//        MBLSRuleTableViewCell* ruleCell = (MBLSRuleTableViewCell*) sender;
//        
//        NSString* ruleKey = ruleCell.textLeft.text;
//        NSArray* rules = self.sortedReplacementRulesArray;
//        
//        // Find the relevant rule for this cell using the key
//        // could do the following using a query
//#pragma message "TDOD replace with self.rulesDictionary?"
//        for (LSReplacementRule* rule in rules) {
//            if ([rule.contextString isEqualToString: ruleKey]) {
//                rule.replacementString = ruleCell.textRight.text;
//            }
//        }
//        [self saveContext];
//    }
//}

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
#pragma mark - UICollectionViewDelegate
-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
-(BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
#pragma mark - Actions
- (IBAction)nameInputDidEnd:(UITextField*)sender {
    self.fractal.name = sender.text;
    [self saveContext];
}
-(IBAction)nameInputChanged:(UITextField*)sender {
    self.fractal.name = sender.text;
}
-(IBAction)categoryInputChanged:(UITextField*)sender {
    self.fractal.category = sender.text;
}
-(IBAction)categoryInputDidEnd:(UITextField*)sender {
    self.fractal.category = sender.text;
    [self saveContext];
}
-(IBAction)axiomInputChanged:(UITextField*)sender {
    self.fractal.axiom = sender.text;
    [self saveContext];
}
-(IBAction)axiomInputEnded:(UITextField*)sender {
    // update rule editing table?
}

- (IBAction)ruleLongPress:(UILongPressGestureRecognizer *)sender {
    CGPoint fingerOffset = CGPointMake(-10.0, -40.0);
    CGPoint rawLoc = [sender locationInView: self.tableView];
    CGRect tableBounds = self.tableView.bounds;
    CGPoint loc = CGPointZero;
    if (CGRectContainsPoint(tableBounds, rawLoc)) {
        loc = rawLoc;
    } else {
        CGFloat limitedX;
        CGFloat limitedY;
        limitedX = rawLoc.x < CGRectGetMinX(tableBounds) ? CGRectGetMinX(tableBounds) : rawLoc.x;
        limitedX = rawLoc.x > CGRectGetMaxX(tableBounds) ? CGRectGetMaxX(tableBounds) : limitedX;
        limitedY = rawLoc.y < CGRectGetMinY(tableBounds) ? CGRectGetMinY(tableBounds) : rawLoc.y;
        limitedY = rawLoc.y > CGRectGetMaxY(tableBounds) ? CGRectGetMaxY(tableBounds) : limitedY;
        loc = CGPointMake(limitedX, limitedY);
    }
    loc = CGPointMake(loc.x + fingerOffset.x, loc.y + fingerOffset.y);
    
    NSIndexPath* startIndex = [self.tableView indexPathForRowAtPoint: loc];
    NSInteger section = startIndex.section;
    NSInteger row = startIndex.row;
    
    CGPoint offset = self.tableView.contentOffset;

    CGFloat tableViewHeight = self.tableView.bounds.size.height;
    
    if (loc.y < (offset.y + 44.0) && (offset.y > 0)) {
        CGPoint newOffset = CGPointMake(0.0, loc.y - 44.0);
        [self.tableView setContentOffset: newOffset animated: NO];
    } else if (loc.y > (offset.y+tableViewHeight - 44.0) && (offset.y + tableViewHeight  < self.tableView.contentSize.height)){
        CGPoint newOffset = CGPointMake(0.0, loc.y - tableViewHeight + 44.0);
        [self.tableView setContentOffset: newOffset animated: NO];
    }
    NSArray* visibleData = [self.tableView indexPathsForVisibleRows];
    if (section == 3) {
        //
    }
    
    UIGestureRecognizerState gestureState = sender.state;
    if (gestureState == UIGestureRecognizerStateBegan) {
        //
        self.draggingRule = [MBDraggingRule newWithRule: nil size: 30];
        [self.tableView addSubview: self.draggingRule.view];
        self.draggingRule.view.center = loc;
        
    } else if (gestureState == UIGestureRecognizerStateChanged) {
        if (self.draggingRule) {
            self.draggingRule.view.center = loc;
        }
    }else if (gestureState == UIGestureRecognizerStateEnded) {
        [self.draggingRule.view removeFromSuperview];
        self.draggingRule = nil;
        
    } else if (gestureState == UIGestureRecognizerStateCancelled) {
        [self.draggingRule.view removeFromSuperview];
        self.draggingRule = nil;
    }
}
-(IBAction)descriptorInputChanged:(UITextView*)sender {
    self.fractal.descriptor = sender.text;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.fractal.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } else {
            self.fractalDataChanged = YES;
        }
    }
}

#pragma mark - TextView Delegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    return YES;
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

@end
