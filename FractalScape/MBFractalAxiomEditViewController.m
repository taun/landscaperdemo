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
#import "LSDrawingRuleType+addons.h"
#import "LSDrawingRule+addons.h"

#import "MBFractalPropertyTableHeaderView.h"
#import "MBBasicLabelTextTableCell.h"
#import "MBTextViewTableCell.h"
#import "MBLSRuleCollectionTableViewCell.h"
#import "MBLSRuleCollectionViewCell.h"
#import "MBLSReplacementRuleTableViewCell.h"

#import "MBRuleSourceCollectionDataSource.h"

#import "MBStyleKitButton.h"


typedef NS_ENUM(NSUInteger, enumTableSections) {
    TableSectionsDescription,
    TableSectionsRule,
    TableSectionsReplacement,
    TableSectionRules
};

@interface MBFractalAxiomEditViewController ()

/*!
 for tracking which text input field has the current focus.
 allows using a custom input keyboard.
 Want to change to a popover at some point.
 */
@property (weak, nonatomic) UITextField             *activeTextField;
@property (nonatomic, readwrite) NSArray            *sortedReplacementRulesArray;

@property (nonatomic,strong) NSArray                *tableSections;

@property (nonatomic,strong) NSDictionary                       *rulesDictionary;
@property (nonatomic,strong) NSMutableDictionary                *rulesCollectionsDict;
@property (nonatomic,strong) MBRuleSourceCollectionDataSource   *rulesDataSource;
@property (nonatomic,strong) MBRuleSourceCollectionDataSource   *axiomDataSource;
@property (nonatomic,strong) NSMutableDictionary                *replacementDataSourcesDict;

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
-(void) setFractal:(LSFractal *)fractal {
    if (_fractal != fractal) {
        _fractal = fractal;
        NSSet* rules = _fractal.drawingRulesType.rules;
        if (rules.count > 0) {
            NSMutableDictionary* rulesDict = [[NSMutableDictionary alloc] initWithCapacity: rules.count];
            for (LSDrawingRule* rule in rules) {
                //
                rulesDict[rule.productionString] = rule;
            }
            self.rulesDictionary = [rulesDict copy];
            NSSortDescriptor* ruleIndexSorting = [NSSortDescriptor sortDescriptorWithKey: @"displayIndex" ascending: YES];
            NSSortDescriptor* ruleAlphaSorting = [NSSortDescriptor sortDescriptorWithKey: @"iconIdentifierString" ascending: YES];
            NSArray* sortedRules = [self.fractal.drawingRulesType.rules sortedArrayUsingDescriptors: @[ruleIndexSorting,ruleAlphaSorting]];
            
            self.rulesDataSource = [MBRuleSourceCollectionDataSource new];
            self.rulesDataSource.rules = sortedRules;
            
            self.axiomDataSource = [MBRuleSourceCollectionDataSource new];
            self.axiomDataSource.rules = [self rulesArrayFromRuleString: self.fractal.axiom];
            
            self.replacementDataSourcesDict = [NSMutableDictionary new];
            [self.rulesCollectionsDict removeAllObjects];
            _rulesCollectionsDict = nil;
        }
        [self.tableView reloadData];
//        for (id key in self.rulesCollectionsDict) {
//            
//            UICollectionView* collection = (UICollectionView*)self.rulesCollectionsDict[key];
//            [collection reloadData];
//        }
    }
}
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
-(NSMutableDictionary*) rulesCollectionsDict {
    if (!_rulesCollectionsDict) {
        _rulesCollectionsDict = [NSMutableDictionary new];
    }
    return _rulesCollectionsDict;
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
    self.tableSections = @[@"Description", @"Starting Rule", @"Replacement Rules", @"Available Rules"];
    
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
    if (section == 3) {
        // section == "Available Rules"
        NSString* newHeader = [NSString stringWithFormat: @"%@ - press and hold to drag rule ^",sectionHeader];
        sectionHeader = newHeader;
    }
    
    UITableViewCell *sectionView = (MBBasicLabelTextTableCell *)[tableView dequeueReusableCellWithIdentifier: @"HeaderCell"];
    sectionView.textLabel.text = sectionHeader;
    
    return sectionView;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 1;
    if (section==TableSectionsDescription) {
        // section == "Description" - name, category, description
        rows = 3;
    } else if (section == TableSectionsRule) {
        // section == "Starting Rule"
        rows = 1;
    } else if (section == TableSectionsReplacement) {
        // section == "Replacement rules"
        rows = [self.sortedReplacementRulesArray count];
    } else if (section == TableSectionRules) {
        // section == "Available Rules"
        rows = 1;
    }
    return rows;
}

