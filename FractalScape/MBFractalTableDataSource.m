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

#import "MBAxiomEditorTableSection.h"

#import <MDUiKit/MDKLayerView.h>

@interface MBFractalTableDataSource ()

@property (nonatomic,strong) MBRuleCollectionDataSource     *axiomDataSource;
@property (nonatomic,strong) MBRuleCollectionDataSource     *rulesDataSource;

@property (nonatomic,strong) NSMutableDictionary            *rulesCollectionsDict;
@property (nonatomic,strong) NSMutableArray                 *replacementDataSourcesArray;

@end

@implementation MBFractalTableDataSource

+(instancetype) newSourceWithFractalData:(NSMutableArray *)fractalData {
    return [[[self class] alloc] initWithFractalData: fractalData];
}
- (instancetype)init
{
    self = [self initWithFractalData: nil];
    return self;
}
-(instancetype) initWithFractalData:(NSMutableArray *)fractalData {
    self = [super init];
    if (self) {
        //
        self.fractalData = fractalData;
    }
    return self;
}
-(void)awakeFromNib {
    [super awakeFromNib];
}

#pragma mark - Setters Getters
-(void)setFractalData:(NSMutableArray *)fractalData {
    if (_fractalData != fractalData) {
        _fractalData = fractalData;
        
        MBAxiomEditorTableSection* axiomSection = fractalData[TableSectionsAxiom];
        _axiomDataSource = [MBRuleCollectionDataSource newWithRules: axiomSection.data];

        MBAxiomEditorTableSection* rulesSection = fractalData[TableSectionsRules];
        _rulesDataSource = [MBRuleCollectionDataSource newWithRules: rulesSection.data[0]];
        
        MBAxiomEditorTableSection* replacementSection = fractalData[TableSectionsReplacement];
        _replacmentCollections = [NSPointerArray pointerArrayWithOptions: NSPointerFunctionsWeakMemory];
        [_replacmentCollections setCount: replacementSection.data.count];
    }
}
-(NSMutableDictionary*) rulesCollectionsDict {
    if (!_rulesCollectionsDict) {
        _rulesCollectionsDict = [NSMutableDictionary new];
    }
    return _rulesCollectionsDict;
}
-(NSMutableArray*)replacementDataSourcesArray {
    if (!_replacementDataSourcesArray) {
        _replacementDataSourcesArray = [NSMutableArray new];
    }
    return _replacementDataSourcesArray;
}

#pragma mark - TableDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.fractalData count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    MBAxiomEditorTableSection* tableSection = (self.fractalData)[section];
    NSString* sectionHeader = tableSection.title;
    
    return sectionHeader;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
 
    MBAxiomEditorTableSection* tableSection = self.fractalData[section];
    return [tableSection.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    MBAxiomEditorTableSection* tableSection = self.fractalData[indexPath.section];
    NSArray* tableSectionData = tableSection.data;

    static NSString *NameCellIdentifier = @"NameCell";
    static NSString *CategoryCellIdentifier = @"CategoryCell";
    static NSString *DescriptionCellIdentifier = @"DescriptionCell";
    static NSString *ReplacementRuleCellIdentifier = @"MBLSReplacementRuleCell";
    static NSString *AxiomCellIdentifier = @"MBLSRuleStartCollectionTableCell";
    static NSString *RuleSourceCellIdentifier = @"MBLSRuleCollectionTableCell";
    
    if (indexPath.section == TableSectionsDescription) {
        // description
        if (indexPath.row==0) {
            //name
            MBBasicLabelTextTableCell *newCell = (MBBasicLabelTextTableCell *)[tableView dequeueReusableCellWithIdentifier: NameCellIdentifier];
            newCell.textLabel.text = @"Name:";
            newCell.textField.text = tableSectionData[indexPath.row];
            cell = newCell;
        } else if (indexPath.row==1) {
            MBBasicLabelTextTableCell *newCell = (MBBasicLabelTextTableCell *)[tableView dequeueReusableCellWithIdentifier: CategoryCellIdentifier];
            newCell.textLabel.text = @"Category:";
            newCell.textField.text = tableSectionData[indexPath.row];
            cell = newCell;
        } else if (indexPath.row==2) {
            MBTextViewTableCell *newCell = [tableView dequeueReusableCellWithIdentifier: DescriptionCellIdentifier];
            //            newCell.textLabel.text = @"Description:";
            newCell.textView.text = tableSectionData[indexPath.row];
            cell = newCell;
        }
    } else if (indexPath.section == TableSectionsAxiom) {
        // axiom
        MBLSRuleCollectionTableViewCell* newCell = nil;
        //        newCell = self.rulesCollectionsDict[indexString];
        if (!newCell) {
            newCell = (MBLSRuleCollectionTableViewCell *)[tableView dequeueReusableCellWithIdentifier: AxiomCellIdentifier forIndexPath: indexPath];
            
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
            newCell = [tableView dequeueReusableCellWithIdentifier: ReplacementRuleCellIdentifier forIndexPath: indexPath];
            
            newCell.leftImageView.image = [tableSectionData[indexPath.row][0] asImage];
            
            MBRuleCollectionDataSource* replacementRulesSource;
            if (self.replacementDataSourcesArray.count > indexPath.row) {
                // already has a source
                replacementRulesSource = self.replacementDataSourcesArray[indexPath.row];
            } else {
                replacementRulesSource = [MBRuleCollectionDataSource new];
                self.replacementDataSourcesArray[indexPath.row] = replacementRulesSource;
#pragma message "TODO remember to remove the replacementRuleSource when deleting the cell"
            }
            replacementRulesSource.rules = tableSectionData[indexPath.row][1];
            newCell.rightCollectionView.dataSource = replacementRulesSource;
            [self.replacmentCollections replacePointerAtIndex: indexPath.row withPointer: (__bridge void *)(newCell.rightCollectionView)];
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
        }
        
        cell = newCell;
        //        [newCell.rightCollectionView layoutIfNeeded];
        
    } else if (indexPath.section == TableSectionsRules) {
        // Rule source section
        MBLSRuleCollectionTableViewCell *newCell = nil;
        //        newCell = self.rulesCollectionsDict[indexString];
        if (!newCell) {
            newCell = (MBLSRuleCollectionTableViewCell *)[tableView dequeueReusableCellWithIdentifier: RuleSourceCellIdentifier forIndexPath: indexPath];
            
            newCell.collectionView.dataSource = self.rulesDataSource;
            self.rulesCollectionView = newCell.collectionView;
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
- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    MBAxiomEditorTableSection* tableSection = self.fractalData[indexPath.section];
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
