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

#import "MBFractalDescriptionTableCell.h"
#import "MBLSRuleBaseCollectionTableViewCell.h"
#import "MBLSRuleBaseCollectionViewCell.h"
#import "MBLSReplacementRuleTableViewCell.h"


#import "MBAxiomEditorTableSection.h"

#import "MDKUICollectionViewScrollContentSized.h"

static NSString *NameCellIdentifier = @"NameCell";
static NSString *ReplacementRuleCellIdentifier = @"MBLSReplacementRuleCell";
static NSString *AxiomCellIdentifier = @"MBLSRuleStartCollectionTableCell";
static NSString *RuleSourceCellIdentifier = @"MBLSRuleCollectionTableCell";

@interface MBFractalTableDataSource ()

@property (nonatomic,strong) MBRuleCollectionDataSource     *cachedAxiomDataSource;
@property (nonatomic,strong) MBRuleCollectionDataSource     *cachedRulesDataSource;

@property (nonatomic,strong) NSMutableDictionary            *cachedRulesCollectionsDict;
@property (nonatomic,strong) NSMutableArray                 *cachedReplacementDataSourcesArray;

@end

@implementation MBFractalTableDataSource

+(instancetype) newSourceWithFractal:(LSFractal*)fractal tableSections: (NSArray*) sections {
    return [[[self class] alloc] initWithFractal: fractal tableSections: sections];
}
- (instancetype)init
{
    self = [self initWithFractal: nil tableSections: nil];
    return self;
}
-(instancetype) initWithFractal:(LSFractal*)fractal tableSections: (NSArray*) sections {
    self = [super init];
    if (self) {
        //
        _fractal = fractal;
        _tableSections = sections;
    }
    return self;
}
-(void)awakeFromNib {
    [super awakeFromNib];
}

#pragma mark - Setters Getters
-(void)setFractal:(LSFractal *)fractal {
    LSFractal* strongFractalProperty = _fractal;
    
    if (strongFractalProperty != fractal) {
        _fractal = fractal;
        strongFractalProperty = _fractal;
        
        if (strongFractalProperty) {
            _cachedRulesDataSource = [MBRuleCollectionDataSource newWithRules: strongFractalProperty.drawingRulesType.rules];
            _cachedAxiomDataSource = [MBRuleCollectionDataSource newWithRules: strongFractalProperty.startingRules];
            
        } else {
            _cachedAxiomDataSource = nil;
            _cachedRulesDataSource = nil;
            _cachedRulesCollectionsDict = nil;
            _cachedReplacementDataSourcesArray = nil;
        }
    }
}
-(NSMutableDictionary*) cachedRulesCollectionsDict {
    if (!_cachedRulesCollectionsDict) {
        _cachedRulesCollectionsDict = [NSMutableDictionary new];
    }
    return _cachedRulesCollectionsDict;
}
-(NSMutableArray*)cachedReplacementDataSourcesArray {
    if (!_cachedReplacementDataSourcesArray) {
        _cachedReplacementDataSourcesArray = [NSMutableArray new];
    }
    return _cachedReplacementDataSourcesArray;
}

