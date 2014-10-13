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
@property (nonatomic,strong) NSMutableArray                     *lastDragDestinationArray;
@property (nonatomic,strong) UICollectionView                   *lastDragDestinationCollection;
@property (nonatomic,strong) NSIndexPath                        *lastTableDragIndexPath;
@property (nonatomic,strong) NSIndexPath                        *lastCollectionDragIndexPath;

-(void) addReplacementRulesObserverFor: (LSFractal*)fractal;
-(void) removeReplacementRulesObserverFor: (LSFractal*)fractal;

@end

#pragma mark - Implementation
@implementation MBFractalAxiomEditViewController
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString: @"replacementRules"]) {
//        self.sortedReplacementRulesArray = nil;
        self.fractalDataChanged = YES;

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
        
        self.fractalDataChanged = YES;
        self.cachedRulesDictionary = nil;
        if (_fractal) {
            self.fractalTableSource.fractalData = self.fractalTableData;
            
            [self.tableView reloadData];
            
        } else {
            self.fractalTableSource.fractalData = nil;
        }
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
        if (_fractal) {
            if (!_fractalTableData) {
                _fractalTableData = [[NSMutableArray alloc] initWithCapacity: 4];
            }
            
            [_fractalTableData removeAllObjects];
            
            MBAxiomEditorTableSection* desc = [MBAxiomEditorTableSection newWithTitle: @"Description"];
            desc.data =  [NSMutableArray arrayWithObjects: self.fractal.name, self.fractal.category, self.fractal.descriptor, nil];
            
            MBAxiomEditorTableSection* start = [MBAxiomEditorTableSection newWithTitle: @"Starting Rule"];
            start.data = [NSMutableArray arrayWithObject: [[self.fractal.drawingRulesType rulesArrayFromRuleString: _fractal.axiom] mutableCopy]];
            
            MBAxiomEditorTableSection* replace = [MBAxiomEditorTableSection newWithTitle:  @"Replacement Rules"];
            NSMutableArray* repRuleObjects = [NSMutableArray new];
            NSOrderedSet* repRules = self.fractal.replacementRules;
            for (LSReplacementRule* repRule in repRules) {
                NSMutableArray* repRuleObject = [NSMutableArray arrayWithObjects: self.cachedRulesDictionary[repRule.contextString],
                                                 [[self.fractal.drawingRulesType rulesArrayFromRuleString: repRule.replacementString]mutableCopy], nil];
                [repRuleObjects addObject: repRuleObject];
            }
            replace.data = [repRuleObjects copy];
            replace.shouldIndentWhileEditing = YES;
            
            MBAxiomEditorTableSection* rules = [MBAxiomEditorTableSection newWithTitle: @"Available Rules - press and hold to drag rule ^"];
            rules.data = [NSMutableArray arrayWithObject: [self.fractal.drawingRulesType.rules array]];
            
            [_fractalTableData addObjectsFromArray: @[desc,start,replace,rules]];
        } else {
            [_fractalTableData removeAllObjects];
            _fractalTableData = nil;
        }
    }
    return _fractalTableData;
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
//- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    MBAxiomEditorTableSection* tableSection = (self.fractalTableData)[section];
//    NSString* sectionHeader = tableSection.title;
//
//    if (section == 3) {
//        // section == "Available Rules"
//        NSString* newHeader = [NSString stringWithFormat: @"%@ - press and hold to drag rule ^",sectionHeader];
//        sectionHeader = newHeader;
//    }
//
//    UITableViewCell *sectionView = [tableView dequeueReusableCellWithIdentifier: @"HeaderCell"];
//    sectionView.textLabel.text = sectionHeader;
//
//    return sectionView;
//}
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
- (IBAction)axiomRuleLongPress:(id)sender {
}
- (IBAction)placeholderLongPress:(id)sender {
}
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

