//
//  MBFractalTableDataSource.m
//  FractalScape
//
//  Created by Taun Chapman on 10/08/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBFractalTableDataSource.h"
#import "MBRuleCollectionDataSource.h"

#import "MBLSRuleTableViewCell.h"
#import "LSReplacementRule.h"
#import "LSDrawingRuleType+addons.h"
#import "LSDrawingRule+addons.h"

#import "MBBasicLabelTextTableCell.h"
#import "MBTextViewTableCell.h"
#import "MBLSRuleCollectionTableViewCell.h"
#import "MBLSRuleCollectionViewCell.h"
#import "MBLSReplacementRuleTableViewCell.h"

#import <MDUiKit/MDKLayerView.h>

typedef NS_ENUM(NSUInteger, enumTableSections) {
    TableSectionsDescription,
    TableSectionsRule,
    TableSectionsReplacement,
    TableSectionRules
};

@interface MBAxiomEditorTableSection : NSObject

@property (nonatomic,strong) NSString       *title;
@property (nonatomic,assign) NSInteger      rows;
@property (nonatomic,assign) BOOL           shouldIndentWhileEditing;
@property (nonatomic,assign) BOOL           canEditRow;
@property (nonatomic,strong) NSMutableArray *collections;

+(instancetype) newWithTitle: (NSString*) title rows: (NSInteger) rows;
-(instancetype) initWithTItle: (NSString*) title rows: (NSInteger) rows;

@end

@implementation MBAxiomEditorTableSection

+(instancetype) newWithTitle:(NSString *)title rows: (NSInteger) rows{
    return [[[self class] alloc] initWithTItle: title rows: (NSInteger) rows];
}
-(instancetype) initWithTItle:(NSString *)title rows: (NSInteger) rows{
    self = [super init];
    if (self) {
        _title = title;
        _rows = rows;
        _shouldIndentWhileEditing = NO;
        _canEditRow = YES;
    }
    return self;
}
-(NSMutableArray*)collections {
    if (!_collections) {
        _collections = [NSMutableArray new];
    }
    return _collections;
}
@end

@interface MBFractalTableDataSource ()

@property (nonatomic,strong) NSDictionary                   *rulesDictionary;
@property (nonatomic,strong) NSArray                        *sortedReplacementRules;

@property (nonatomic,strong) NSArray                        *tableSections;

@property (nonatomic,strong) MBRuleCollectionDataSource     *rulesDataSource;
@property (nonatomic,strong) MBRuleCollectionDataSource     *axiomDataSource;

@property (nonatomic,strong) NSMutableDictionary            *rulesCollectionsDict;
@property (nonatomic,strong) NSMutableDictionary            *replacementDataSourcesDict;

@property (nonatomic,strong) NSMutableDictionary            *rulesCellIndexPaths;

@end

@implementation MBFractalTableDataSource

+(instancetype) newSourceWithFractal: (LSFractal*) fractal {
    return [[[self class] alloc] initWithFractal: fractal];
}
- (instancetype)init
{
    self = [self initWithFractal: nil];
    return self;
}
-(instancetype) initWithFractal: (LSFractal*) fractal {
    self = [super init];
    if (self) {
        //
        [self setupDefaultProperties];
        self.fractal = fractal;
    }
    return self;
}
-(void)awakeFromNib {
    [super awakeFromNib];
    [self setupDefaultProperties];
}
-(void) setupDefaultProperties {
    MBAxiomEditorTableSection* desc = [MBAxiomEditorTableSection newWithTitle: @"Description" rows: 3];
    MBAxiomEditorTableSection* start = [MBAxiomEditorTableSection newWithTitle: @"Starting Rule" rows: 1];
    MBAxiomEditorTableSection* replace = [MBAxiomEditorTableSection newWithTitle:  @"Replacement Rules" rows: 0];
    replace.shouldIndentWhileEditing = YES;
    MBAxiomEditorTableSection* rules = [MBAxiomEditorTableSection newWithTitle: @"Available Rules" rows: 1];
    
    self.tableSections = @[desc,start,replace,rules];
}
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

