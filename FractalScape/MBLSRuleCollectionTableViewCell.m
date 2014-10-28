//
//  MBLSRuleCollectionTableViewCell.m
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSRuleCollectionTableViewCell.h"
#import "MBLSRuleCollectionViewCell.h"

@interface MBLSRuleCollectionTableViewCell ()


@end

@implementation MBLSRuleCollectionTableViewCell

/*!
 Initializes a table cell with a style and a reuse identifier and returns it to the caller.
 
 @param style           A constant indicating a cell style. See UITableViewCellStyle for descriptions of these constants.
 @param reuseIdentifier A string used to identify the cell object if it is to be reused for drawing multiple rows of a table view. Pass nil if the cell object is not to be reused. You should use the same reuse identifier for all cells of the same form.
 
 @return An initialized UITableViewCell object or nil if the object could not be created.
 */
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _isReadOnly = NO;
    }
    return self;
}
-(void)setRules:(NSMutableOrderedSet *)rules {
    if (_rules != rules) {
        _rules = rules;
        
        if (_rules) {
            _rulesSource = [MBRuleCollectionDataSource new];
            _rulesSource.rules = _rules;
            
            self.collectionView.dataSource = _rulesSource;
            [self updateCollectionLayout];
            [self.collectionView reloadData];
        } else {
            _rulesSource = nil;
        }
    }
}
-(void)setItemSize:(CGFloat)itemSize {
    if (_itemSize != itemSize) {
        _itemSize = itemSize;
        [self updateCollectionLayout];
    }
}
-(void)setItemMargin:(CGFloat)itemMargin {
    if (_itemMargin != itemMargin) {
        _itemMargin = itemMargin;
        [self updateCollectionLayout];
    }
}
-(void) updateCollectionLayout {
    if (_itemMargin > 0.0 && _itemSize > 0.0) {
        NSInteger items = [self.collectionView numberOfItemsInSection: 0];
        UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
        layout.itemSize = CGSizeMake(_itemSize, _itemSize);
        layout.minimumLineSpacing = _itemMargin;
        layout.minimumInteritemSpacing = _itemMargin;
        NSInteger rows = floorf(items/9.0) + 1;
        CGFloat height = rows*(_itemSize+_itemMargin);
        self.collectionView.currentHeightConstraint.constant = height;
        CGSize currentSize = self.collectionView.contentSize;
        self.collectionView.contentSize = CGSizeMake(currentSize.width, height);
        [self.collectionView setNeedsUpdateConstraints]; // needed to reapply cell and collection constraint heights.
    }
}
/*!
 Prepares a reusable cell for reuse by the table view's delegate.
 */