#pragma mark - TableDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.tableSections count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    MBAxiomEditorTableSection* tableSection = (self.tableSections)[section];
    NSString* sectionHeader = tableSection.title;

    return sectionHeader;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    LSFractal* strongFractalProperty = self.fractal;
 
    NSInteger count = 0;
    
    if (section == TableSectionsDescription) {
        //
        count = 1;
        
    } else if (section == TableSectionsAxiom) {
        //
        count = 1;
        
    } else if (section == TableSectionsReplacement) {
        //
        count = strongFractalProperty.replacementRules.count;
        
    } else if (section == TableSectionsRules) {
        //
        count = 1;
    }
    
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    LSFractal* strongFractalProperty = self.fractal;
    
    
    if (indexPath.section == TableSectionsDescription) {
        // description
            //name
        MBFractalDescriptionTableCell *newCell = (MBFractalDescriptionTableCell *)[tableView dequeueReusableCellWithIdentifier: NameCellIdentifier];
        newCell.textField.text = strongFractalProperty.name;
        newCell.textView.text = strongFractalProperty.descriptor;
        newCell.pickerView.delegate = self.pickerDelegate;
        newCell.pickerView.dataSource = self.pickerSource;
        NSInteger catIndex = [[strongFractalProperty allCategories] indexOfObject: strongFractalProperty.category];
        [newCell.pickerView selectRow: catIndex inComponent: 0 animated: YES];
        cell = newCell;
    } else if (indexPath.section == TableSectionsAxiom) {
        // axiom
        MBLSRuleBaseCollectionTableViewCell* newCell = nil;
        if (!newCell) {
            newCell = (MBLSRuleBaseCollectionTableViewCell *)[tableView dequeueReusableCellWithIdentifier: AxiomCellIdentifier forIndexPath: indexPath];
            newCell.rules = [strongFractalProperty mutableOrderedSetValueForKey: [LSFractal startingRulesKey]];
            newCell.notifyObject = strongFractalProperty;
            newCell.notifyPath = [LSFractal startingRulesKey];
            newCell.isReadOnly = NO;
            newCell.itemSize = 26.0;
            newCell.itemMargin = 2.0;
            CGFloat newHeight = [self calculateCollectionHeightFor: newCell.collectionView itemSize: 26.0 itemMargin: 2.0 itemCount: newCell.rules.count];
            newCell.collectionView.currentHeightConstraint.constant = newHeight;
        }
        
        cell = newCell;
        
    } else if (indexPath.section == TableSectionsReplacement) {
        // rules
        LSReplacementRule* replacementRule = strongFractalProperty.replacementRules[indexPath.row];

        MBLSReplacementRuleTableViewCell *newCell = nil;
        if (replacementRule) {
            newCell = [tableView dequeueReusableCellWithIdentifier: ReplacementRuleCellIdentifier forIndexPath: indexPath];
            newCell.replacementRule = replacementRule;
            newCell.notifyObject = strongFractalProperty;
            newCell.notifyPath = [LSFractal replacementRulesKey];
            newCell.isReadOnly = NO;
            newCell.itemSize = 26.0;
            newCell.itemMargin = 2.0;
            CGFloat newHeight = [self calculateCollectionHeightFor: newCell.collectionView itemSize: 26.0 itemMargin: 2.0 itemCount: newCell.replacementRule.rules.count];
            newCell.collectionView.currentHeightConstraint.constant = newHeight;
        }
        
        cell = newCell;
        
    } else if (indexPath.section == TableSectionsRules) {
        // Rule source section
        MBLSRuleBaseCollectionTableViewCell *newCell = nil;
        if (!newCell) {
            newCell = (MBLSRuleBaseCollectionTableViewCell *)[tableView dequeueReusableCellWithIdentifier: RuleSourceCellIdentifier forIndexPath: indexPath];
            newCell.rules = [strongFractalProperty.drawingRulesType mutableOrderedSetValueForKey: [LSDrawingRuleType rulesKey]];
            newCell.notifyObject = strongFractalProperty.drawingRulesType;
            newCell.notifyPath = [LSDrawingRuleType rulesKey];
            newCell.isReadOnly = YES;
            newCell.itemSize = 46.0;
            newCell.itemMargin = 2.0;
            CGFloat newHeight = [self calculateCollectionHeightFor: newCell.collectionView itemSize: 46.0 itemMargin: 2.0 itemCount: newCell.rules.count];
            newCell.collectionView.currentHeightConstraint.constant = newHeight;
        }
        
        cell = newCell;
    }
    
    return cell;
}
-(CGFloat) calculateCollectionHeightFor: (UICollectionView*) cell itemSize: (CGFloat)itemSize itemMargin: (CGFloat) itemMargin itemCount: (NSInteger)count {
    // force the newly loaded cell to update the layout before calculating the
    [cell setNeedsUpdateConstraints];
    [cell setNeedsLayout];
    #pragma message "KEY to making embedded dynamic collectionViews work."
    [cell layoutIfNeeded];
    
    CGFloat cellWidth = cell.bounds.size.width;
    CGFloat itemWidth = itemMargin+itemSize;
    NSInteger lines = 1;
    if (cellWidth) {
        CGFloat itemsPerLine = floorf(cellWidth/itemWidth);
        lines = ceilf(count/itemsPerLine);
    }
    CGFloat newHeight = lines * itemWidth;
    return newHeight;
}
- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    MBAxiomEditorTableSection* tableSection = self.tableSections[indexPath.section];
    return tableSection.canEditRow;
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

@end