#pragma mark - Setters Getters
-(void) setFractal:(LSFractal *)fractal {
    if (_fractal != fractal) {
        _fractal = fractal;
        NSSet* rules = _fractal.drawingRulesType.rules;
        if (rules.count > 0) {
            
            _replacementDataSourcesDict = nil;
            _sortedReplacementRules = nil;
            _rulesCollectionsDict = nil;
            _rulesCellIndexPaths = nil;

            MBAxiomEditorTableSection* replacements = (MBAxiomEditorTableSection*) self.tableSections[TableSectionsReplacement];
            replacements.rows = self.fractal.replacementRules.count;
            [self updateRulesDataSource];
            [self updateAxiomDataSource];
            
        }
    }
}
-(NSMutableDictionary*) rulesCollectionsDict {
    if (!_rulesCollectionsDict) {
        _rulesCollectionsDict = [NSMutableDictionary new];
    }
    return _rulesCollectionsDict;
}
-(NSMutableDictionary*)replacementDataSourcesDict {
    if (!_replacementDataSourcesDict) {
        _replacementDataSourcesDict = [NSMutableDictionary new];
    }
    return _replacementDataSourcesDict;
}
-(void) setSortedReplacementRulesArray:(NSArray *)sortedReplacementRulesArray {
    if (_sortedReplacementRules != sortedReplacementRulesArray) {
        [self removeReplacementRulesObserverFor: self.fractal];
        _sortedReplacementRules = sortedReplacementRulesArray;
    }
}
-(NSArray*) sortedReplacementRulesArray {
    if (!_sortedReplacementRules) {
        _sortedReplacementRules = [self.fractal newSortedReplacementRulesArray];
        [self addReplacementRulesObserverFor: self.fractal];
    }
    return _sortedReplacementRules;
}
-(NSMutableDictionary*) rulesCellIndexPaths {
    if (_rulesCellIndexPaths == nil) {
        _rulesCellIndexPaths = [[NSMutableDictionary alloc] initWithCapacity: 5];
    }
    return _rulesCellIndexPaths;
}


-(void)updateRulesDataSource {
    if (!_rulesDataSource) {
        _rulesDataSource = [MBRuleCollectionDataSource new];
    }
    NSSortDescriptor* ruleIndexSorting = [NSSortDescriptor sortDescriptorWithKey: @"displayIndex" ascending: YES];
    NSSortDescriptor* ruleAlphaSorting = [NSSortDescriptor sortDescriptorWithKey: @"iconIdentifierString" ascending: YES];
    NSArray* sortedRules = [self.fractal.drawingRulesType.rules sortedArrayUsingDescriptors: @[ruleIndexSorting,ruleAlphaSorting]];
    
    _rulesDataSource.rules = sortedRules;
}
-(void)updateAxiomDataSource {
    if (!_axiomDataSource) {
        _axiomDataSource = [MBRuleCollectionDataSource new];
    }
    _axiomDataSource.rules = [self.fractal rulesArrayFromRuleString: _fractal.axiom];
}
#pragma mark - TableDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.tableSections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    MBAxiomEditorTableSection* sectionData = (self.tableSections)[section];
    NSString* sectionHeader = sectionData.title;
    
    return sectionHeader;
}
- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    MBAxiomEditorTableSection* sectionData = (self.tableSections)[section];
    NSString* sectionHeader = sectionData.title;

    if (section == 3) {
        // section == "Available Rules"
        NSString* newHeader = [NSString stringWithFormat: @"%@ - press and hold to drag rule ^",sectionHeader];
        sectionHeader = newHeader;
    }
    
    UITableViewCell *sectionView = [tableView dequeueReusableCellWithIdentifier: @"HeaderCell"];
    sectionView.textLabel.text = sectionHeader;
    
    return sectionView;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
 
    MBAxiomEditorTableSection* sectionData = self.tableSections[section];
    return sectionData.rows;
}

