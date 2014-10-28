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
        self.fractalTableSource.fractal = _fractal;
        self.fractalTableSource.tableSections = self.fractalTableSections;
        
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
        
            MBAxiomEditorTableSection* desc = [MBAxiomEditorTableSection newWithTitle: @"Description"];
            
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



#pragma mark - table delegate
- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    MBAxiomEditorTableSection* tableSection = (self.fractalTableSections)[indexPath.section];
    return tableSection.shouldIndentWhileEditing;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    MBAxiomEditorTableSection* tableSection = (self.fractalTableSections)[indexPath.section];
    
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
//-(IBAction)descriptorInputChanged:(UITextView*)sender {
//    self.fractal.descriptor = sender.text;
//}
//-(IBAction)axiomInputChanged:(UITextField*)sender {
//    self.fractal.axiom = sender.text;
//    [self saveContext];
//}
//-(IBAction)axiomInputEnded:(UITextField*)sender {
//    // update rule editing table?
//}
/*!
 Each longGesture recognizer is associated with a particular source of rules.
 This avoids needing to detect the initial location of the touch and simplifies the code.
 
 The following is in spacial order of the table fields.
 @param sender UILongPressGestureRecognizer
 */
//- (IBAction)replacementRuleLongPress:(UILongPressGestureRecognizer *)sender {
//    CGPoint fingerOffset = CGPointMake(-10.0, -40.0);
//    CGPoint rawLoc = [sender locationInView: self.tableView];
//    NSIndexPath* tableRawIndex = [self.tableView indexPathForRowAtPoint: rawLoc];
//    NSInteger tableRawSection = tableRawIndex.section;
//    NSInteger tableRawRow = tableRawIndex.row;
//
//    CGRect tableBounds = self.tableView.bounds;
//    CGPoint loc = CGPointZero;
//    if (CGRectContainsPoint(tableBounds, rawLoc)) {
//        loc = rawLoc;
//    } else {
//        CGFloat limitedX;
//        CGFloat limitedY;
//        limitedX = rawLoc.x < CGRectGetMinX(tableBounds) ? CGRectGetMinX(tableBounds) : rawLoc.x;
//        limitedX = rawLoc.x > CGRectGetMaxX(tableBounds) ? CGRectGetMaxX(tableBounds) : limitedX;
//        limitedY = rawLoc.y < CGRectGetMinY(tableBounds) ? CGRectGetMinY(tableBounds) : rawLoc.y;
//        limitedY = rawLoc.y > CGRectGetMaxY(tableBounds) ? CGRectGetMaxY(tableBounds) : limitedY;
//        loc = CGPointMake(limitedX, limitedY);
//    }
//    loc = CGPointMake(loc.x + fingerOffset.x, loc.y + fingerOffset.y);
//
//    NSIndexPath* tableInsertionIndex = [self.tableView indexPathForRowAtPoint: loc];
//    NSInteger tableInsertionSection = tableInsertionIndex.section;
//    NSInteger tableInsertionRow = tableInsertionIndex.row;
//
//    CGPoint offset = self.tableView.contentOffset;
//
//    CGFloat tableViewHeight = self.tableView.bounds.size.height;
//
//    if (loc.y < (offset.y + 44.0) && (offset.y > 0)) {
//        CGPoint newOffset = CGPointMake(0.0, loc.y - 44.0);
//        [self.tableView setContentOffset: newOffset animated: NO];
//    } else if (loc.y > (offset.y+tableViewHeight - 44.0) && (offset.y + tableViewHeight  < self.tableView.contentSize.height)){
//        CGPoint newOffset = CGPointMake(0.0, loc.y - tableViewHeight + 44.0);
//        [self.tableView setContentOffset: newOffset animated: NO];
//    }
//
//    UIGestureRecognizerState gestureState = sender.state;
//    if (gestureState == UIGestureRecognizerStateBegan) {
//        //
//        MBAxiomEditorTableSection* tableSection = self.fractalTableData[tableRawSection];
//        if (tableRawSection == TableSectionsRules) {
//            // We are starting the drag in the rules collection
//            // Get the rules collection index
//            UICollectionView* sourceCollection = self.fractalTableSource.rulesCollectionView;
//            CGPoint collectionLoc = [self.tableView convertPoint: rawLoc toView: sourceCollection];
//            NSIndexPath* rulesCollectionIndex = [sourceCollection indexPathForItemAtPoint: collectionLoc];
//            NSInteger rulesSection = rulesCollectionIndex.section;
//            NSInteger rulesRow = rulesCollectionIndex.row;
//            LSDrawingRule* draggedRule = tableSection.data[rulesSection][rulesRow];
//            self.draggingRule = [MBDraggingRule newWithRule: draggedRule size: 30];
//            [self.tableView addSubview: self.draggingRule.view];
//            self.draggingRule.view.center = loc;
//        }
//        if (tableRawSection == TableSectionsReplacement) {
//            // We are starting the drag in the rules collection
//            // Get the rules collection index
//#pragma message "TODO need to test for cell drag source leftImage or rightCollection"
//            NSPointerArray* collections = self.fractalTableSource.replacementCollections;
//            UICollectionView* sourceCollection = [collections pointerAtIndex: tableRawRow];
//
//            CGPoint collectionLoc = [self.tableView convertPoint: rawLoc toView: sourceCollection];
//            NSIndexPath* rulesCollectionIndex = [sourceCollection indexPathForItemAtPoint: collectionLoc];
//            NSInteger rulesSection = rulesCollectionIndex.section;
//            NSInteger rulesRow = rulesCollectionIndex.row;
//            // 1 below selects rightCollection
//            LSDrawingRule* draggedRule = tableSection.data[tableRawRow][1][rulesRow];
//            self.draggingRule = [MBDraggingRule newWithRule: draggedRule size: 30];
//            [self.tableView addSubview: self.draggingRule.view];
//            self.draggingRule.view.center = loc;
//        }
//
//    } else if (gestureState == UIGestureRecognizerStateChanged) {
//        if (self.draggingRule) {
//            self.draggingRule.view.center = loc;
//            if (tableInsertionSection == TableSectionsReplacement) {
//                //
//
//                if (tableInsertionRow == 0) {
//                    // Replacment placeholder image
//
//                }
//                if (tableInsertionRow == 1) {
//                    // Replaement rules collection
//
////                    UICollectionView* replacementRulesCollection = self.fractalTableSource.replacementCollections[
////                    NSIndexPath* insertionIndexPath = [replacementRulesCollection indexPathForItemAtPoint: loc];
////                    NSInteger section = insertionIndexPath.section;
////                    NSInteger row = insertionIndexPath.row;
//                }
//            }
//
//        }
//    }else if (gestureState == UIGestureRecognizerStateEnded) {
//        [self.draggingRule.view removeFromSuperview];
//        self.draggingRule = nil;
//
//    } else if (gestureState == UIGestureRecognizerStateCancelled) {
//        [self.draggingRule.view removeFromSuperview];
//        self.draggingRule = nil;
//    }
//}
/*!
 All of the drag and drop handling is based on the fact that the rule assigned to the draggingRule should be unique.
 If the source is the rules collection which are read/only, then the rule is mutableCopied before assignment. The copy
 is unique to the draggingRule. If the draggingRule copy is dropped in a collection, then it is also unique in that collection
 and can be easily found in the set. This means we don't need to keep track of indexes just the source collection (if not the rules
 collection) for moves and deletes.
  */