-(void)prepareForReuse {
    self.isReadOnly = NO;
    self.lastIndexPath = nil;
    self.lastEnteredView = nil;
}
-(void) willChangeNotify {
    if (self.notifyObject && self.notifyPath && self.notifyPath.length > 0) {
        [self.notifyObject willChangeValueForKey: self.notifyPath];
    }
}
-(void) didChangeNotify {
    if (self.notifyObject && self.notifyPath && self.notifyPath.length > 0) {
        [self.notifyObject didChangeValueForKey: self.notifyPath];
    }
}
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule {
    UIView* returnView;
    
    CGPoint collectionLoc = [self convertPoint: point toView: self.collectionView];
    NSIndexPath* ruleIndexPath = [self.collectionView indexPathForItemAtPoint: collectionLoc];
    MBLSRuleCollectionViewCell* collectionSourceCell = (MBLSRuleCollectionViewCell*)[self.collectionView cellForItemAtIndexPath: ruleIndexPath];
    
    if (collectionSourceCell) {
        LSDrawingRule* draggedRule;
        if (_isReadOnly) {
            draggedRule = [collectionSourceCell.rule mutableCopy];
        } else {
            draggedRule = collectionSourceCell.rule;
        }
        
        self.lastEnteredView = self.collectionView;
        self.lastIndexPath = ruleIndexPath;
        
        draggingRule.rule = draggedRule;
        draggingRule.sourceCollection = self.collectionView;
        draggingRule.sourceCollectionIndexPath = ruleIndexPath;
        
        returnView = draggingRule.view;
    }
    return returnView;
}
#pragma message "There is a possibility this is entered for the same view right after the didStart"
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule {
    BOOL reloadContainer = NO;
    
    if (!self.isReadOnly) {
        CGRect collectionRect = [self convertRect: self.collectionView.bounds fromView: self.collectionView];
        
        if (CGRectContainsPoint(collectionRect, point)) {
            CGPoint collectionLoc = [self convertPoint: point toView: self.collectionView];
            NSIndexPath* rulesCollectionIndexPath = [self.collectionView indexPathForDropInSection: 0 atPoint: collectionLoc];
            
            if (rulesCollectionIndexPath) {
                // is the touch over a cell or at the end. indexPath will be nil in cell margins.
                [self willChangeNotify];
                [self.rules insertObject: draggingRule.rule atIndex: rulesCollectionIndexPath.row];
                [self.collectionView insertItemsAtIndexPaths: @[rulesCollectionIndexPath]];
                [self didChangeNotify];
                
                self.lastEnteredView = self.collectionView;
                self.lastIndexPath = rulesCollectionIndexPath;
                
                CGFloat remainder = fmodf([self.collectionView numberOfItemsInSection: 0], 9.0);
                if (remainder == 0.0) {
                    // flag to relayout collection with additional row
                    reloadContainer = YES;
                }
            }
            
        } else if (self.lastEnteredView == self.collectionView) {
            [self dragDidExitDraggingRule: draggingRule];
        }
    }
    
    return reloadContainer;
}
-(BOOL) dragDidChangeToLocalPoint:(CGPoint)point draggingRule:(MBDraggingRule *)draggingRule {
    BOOL reloadContainer = NO;
    
    if (!self.isReadOnly) {
        CGRect collectionRect = [self convertRect: self.collectionView.bounds fromView: self.collectionView];
        
        if (CGRectContainsPoint(collectionRect, point)) {
            if (self.lastEnteredView == self.collectionView) {
                // was already here and just a change
                // only change if collection indexPath changed.
                CGPoint collectionLoc = [self convertPoint: point toView: self.collectionView];
                NSIndexPath* rulesCollectionIndexPath = [self.collectionView indexPathForDropInSection: 0 atPoint: collectionLoc];
                
                NSInteger lastCellRow = [self.collectionView numberOfItemsInSection: 0] - 1;
                
                // check if the insertion path is past the last row
                if (lastCellRow < rulesCollectionIndexPath.row) {
                    rulesCollectionIndexPath = [NSIndexPath indexPathForItem: rulesCollectionIndexPath.row-1 inSection: rulesCollectionIndexPath.section];
                }
                
                if (rulesCollectionIndexPath != nil && self.lastIndexPath != nil && [rulesCollectionIndexPath compare: self.lastIndexPath] != NSOrderedSame) {
                    [self willChangeNotify];
                    [self.rules moveObjectsAtIndexes: [NSIndexSet indexSetWithIndex: self.lastIndexPath.row] toIndex: rulesCollectionIndexPath.row];
                    [self.collectionView moveItemAtIndexPath: self.lastIndexPath toIndexPath: rulesCollectionIndexPath];
                    [self didChangeNotify];
                    
                    self.lastIndexPath = rulesCollectionIndexPath;
                }
            } else {
                [self dragDidEnterAtLocalPoint: point draggingRule: draggingRule];
            }
        }
    }
    return reloadContainer;
}
-(BOOL) dragDidExitDraggingRule: (MBDraggingRule*) draggingRule {
    BOOL reloadContainer = NO;
    if (!self.isReadOnly) {
        NSUInteger removeIndex = [self.rules indexOfObject: draggingRule.rule];
        if (removeIndex != NSNotFound) {
            [self willChangeNotify];
            [self.rules removeObjectAtIndex: removeIndex];
            [self.collectionView deleteItemsAtIndexPaths: @[[NSIndexPath indexPathForRow: removeIndex inSection: 0]]];
            [self didChangeNotify];
        }
    }
    self.lastEnteredView = nil;
    self.lastIndexPath = nil;
    return reloadContainer;
}
-(BOOL) dragDidEndDraggingRule: (MBDraggingRule*) draggingRule {
    BOOL reloadContainer = NO;
    self.lastEnteredView = nil;
    self.lastIndexPath = nil;
    return reloadContainer;
}

@end
