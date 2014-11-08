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

#import "MBLSReplacementRuleTableViewCell.h"
#import "MBLSRuleCollectionTableViewCell.h"
#import "MBLSRuleTableViewCell.h"
#import "MBLSRuleCollectionViewCell.h"
#import "MBLSRuleDragAndDropProtocol.h"

#import "MBStyleKitButton.h"
#import "MBDraggingRule.h"
#import "QuartzHelpers.h"

#import <MDUIKit/UICollectionView+MDKDragAndDrop.h>

@interface MBFractalAxiomEditViewController ()

/*!
 for tracking which text input field has the current focus.
 allows using a custom input keyboard.
 Want to change to a popover at some point.
 */
@property (weak, nonatomic) UITextField                         *activeTextField;

@property (nonatomic,strong) NSDictionary                       *cachedRulesDictionary;
@property (nonatomic,weak) IBOutlet MBFractalTableDataSource    *fractalTableSource;
@property (nonatomic,strong) NSArray                            *fractalTableSections;
@property (nonatomic,strong) NSArray                            *fractalSectionDataMap;
@property (nonatomic,strong) NSArray                            *fractalSectionKeyChangedMap;
@property (nonatomic,strong) MBDraggingRule                     *draggingRule;

-(void) addReplacementRulesObserverFor: (LSFractal*)fractal;
-(void) removeReplacementRulesObserverFor: (LSFractal*)fractal;

@end

#pragma mark - Implementation
@implementation MBFractalAxiomEditViewController
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString: @"replacementRules"]) {
        
//        self.fractalDataChanged = YES;
        
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
-(void) setFractal:(LSFractal *)fractal {
    MBFractalTableDataSource* strongFractalTableSource = self.fractalTableSource;
    
    if (_fractal != fractal) {
        _fractal = fractal;
        
        if (_fractal) {
            _fractalSectionKeyChangedMap = @[@"",
                                             @"startingRules",
                                             @"replacementRules",
                                             @""];
            _fractalSectionDataMap = @[@"not used",
                                       [_fractal mutableOrderedSetValueForKey: @"startingRules"],
                                       [_fractal mutableOrderedSetValueForKey: @"replacementRules"],
                                       [_fractal mutableOrderedSetValueForKeyPath: @"drawingRulesType.rules"]];
        }
        
        self.cachedRulesDictionary = nil;
        strongFractalTableSource.fractal = _fractal;
        strongFractalTableSource.tableSections = self.fractalTableSections;
        strongFractalTableSource.pickerDelegate = self;
        strongFractalTableSource.pickerSource = self;
        
        [self.tableView reloadData];
        
    }
}
-(NSDictionary*) cachedRulesDictionary {
    if (!_cachedRulesDictionary) {
        _cachedRulesDictionary = self.fractal.drawingRulesType.rulesDictionary;
    }
    return _cachedRulesDictionary;
}
-(NSArray*) fractalTableSections {
    if (!_fractalTableSections) {
        
        MBAxiomEditorTableSection* desc = [MBAxiomEditorTableSection newWithTitle: @"Name, Description, Category"]; // no title to fit rules //@"Description"
        
            MBAxiomEditorTableSection* start = [MBAxiomEditorTableSection newWithTitle: @"Starting Rule"];
            
            MBAxiomEditorTableSection* replace = [MBAxiomEditorTableSection newWithTitle:  @"Replacement Rules"];
            replace.shouldIndentWhileEditing = YES;
            
            MBAxiomEditorTableSection* rules = [MBAxiomEditorTableSection newWithTitle: @"Available Rules - press and hold to drag rule ^"];
            
            _fractalTableSections = @[desc,start,replace,rules];
    }
    return _fractalTableSections;
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
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

/* on staartup, fractal should not be set until just before view didAppear */
-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setEditing: YES animated: NO];
//    [self.tableView reloadData];
}
-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}
-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
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
- (IBAction)axiomRuleLongPress:(id)sender {
    [self rulesSourceLongPress: sender];
}
- (IBAction)placeholderLongPress:(id)sender {
    [self rulesSourceLongPress: sender];
}
-(IBAction)replacementRuleLongPress:(UILongPressGestureRecognizer *)sender {
    [self rulesSourceLongPress: sender];
}
/*!
 Precess the long press gesture as a drag originating in the rules source collection.
 The rules source is read only and items can be dragged from the source to all the other
 rule locations such as the replacement rules and the axiom.
 
 @param sender users long press
 */