-(void) handleRulesSourceGestureBeganWithLocation: (CGPoint) touchPoint andIndexPath: (NSIndexPath*) indexPath {
    MBLSRuleCollectionTableViewCell* tableSourceCell = (MBLSRuleCollectionTableViewCell*)[self.tableView cellForRowAtIndexPath: indexPath];
    UICollectionView* sourceCollection = tableSourceCell.collectionView;
    CGPoint collectionLoc = [self.tableView convertPoint: touchPoint toView: sourceCollection];
    NSIndexPath* ruleIndexPath = [sourceCollection indexPathForItemAtPoint: collectionLoc];
    MBLSRuleCollectionViewCell* collectionSourceCell = (MBLSRuleCollectionViewCell*)[sourceCollection cellForItemAtIndexPath: ruleIndexPath];
    
    if (collectionSourceCell) {
        self.draggingRule.rule = [collectionSourceCell.rule mutableCopy]; // only use a copy if getting from source which is case for now
        self.draggingRule.sourceTableIndexPath = indexPath;
        self.draggingRule.sourceCollection = sourceCollection;
        self.draggingRule.sourceCollectionIndexPath = ruleIndexPath;
        
        [self.tableView addSubview: self.draggingRule.view];
    }
 }
-(void) handleRulesSourceGestureChangedWithCollection: (UICollectionView*) collectionView data: (NSMutableOrderedSet*)newDestinationArray {
    
    self.draggingRule.lastDestinationCollection = collectionView;
    
    NSInteger lastCellRow = [self.draggingRule.lastDestinationCollection numberOfItemsInSection: 0] - 1;
    
    CGPoint collectionPoint = [self.tableView convertPoint: self.draggingRule.viewCenter toView: self.draggingRule.lastDestinationCollection];
    NSIndexPath* rulesCollectionIndexPath = [self.draggingRule.lastDestinationCollection indexPathForDropInSection: 0 atPoint: collectionPoint];
    
    if (rulesCollectionIndexPath == nil) {
        // in table cell but not in collection therefore remove from collection is there
        NSString* propertyKey = self.fractalSectionKeyChangedMap[self.draggingRule.lastTableIndexPath.section];
        [self.draggingRule removePreviousDropRepresentationNotify: self.fractal forPropertyChange: propertyKey];
        return;
    }
    
    
    if (self.draggingRule.isAlreadyDropped && lastCellRow < rulesCollectionIndexPath.row) {
        // indexPathForDropInSection: does not know if a rule was already dropped so we need to adjust row by -1.
        rulesCollectionIndexPath = [NSIndexPath indexPathForItem: rulesCollectionIndexPath.row-1 inSection: rulesCollectionIndexPath.section];
    }
    
    BOOL isDifferentLocation = (self.draggingRule.lastCollectionIndexPath == nil || [rulesCollectionIndexPath compare: self.draggingRule.lastCollectionIndexPath] != NSOrderedSame);
    
    if (isDifferentLocation) { // we are in a collection space, currentTableCell should have taken care of this check as well.
                               // only update if the index has changed
        
        NSString* propertyKey = self.fractalSectionKeyChangedMap[self.draggingRule.lastTableIndexPath.section];
        BOOL resized = [self.draggingRule moveRuleToArray: newDestinationArray indexPath: rulesCollectionIndexPath notify: self.fractal forPropertyChange: propertyKey];
        if (resized) {
            [self.tableView reloadRowsAtIndexPaths: @[self.draggingRule.lastTableIndexPath] withRowAnimation: UITableViewRowAnimationAutomatic];
        }
        
    }

}
/*!
 Add the real rule to the fractal data and update the relevant table views.
 */