-(NSString*) stringFromIndexPath: (NSIndexPath*) indexPath {
    NSString* pathString = [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
    return pathString;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    MBAxiomEditorTableSection* sectionData = self.tableSections[indexPath.section];

    static NSString *NameCellIdentifier = @"NameCell";
    static NSString *CategoryCellIdentifier = @"CategoryCell";
    static NSString *DescriptionCellIdentifier = @"DescriptionCell";
    static NSString *ReplacementRuleCellIdentifier = @"MBLSReplacementRuleCell";
    static NSString *AxiomCellIdentifier = @"MBLSRuleStartCollectionTableCell";
    static NSString *RuleSourceCellIdentifier = @"MBLSRuleCollectionTableCell";
    
    NSString* indexString = [self stringFromIndexPath: indexPath];
    
    if (indexPath.section == TableSectionsDescription) {
        // description
        if (indexPath.row==0) {
            //name
            MBBasicLabelTextTableCell *newCell = (MBBasicLabelTextTableCell *)[tableView dequeueReusableCellWithIdentifier: NameCellIdentifier];
            newCell.textLabel.text = @"Name:";
            newCell.textField.text = self.fractal.name;
            newCell.textField.delegate = self.controller;
            [newCell.textField addTarget: self
                                  action: @selector(nameInputChanged:)
                        forControlEvents: (UIControlEventEditingChanged | UIControlEventEditingDidEnd)];
            cell = newCell;
        } else if (indexPath.row==1) {
            MBBasicLabelTextTableCell *newCell = (MBBasicLabelTextTableCell *)[tableView dequeueReusableCellWithIdentifier: CategoryCellIdentifier];
            newCell.textLabel.text = @"Category:";
            newCell.textField.text = self.fractal.category;
            newCell.textField.delegate = self.controller;
            [newCell.textField addTarget: self
                                  action: @selector(categoryInputChanged:)
                        forControlEvents: (UIControlEventEditingChanged | UIControlEventEditingDidEnd)];
            cell = newCell;
        } else if (indexPath.row==2) {
            MBTextViewTableCell *newCell = [tableView dequeueReusableCellWithIdentifier: DescriptionCellIdentifier];
            //            newCell.textLabel.text = @"Description:";
            newCell.textView.text = self.fractal.descriptor;
            newCell.textView.delegate = self.controller;
            cell = newCell;
        }
    } else if (indexPath.section == TableSectionsRule) {
        // axiom
        MBLSRuleCollectionTableViewCell* newCell = nil;
        //        newCell = self.rulesCollectionsDict[indexString];
        if (!newCell) {
            newCell = (MBLSRuleCollectionTableViewCell *)[tableView dequeueReusableCellWithIdentifier: AxiomCellIdentifier forIndexPath: indexPath];
            self.rulesCollectionsDict[indexString] = newCell.collectionView;
            
            newCell.collectionView.dataSource = self.axiomDataSource;
            newCell.collectionView.delegate = self.controller;
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
            newCell = [tableView dequeueReusableCellWithIdentifier: ReplacementRuleCellIdentifier forIndexPath: indexPath];
            self.rulesCollectionsDict[indexString] = newCell.rightCollectionView;
            
            LSReplacementRule* replacementRule = (self.sortedReplacementRulesArray)[indexPath.row];
            
            newCell.leftImageView.image = [self.fractal.rulesDictionary[replacementRule.contextString] asImage];
            
            MBRuleCollectionDataSource* replacementRulesSource = self.replacementDataSourcesDict[replacementRule.contextString];
            if (!replacementRulesSource) {
                // already has a source
                replacementRulesSource = [MBRuleCollectionDataSource new];
                self.replacementDataSourcesDict[replacementRule.contextString] = replacementRulesSource;
#pragma message "TODO remember to remove the replacementRuleSource when deleting the cell"
            }
            replacementRulesSource.rules = [self.fractal rulesArrayFromRuleString: replacementRule.replacementString];
            newCell.rightCollectionView.dataSource = replacementRulesSource;
            newCell.rightCollectionView.delegate = self.controller;
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
            newCell.collectionView.delegate = self.controller;
            
            //        newCell.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
#pragma message "All of the stuff below should be in cell class 'prepareForReuse' ? or when setting itemSize? of class"
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
- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    MBAxiomEditorTableSection* sectionData = (self.tableSections)[indexPath.section];
    return sectionData.shouldIndentWhileEditing;
}
- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    MBAxiomEditorTableSection* sectionData = (self.tableSections)[indexPath.section];
    return sectionData.canEditRow;
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
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
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

@end