- (IBAction)rulesSourceLongPress:(UILongPressGestureRecognizer *)sender {
    UIGestureRecognizerState gestureState = sender.state;
    BOOL reloadCell = NO;
    
    if (!self.draggingRule) {
        self.draggingRule = [[MBDraggingRule alloc] initWithRule: nil size: 26.0];
        //        self.draggingRule = [[MBDraggingRule alloc] init];
        //        self.draggingRule.size = 30;
        self.draggingRule.touchToDragViewOffset = CGPointMake(0.0, -40.0);
    }
    
    
    CGPoint touchPoint = [sender locationInView: self.tableView];
    
    CGRect tableBounds = self.tableView.bounds;
    CGPoint constrainedPoint = CGPointConfineToRect(touchPoint, tableBounds);
    // Keep dragged view within the table bounds
    self.draggingRule.viewCenter = constrainedPoint;
    
    NSIndexPath* tableInsertionIndexPath;
    
    if (gestureState == UIGestureRecognizerStateBegan) {
        tableInsertionIndexPath = [self.tableView indexPathForRowAtPoint: touchPoint];
    } else {
        tableInsertionIndexPath = [self.tableView indexPathForRowAtPoint: self.draggingRule.viewCenter];
    }
    
    self.draggingRule.currentIndexPath = tableInsertionIndexPath;
    
    // Scroll the table to keep the touchpoint and dragged image in the frame.
    CGFloat scrollTouchInsets = -20.0;
    CGRect dropImageRect = CGRectInset(self.draggingRule.view.frame, scrollTouchInsets, scrollTouchInsets);
    CGRect touchRect = CGRectInset(CGRectMake(touchPoint.x, touchPoint.y, 1, 1), scrollTouchInsets, scrollTouchInsets);
    CGRect scroll = CGRectUnion(dropImageRect, touchRect);
    [self.tableView scrollRectToVisible: scroll animated: YES];
    
    // Get the cell either under the touch or under the drag image depending on current tableIndex.
    UITableViewCell<MBLSRuleDragAndDropProtocol>* currentTableCell = (UITableViewCell<MBLSRuleDragAndDropProtocol>*)[self.tableView cellForRowAtIndexPath: tableInsertionIndexPath];
    
    if (![currentTableCell conformsToProtocol: @protocol(MBLSRuleDragAndDropProtocol) ]) {
        currentTableCell = nil;
    }
    
    if (currentTableCell && gestureState == UIGestureRecognizerStateBegan) {
        //
        CGPoint localSourceViewPoint = [self.tableView convertPoint: touchPoint toView: currentTableCell];
        
        UIView* dragView = [currentTableCell dragDidStartAtLocalPoint: localSourceViewPoint draggingRule: self.draggingRule];
        if (dragView) {
            [self.tableView addSubview: dragView];
            [self.tableView bringSubviewToFront: dragView];
            self.draggingRule.sourceTableIndexPath = tableInsertionIndexPath;
            self.draggingRule.lastTableIndexPath = tableInsertionIndexPath;
        }
        
    } else if (currentTableCell && gestureState == UIGestureRecognizerStateChanged) {
        // Cases
        // Previous cell in other array
        //      remove previous cell
        //      nil previous array
        //
        // Previous cell in current array
        //      new position overcell - move
        //      new position at end - move
        // No previous array
        //      new position overcell - insert
        //      new position at end of cells - append
        /*
         also have a category method which takes above index and does the right thing in terms of insertion or append based on whether index is past end of row. Maybe not neccesary given proper index above?
         */
        if (self.draggingRule == nil) {
            // drag never began.
            return;
        }
        
        CGPoint localDropViewPoint = [self.tableView convertPoint: self.draggingRule.viewCenter toView: currentTableCell];
        BOOL isDifferentLocation = (self.draggingRule.lastTableIndexPath == nil || [tableInsertionIndexPath compare: self.draggingRule.lastTableIndexPath] != NSOrderedSame);
        if (isDifferentLocation) {
            if (self.draggingRule.lastTableIndexPath) {
                UITableViewCell<MBLSRuleDragAndDropProtocol>* lastTableCell = (UITableViewCell<MBLSRuleDragAndDropProtocol>*)[self.tableView cellForRowAtIndexPath: self.draggingRule.lastTableIndexPath];
                if (lastTableCell) {
                    reloadCell = [lastTableCell dragDidExitDraggingRule: self.draggingRule];
                    if (reloadCell) {
                        [lastTableCell setNeedsUpdateConstraints];
                    }
                }
            }
            reloadCell = [currentTableCell dragDidEnterAtLocalPoint: localDropViewPoint draggingRule: self.draggingRule];
        } else {
            reloadCell = [currentTableCell dragDidChangeToLocalPoint: localDropViewPoint draggingRule: self.draggingRule];
        }
        self.draggingRule.lastTableIndexPath = tableInsertionIndexPath;
        
        
    }else if (gestureState == UIGestureRecognizerStateEnded) {
        if (currentTableCell) {
            // look for dragging cell and replace with real rule in fractal data then regen fractalTableData
            reloadCell = [currentTableCell dragDidEndDraggingRule: self.draggingRule];
        }
        [self.draggingRule.view removeFromSuperview];
        self.draggingRule = nil;
        
    } else if (gestureState == UIGestureRecognizerStateCancelled) {
        [self.draggingRule.view removeFromSuperview];
        self.draggingRule = nil;
    }
    
    if (reloadCell) {
        [self.tableView reloadRowsAtIndexPaths: @[tableInsertionIndexPath] withRowAnimation: UITableViewRowAnimationAutomatic];
    }
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
            //            self.fractalDataChanged = YES;
        }
    }
}