-(void) handleRulesSourceGestureEndedWithIndexPath {
    
    if (self.draggingRule.lastTableIndexPath.section == TableSectionsReplacement || self.draggingRule.lastTableIndexPath.section == TableSectionsAxiom) {
        
        [self saveContext];
        
    }
    // done with draggingRule
    [self.draggingRule.view removeFromSuperview];
    self.draggingRule = nil;
}
-(void) handleRulesSourceGestureCancelled {
    NSString* propertyKey = self.fractalSectionKeyChangedMap[self.draggingRule.lastTableIndexPath.section];
    [self.draggingRule removePreviousDropRepresentationNotify: self.fractal forPropertyChange: propertyKey];
    [self.draggingRule.view removeFromSuperview];
    self.draggingRule = nil;
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
-(void) axiomRuleDropInTableIndexPath: (NSIndexPath*)tableIndexPath {
    NSMutableOrderedSet* rulesSet;
    
    UITableViewCell* currentTableCell = [self.tableView cellForRowAtIndexPath: tableIndexPath];

    rulesSet = self.fractalSectionDataMap[TableSectionsAxiom];
    
    if ([currentTableCell isKindOfClass:[MBLSRuleCollectionTableViewCell class]]) {
        // just a collection view (axiom or rule source) only axiom matters
        
        MBLSRuleCollectionTableViewCell* collectionCell = (MBLSRuleCollectionTableViewCell*)currentTableCell;
        // get data and collection and send to method
        [self handleRulesSourceGestureChangedWithCollection: collectionCell.collectionView data: rulesSet];
        
    }
}
-(void) replacementRuleDropInTableIndexPath: (NSIndexPath*)tableIndexPath  {
    NSMutableOrderedSet* rulesSet;
    
    LSReplacementRule* replacementRule = self.fractalSectionDataMap[tableIndexPath.section][tableIndexPath.row];
    rulesSet = [replacementRule mutableOrderedSetValueForKey: @"rules"];
    
    UITableViewCell* currentTableCell = [self.tableView cellForRowAtIndexPath: tableIndexPath];
    
    if ([currentTableCell isKindOfClass:[MBLSReplacementRuleTableViewCell class]]) {
        // replacement cell with image and collection
        // dragging over image or collection?
        MBLSReplacementRuleTableViewCell* replacementTableCell = (MBLSReplacementRuleTableViewCell*)currentTableCell;
        
        CGRect collectionRect = [self.tableView convertRect: replacementTableCell.collectionView.bounds fromView: replacementTableCell.collectionView];
        CGRect placeholderImageRect = [self.tableView convertRect: replacementTableCell.customImageView.bounds fromView: replacementTableCell.customImageView];
        
        if (CGRectContainsPoint(collectionRect, self.draggingRule.viewCenter)) {
            // over collection
            // get data and collection and send to method
            
            [self handleRulesSourceGestureChangedWithCollection: replacementTableCell.collectionView data: rulesSet];
            
        } else if (CGRectContainsPoint(placeholderImageRect, self.draggingRule.viewCenter)) {
            // over rule placeholder imageView
            NSString* propertyKey = self.fractalSectionKeyChangedMap[self.draggingRule.lastTableIndexPath.section];
            [self.fractal willChangeValueForKey: propertyKey];
            replacementRule.contextRule = self.draggingRule.rule;
            [self.fractal didChangeValueForKey: propertyKey];
            [self.tableView reloadRowsAtIndexPaths: @[self.draggingRule.lastTableIndexPath] withRowAnimation: UITableViewRowAnimationAutomatic];
#pragma message "TODO handle customImageView drop"
        } else {
            // in the cell but not in either subView
            NSString* propertyKey = self.fractalSectionKeyChangedMap[self.draggingRule.lastTableIndexPath.section];
            [self.draggingRule removePreviousDropRepresentationNotify: self.fractal forPropertyChange: propertyKey];
        }
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