-(NSArray*) rulesArrayFromRuleString: (NSString*) ruleString {
    NSInteger sourceLength = ruleString.length;
    
    NSMutableArray* rules = [[NSMutableArray alloc] initWithCapacity: sourceLength];
    
    for (int y=0; y < sourceLength; y++) {
        //
        NSString* key = [ruleString substringWithRange: NSMakeRange(y, 1)];
        
        LSDrawingRule* rule = self.rulesDictionary[key];
        
        if (rule) {
            [rules addObject: rule];
        }
        
    }
    return [rules copy];
}
-(NSString*) stringFromIndexPath: (NSIndexPath*) indexPath {
    NSString* pathString = [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
    return pathString;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    static NSString *NameCellIdentifier = @"NameCell";
    static NSString *CategoryCellIdentifier = @"CategoryCell";
    static NSString *DescriptionCellIdentifier = @"DescriptionCell";
    static NSString *ReplacementRuleCellIdentifier = @"MBLSReplacementRuleCell";
    static NSString *AxiomCellIdentifier = @"MBLSRuleCollectionTableCell";
    static NSString *RuleSourceCellIdentifier = @"MBLSRuleCollectionTableCell";
    
    NSString* indexString = [self stringFromIndexPath: indexPath];
    
    if (indexPath.section == TableSectionsDescription) {
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
    } else if (indexPath.section == TableSectionsRule) {
        // axiom
        MBLSRuleCollectionTableViewCell* newCell = nil;
//        newCell = self.rulesCollectionsDict[indexString];
        if (!newCell) {
            newCell = (MBLSRuleCollectionTableViewCell *)[tableView dequeueReusableCellWithIdentifier: AxiomCellIdentifier forIndexPath: indexPath];
            self.rulesCollectionsDict[indexString] = newCell.collectionView;
            
            self.axiomDataSource.rules = [self rulesArrayFromRuleString: self.fractal.axiom];
            newCell.collectionView.dataSource = self.axiomDataSource;
            //        newCell.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
            
            CGFloat itemSize = 26.0;
            CGFloat itemMargin = 2.0;
            NSInteger items = [newCell.collectionView numberOfItemsInSection: 0];
            UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)newCell.collectionView.collectionViewLayout;
            layout.itemSize = CGSizeMake(itemSize, itemSize);
            layout.minimumLineSpacing = itemMargin;
            layout.minimumInteritemSpacing = itemMargin;
            NSInteger rows = floorf(items/9.0) + 1;
            CGFloat height = rows*(itemSize+itemMargin);
            newCell.collectionView.currentHeightConstraint.constant = height;
            CGSize currentSize = newCell.collectionView.contentSize;
            newCell.collectionView.contentSize = CGSizeMake(currentSize.width, height);
            [newCell.collectionView reloadData];
            
            [newCell.collectionView setNeedsUpdateConstraints]; // needed to reapply cell and collection constraint heights.
        }
        
        cell = newCell;
//        [newCell.collectionView layoutIfNeeded];
        
    } else if (indexPath.section == TableSectionsReplacement) {
        // rules
        MBLSReplacementRuleTableViewCell *newCell = nil;
//        newCell = self.rulesCollectionsDict[indexString];
        if (!newCell) {
            newCell = (MBLSReplacementRuleTableViewCell *)[tableView dequeueReusableCellWithIdentifier: ReplacementRuleCellIdentifier forIndexPath: indexPath];
            self.rulesCollectionsDict[indexString] = newCell.rightCollectionView;
            
            LSReplacementRule* replacementRule = (self.sortedReplacementRulesArray)[indexPath.row];
            
            newCell.leftImageView.image = [self.rulesDictionary[replacementRule.contextString] asImage];
            
            MBRuleSourceCollectionDataSource* replacementRulesSource = self.replacementDataSourcesDict[replacementRule.contextString];
            if (!replacementRulesSource) {
                // already has a source
                replacementRulesSource = [MBRuleSourceCollectionDataSource new];
                self.replacementDataSourcesDict[replacementRule.contextString] = replacementRulesSource;
#pragma message "TODO remember to remove the replacementRuleSource when deleting the cell"
            }
            replacementRulesSource.rules = [self rulesArrayFromRuleString: replacementRule.replacementString];
            newCell.rightCollectionView.dataSource = replacementRulesSource;
            //        newCell.rightCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
            CGFloat itemSize = 26.0;
            CGFloat itemMargin = 2.0;
            NSInteger items = [newCell.rightCollectionView numberOfItemsInSection: 0];
            UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)newCell.rightCollectionView.collectionViewLayout;
            layout.itemSize = CGSizeMake(itemSize, itemSize);
            layout.minimumLineSpacing = itemMargin;
            layout.minimumInteritemSpacing = itemMargin;
            NSInteger rows = floorf(items/9.0) + 1;
            CGFloat height = rows*(itemSize+itemMargin);
            newCell.rightCollectionView.currentHeightConstraint.constant = height;
            CGSize currentSize = newCell.rightCollectionView.contentSize;
            newCell.rightCollectionView.contentSize = CGSizeMake(currentSize.width, height);
            [newCell.rightCollectionView reloadData];
            [newCell.rightCollectionView setNeedsUpdateConstraints]; // needed to reapply cell and collection constraint heights.
            (self.rulesCellIndexPaths)[replacementRule.contextString] = indexPath;
       }
        
        cell = newCell;
//        [newCell.rightCollectionView layoutIfNeeded];
        
    } else if (indexPath.section == TableSectionRules) {
        // Rule source section
        MBLSRuleCollectionTableViewCell *newCell = nil;
//        newCell = self.rulesCollectionsDict[indexString];
        if (!newCell) {
            newCell = (MBLSRuleCollectionTableViewCell *)[tableView dequeueReusableCellWithIdentifier: RuleSourceCellIdentifier forIndexPath: indexPath];
            self.rulesCollectionsDict[indexString] = newCell.collectionView;
            
            newCell.collectionView.dataSource = self.rulesDataSource;
            //        newCell.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
            
            CGFloat itemSize = 46.0;
            CGFloat itemMargin = 2.0;
            NSInteger items = [newCell.collectionView numberOfItemsInSection: 0];
            UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)newCell.collectionView.collectionViewLayout;
            layout.itemSize = CGSizeMake(itemSize, itemSize);
            layout.minimumLineSpacing = itemMargin;
            layout.minimumInteritemSpacing = itemMargin;
            NSInteger rows = floorf(items/9.0) + 1;
            CGFloat height = rows*(itemSize+itemMargin);
            newCell.collectionView.currentHeightConstraint.constant = height;
            CGSize currentSize = newCell.collectionView.contentSize;
            newCell.collectionView.contentSize = CGSizeMake(currentSize.width, height);
            [newCell.collectionView reloadData];
            [newCell.collectionView setNeedsUpdateConstraints]; // needed to reapply cell and collection constraint heights.
        }
        
//        CGSize largeCollectionSize = [newCell.collectionView systemLayoutSizeFittingSize: UILayoutFittingExpandedSize];
//        CGSize smallCollectionSize = [newCell.collectionView systemLayoutSizeFittingSize: UILayoutFittingCompressedSize];
//        CGSize largeContentSize = [newCell.collectionView.conte]
        
        cell = newCell;
//        [newCell.collectionView layoutIfNeeded];
    }
    
    return cell;
}
#pragma message "TODO: fix collectionView layout to be flexible height"
//- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    CGFloat estimatedRowHeight = tableView.estimatedRowHeight;
//    if (indexPath.section == TableSectionsRule) {
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
- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL result = YES;
    if (indexPath.section == TableSectionsDescription) {
        result = NO;
    } else if (indexPath.section == TableSectionsRule) {
        result = NO;
    } else if (indexPath.section == TableSectionsReplacement) {
        
    } else if (indexPath.section == TableSectionRules) {
        result = NO;
    }
    return result;
}
- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;
    
    if (indexPath.section == TableSectionsReplacement) {
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
#pragma message "TDOD replace with self.rulesDictionary?"
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