#pragma mark - table delegate
- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    MBAxiomEditorTableSection* tableSection = (self.fractalTableSections)[indexPath.section];
    return tableSection.shouldIndentWhileEditing;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Set default value
    UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;
    
    if (indexPath.section == TableSectionsReplacement) {
        // Rules
        if (indexPath.row == ([self.fractal.replacementRules count] -1)) {
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
#pragma message "Change cell background color here, not in awakeFromNib:"
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // move appearance code from tableSOurce to here
    cell.backgroundColor = [UIColor clearColor];

    if (indexPath.section == TableSectionsAxiom) {
        // axiom
        if (((MBLSRuleCollectionTableViewCell *)cell).collectionView.willScrollVertically) {
            [self.tableView reloadRowsAtIndexPaths: @[indexPath] withRowAnimation: UITableViewRowAnimationNone];
        }
        //        newCell.isReadOnly = NO;
        //        newCell.itemSize = 26.0;
        //        newCell.itemMargin = 2.0;
        
    } else if (indexPath.section == TableSectionsReplacement) {
        // rules
        if (((MBLSRuleCollectionTableViewCell *)cell).collectionView.willScrollVertically) {
            [self.tableView reloadRowsAtIndexPaths: @[indexPath] withRowAnimation: UITableViewRowAnimationNone];
        }
        //        newCell.isReadOnly = NO;
        //        newCell.itemSize = 26.0;
        //        newCell.itemMargin = 2.0;
        
    } else if (indexPath.section == TableSectionsRules) {
        // Rule source section
        if (((MBLSRuleCollectionTableViewCell *)cell).collectionView.willScrollVertically) {
            [self.tableView reloadRowsAtIndexPaths: @[indexPath] withRowAnimation: UITableViewRowAnimationNone];
        }
        //        newCell.isReadOnly = YES;
        //        newCell.itemSize = 46.0;
        //        newCell.itemMargin = 2.0;
        //        newCell.rules.count;
        //        CGFloat newHeight = [self calculateCollectionHeightFor: newCell.collectionView itemSize: 46.0 itemMargin: 2.0 itemCount: newCell.rules.count];
        //        newCell.collectionView.currentHeightConstraint.constant = newHeight;
    }
}
//-(CGFloat) calculateCollectionHeightFor: (UICollectionView*) cell itemSize: (CGFloat)itemSize itemMargin: (CGFloat) itemMargin itemCount: (NSInteger)count {
//    CGFloat width = self.tableView.bounds.size.width;
//    CGFloat cellWidth = cell.bounds.size.width;
//    CGFloat itemWidth = itemMargin+itemSize;
//    NSInteger lines = 1;
//    if (cellWidth) {
//        CGFloat itemsPerLine = floorf(cellWidth/itemWidth);
//        lines = ceilf(count/itemsPerLine);
//    }
//    CGFloat newHeight = lines * itemWidth;
//    return newHeight;
//}
#pragma mark - Rule Cell Delegate

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
#pragma mark - PickerViewSource
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 2;
}
#pragma mark - TextView Delegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    return YES;
}

#pragma mark - PickerViewDelegate
-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 24.0;
}
-(CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return 120.0;
}
-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSArray* categories = [self.fractal allCategories];
    return categories[row];
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