- (IBAction)rulesSourceLongPress:(UILongPressGestureRecognizer *)sender {
    BOOL addedRow = NO;

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
    
    NSIndexPath* tableInsertionIndex = [self.tableView indexPathForRowAtPoint: loc];
    NSInteger tableInsertionSection = tableInsertionIndex.section;
    NSInteger tableInsertionRow = tableInsertionIndex.row;
    
    CGPoint offset = self.tableView.contentOffset;
    
    CGFloat tableViewHeight = self.tableView.bounds.size.height;
    
    if (loc.y < (offset.y + 44.0) && (offset.y > 0)) {
        CGPoint newOffset = CGPointMake(0.0, loc.y - 44.0);
        [self.tableView setContentOffset: newOffset animated: NO];
    } else if (loc.y > (offset.y+tableViewHeight - 44.0) && (offset.y + tableViewHeight  < self.tableView.contentSize.height)){
        CGPoint newOffset = CGPointMake(0.0, loc.y - tableViewHeight + 44.0);
        [self.tableView setContentOffset: newOffset animated: NO];
    }
    
    UIGestureRecognizerState gestureState = sender.state;
    if (gestureState == UIGestureRecognizerStateBegan) {
        //
        MBLSRuleCollectionTableViewCell* currentCell = (MBLSRuleCollectionTableViewCell*)[self.tableView cellForRowAtIndexPath: tableInsertionIndex];
        UICollectionView* sourceCollection = currentCell.collectionView;
        CGPoint collectionLoc = [self.tableView convertPoint: rawLoc toView: sourceCollection];
        NSIndexPath* rulesCollectionIndex = [sourceCollection indexPathForItemAtPoint: collectionLoc];
        NSInteger rulesSection = rulesCollectionIndex.section;
        NSInteger rulesRow = rulesCollectionIndex.row;

        MBAxiomEditorTableSection* tableSection = self.fractalTableData[TableSectionsRules];
        // We are starting the drag in the rules collection
        // Get the rules collection index
        LSDrawingRule* draggedRule = tableSection.data[rulesSection][rulesRow];
        self.draggingRule = [MBDraggingRule newWithRule: draggedRule size: 30];
        [self.tableView addSubview: self.draggingRule.view];
        self.draggingRule.view.center = loc;
        
        self.lastTableDragIndexPath = nil;
        self.lastDragDestinationArray = nil;
        self.lastDragDestinationCollection = nil;
        
    } else if (gestureState == UIGestureRecognizerStateChanged) {
        if (self.draggingRule) {
            if (self.lastTableDragIndexPath && ([self.lastTableDragIndexPath compare: tableInsertionIndex]!=NSOrderedSame)) {
                // if index is not the same, drag has moved out of the last one so remove dragging cell.
                if (self.lastDragDestinationArray && self.draggingRule) {
                    [self.lastDragDestinationArray removeObject: self.draggingRule];
                    [self.lastDragDestinationCollection deleteItemsAtIndexPaths: @[self.lastCollectionDragIndexPath]];
                    self.lastTableDragIndexPath = nil;
                    self.lastCollectionDragIndexPath = nil;
                    self.lastDragDestinationArray = nil;
//                    [self.lastDragDestinationCollection reloadData];
                    self.lastDragDestinationCollection = nil;
                }
            }
            self.draggingRule.view.center = loc;
            if (tableInsertionSection == TableSectionsReplacement) {
                //
                MBAxiomEditorTableSection* tableReplacementSection = self.fractalTableData[TableSectionsReplacement];
                NSMutableArray* replacementRulesArray = tableReplacementSection.data[tableInsertionRow][1];
                
#pragma message "TODO use [self.tableView cellForRowAtIndexPath: tableInsertionIndex] then get the collection and image from the cell"
#pragma message "TODO need to check space at end of last cell for appends. create a rect cell height and from last cell to end of view and check if loc is in rect."
                MBLSReplacementRuleTableViewCell* currentCell = (MBLSReplacementRuleTableViewCell*)[self.tableView cellForRowAtIndexPath: tableInsertionIndex];
                UICollectionView* sourceCollection = currentCell.collectionView;
                CGPoint collectionLoc = [self.tableView convertPoint: loc toView: sourceCollection];
                NSIndexPath* rulesCollectionIndexPath = [sourceCollection indexPathForItemAtPoint: collectionLoc];

                NSInteger lastCellRow = [sourceCollection numberOfItemsInSection: 0] - 1;

                if (!rulesCollectionIndexPath) {
                    // not over a cell need to check if we are at the end of the collection
                    CGRect collectionBounds = sourceCollection.bounds;
                    if (CGRectContainsPoint(collectionBounds, collectionLoc)) {
                        // in collection view
                        
                        NSIndexPath* lastItemIndexPath = [NSIndexPath indexPathForRow: lastCellRow inSection: 0];
                        NSIndexPath* lastItemPlusOneIndexPath = [NSIndexPath indexPathForRow: lastCellRow+1 inSection: 0];
                        
                        UICollectionViewLayoutAttributes* lastItemAttrs = [sourceCollection layoutAttributesForItemAtIndexPath: lastItemIndexPath];
                        CGRect lastItemFrame = lastItemAttrs.frame;
                        CGFloat cellRightX = lastItemFrame.origin.x + lastItemFrame.size.width;
                        CGFloat cellTopY = lastItemFrame.origin.y;
                        CGFloat collRightX = collectionBounds.origin.x + collectionBounds.size.width;
                        CGFloat collBottomY = collectionBounds.origin.y + collectionBounds.size.height;
                        CGRect lastSpaceRect = CGRectMake(cellRightX, cellTopY, collRightX-cellRightX, collBottomY-cellTopY);
                        if (CGRectContainsPoint(lastSpaceRect, collectionLoc)) {
                            // in space at end to append rather than insert
                            // need to check if last item is a previous draggingRule append
                            LSDrawingRule* lastRule = replacementRulesArray[lastCellRow];
                            if (![lastRule isKindOfClass:[MBDraggingRule class]]) {
                                // not draggingClass so free to append
                                if (self.lastCollectionDragIndexPath) {
                                    [replacementRulesArray removeObject: self.draggingRule];
                                    [replacementRulesArray addObject: self.draggingRule];
                                    [sourceCollection moveItemAtIndexPath: self.lastCollectionDragIndexPath toIndexPath: lastItemIndexPath];
                                    self.lastCollectionDragIndexPath = lastItemIndexPath;
                                } else {
                                    [replacementRulesArray addObject: self.draggingRule];
                                    [sourceCollection insertItemsAtIndexPaths: @[lastItemPlusOneIndexPath]];
                                    self.lastCollectionDragIndexPath = lastItemPlusOneIndexPath;
                                    // resize collectionView if count goes from mod 9 -> 10
                                    CGFloat remainder = fmodf(lastCellRow+1, 9.0);
                                    if (remainder == 0.0) {
                                        addedRow = YES;
                                    }
                                }
                                self.lastDragDestinationArray = replacementRulesArray;
                                self.lastDragDestinationCollection = sourceCollection;
                                self.lastTableDragIndexPath = tableInsertionIndex;
                            }
                        }
                    }
                } else if (rulesCollectionIndexPath) {
                    // over a cell in the collection
                    NSInteger rulesSection = rulesCollectionIndexPath.section;
                    NSInteger rulesRow = rulesCollectionIndexPath.row;
                    LSDrawingRule* ruleUnderGesture = replacementRulesArray[rulesRow];
                    if (![ruleUnderGesture isKindOfClass: [MBDraggingRule class]]) {
                        [replacementRulesArray removeObject: self.draggingRule];
                        if (self.lastCollectionDragIndexPath) {
                            [replacementRulesArray removeObject: self.draggingRule];
                            [replacementRulesArray insertObject: self.draggingRule atIndex: rulesRow];
                            [sourceCollection moveItemAtIndexPath: self.lastCollectionDragIndexPath toIndexPath: rulesCollectionIndexPath];
                        } else {
                            [replacementRulesArray insertObject: self.draggingRule atIndex: rulesRow];
                            [sourceCollection insertItemsAtIndexPaths: @[rulesCollectionIndexPath]];
                            // resize collectionView if count goes from mod 9 -> 10
                            CGFloat remainder = fmodf(lastCellRow+1, 9.0);
                            if (remainder == 0.0) {
                                addedRow = YES;
                            }
                        }
                        self.lastCollectionDragIndexPath = rulesCollectionIndexPath;
                        self.lastDragDestinationArray = replacementRulesArray;
                        self.lastDragDestinationCollection = sourceCollection;
                        self.lastTableDragIndexPath = tableInsertionIndex;
                    }
                }
            }
            
        }
    }else if (gestureState == UIGestureRecognizerStateEnded) {
        // look for dragging cell and replace with real rule in fractal data then regen fractalTableData
        if (self.lastTableDragIndexPath.section == TableSectionsReplacement) {
            //
            NSMutableOrderedSet* replacements = [self.fractal mutableOrderedSetValueForKey: @"replacementRules"];
            LSReplacementRule* editedReplacementRule = replacements[self.lastTableDragIndexPath.row];
            LSDrawingRule* insertedRule = self.draggingRule.rule;
            NSInteger insertionRow = self.lastCollectionDragIndexPath.row;
            NSMutableString* oldReplacementString = [editedReplacementRule.replacementString mutableCopy];
            NSString* insertedString = insertedRule.productionString;
            
            if (insertionRow == oldReplacementString.length) {
                // append
                [oldReplacementString appendString: insertedString];
            } else if (insertionRow < oldReplacementString.length) {
                // insert
                [oldReplacementString insertString: insertedString atIndex: insertionRow];
            } else {
                // problem since insertionRow is too large
            }
            editedReplacementRule.replacementString = [oldReplacementString copy];
            [self saveContext];
            
//            NSMutableArray* replacementRulesIndexPaths = [[NSMutableArray alloc] initWithCapacity: replacements.count];
//            for (int i = 0; i < replacements.count; i++) {
//                NSIndexPath* tableRowIndexPath = [NSIndexPath indexPathForRow: i inSection: self.lastTableDragIndexPath.section];
//                [replacementRulesIndexPaths addObject: tableRowIndexPath];
//            }
            // need to force reload of the collections so the dataSource array references are updated.
//            [self.tableView reloadRowsAtIndexPaths: replacementRulesIndexPaths withRowAnimation: UITableViewRowAnimationNone];
            [self.tableView reloadSections: [NSIndexSet indexSetWithIndex: self.lastTableDragIndexPath.section] withRowAnimation: UITableViewRowAnimationNone];
        }
        [self.draggingRule.view removeFromSuperview];
        self.lastCollectionDragIndexPath = nil;
        self.draggingRule = nil;
        self.lastDragDestinationArray = nil;
        self.lastDragDestinationCollection = nil;
        self.lastTableDragIndexPath = nil;
        
    } else if (gestureState == UIGestureRecognizerStateCancelled) {
        [self.draggingRule.view removeFromSuperview];
        self.lastCollectionDragIndexPath = nil;
        self.draggingRule = nil;
        self.lastDragDestinationArray = nil;
        self.lastDragDestinationCollection = nil;
        self.lastTableDragIndexPath = nil;
    }
    if (addedRow) {
//        [self.tableView setNeedsLayout];
//        [self.lastDragDestinationCollection setNeedsLayout];
        [self.tableView reloadRowsAtIndexPaths: @[self.lastTableDragIndexPath] withRowAnimation: UITableViewRowAnimationAutomatic];
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
