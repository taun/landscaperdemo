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
        [self configureAppearance];
    }
    return self;
}
-(void) awakeFromNib {
    [super awakeFromNib];
    [self configureAppearance];
//    self.currentWidthConstraint.constant = self.frame.size.width;
//    self.currentHeightConstraint.constant = self.frame.size.height;
}
-(void) configureAppearance {
//    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.translatesAutoresizingMaskIntoConstraints = YES;
    self.backgroundColor = [UIColor clearColor];
}
-(NSLayoutConstraint*) currentWidthConstraint {
    if (!_currentWidthConstraint) {
        _currentWidthConstraint = [NSLayoutConstraint constraintWithItem: self
                                                                attribute: NSLayoutAttributeWidth
                                                                relatedBy: NSLayoutRelationEqual
                                                                   toItem: nil
                                                                attribute: NSLayoutAttributeNotAnAttribute
                                                               multiplier: 1.0
                                                                 constant: 260.0];
        // Priority 999 seems necessary to stop autolayout constraint conflicts between desired height and UIView-Encapsulated-Layout-Height set by table class.
        _currentWidthConstraint.priority = 1000;
        
        [self addConstraint: _currentWidthConstraint];
    }
    return _currentWidthConstraint;
}
-(NSLayoutConstraint*) currentHeightConstraint {
    if (!_currentHeightConstraint) {
        _currentHeightConstraint = [NSLayoutConstraint constraintWithItem: self
                                                                attribute: NSLayoutAttributeHeight
                                                                relatedBy: NSLayoutRelationEqual
                                                                   toItem: nil
                                                                attribute: NSLayoutAttributeNotAnAttribute
                                                               multiplier: 1.0
                                                                 constant: 52.0];
        // Priority 999 seems necessary to stop autolayout constraint conflicts between desired height and UIView-Encapsulated-Layout-Height set by table class.
        _currentHeightConstraint.priority = 1000;
        
        [self addConstraint: _currentHeightConstraint];
    }
    return _currentHeightConstraint;
}

-(void)setRules:(NSMutableOrderedSet *)rules {
    if (_rules != rules) {
        _rules = rules;
        
        if (_rules) {
            _rulesSource = [MBRuleCollectionDataSource new];
            _rulesSource.rules = _rules;
            
            self.collectionView.dataSource = _rulesSource;
//            [self updateCollectionLayout];
            [self.collectionView reloadData];
        } else {
            _rulesSource = nil;
        }
    }
}
-(void)setItemSize:(CGFloat)itemSize {
    if (_itemSize != itemSize) {
        _itemSize = itemSize;
//        [self updateCollectionLayout];
    }
}
-(void)setItemMargin:(CGFloat)itemMargin {
    if (_itemMargin != itemMargin) {
        _itemMargin = itemMargin;
//        [self updateCollectionLayout];
    }
}
-(void)layoutMarginsDidChange {
    CGFloat width = self.bounds.size.width;
    [self setNeedsUpdateConstraints];
    [self layoutIfNeeded];
}
//-(void) updateCollectionLayout {
//    MDKUICollectionViewScrollContentSized* strongCollectionView = self.collectionView;
//
//    if (_itemMargin > 0.0 && _itemSize > 0.0) {
//        NSInteger items = [strongCollectionView numberOfItemsInSection: 0];
//        UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)strongCollectionView.collectionViewLayout;
//        layout.itemSize = CGSizeMake(_itemSize, _itemSize);
//        layout.minimumLineSpacing = _itemMargin;
//        layout.minimumInteritemSpacing = _itemMargin;
//        CGFloat cellWidth = strongCollectionView.bounds.size.width;
//        if (cellWidth) {
//            NSInteger itemsPerLine = (cellWidth / (_itemSize+2*_itemMargin));
//            NSInteger rows = floorf(items/itemsPerLine) + 1;
//            CGFloat height = rows*(_itemSize+_itemMargin);
//            strongCollectionView.currentHeightConstraint.constant = height;
//            CGSize currentSize = strongCollectionView.contentSize;
//            if (currentSize.height != height) {
//                strongCollectionView.contentSize = CGSizeMake(currentSize.width, height);
//                //            CGPoint origin = strongCollectionView.frame.origin;
//                //            CGSize size = strongCollectionView.frame.size;
//                //            self.frame = CGRectMake(origin.x, origin.y, size.width, height);
//                
//                [strongCollectionView setNeedsUpdateConstraints]; // needed to reapply cell and collection constraint heights.
//                [self.superview setNeedsLayout];
//                [self setNeedsLayout];
//                [strongCollectionView setNeedsLayout];
//            }
//        }
//        NSString* stackTrace = [[NSThread callStackSymbols] debugDescription];
////        [self.collectionView layoutIfNeeded];
////        [self layoutIfNeeded];
//    }
//}
//-(void)layoutSubviews {
//    UICollectionView* strongCollectionView = self.collectionView;
//    [super layoutSubviews];
//    [self updateCollectionLayout];
//    [super layoutSubviews];
//    CGFloat cellWidth = strongCollectionView.bounds.size.width;
//}
//-(CGSize) sizeThatFits:(CGSize)size {
//    UICollectionView* strongCollectionView = self.collectionView;
//    [strongCollectionView sizeToFit];
//}
/*!
 Prepares a reusable cell for reuse by the table view's delegate.
 */
-(void)prepareForReuse {
    self.isReadOnly = NO;
    self.lastIndexPath = nil;
    self.lastEnteredView = nil;
}
-(void) willChangeNotify {
    id strongObject = self.notifyObject;
    NSString* strongPath = self.notifyPath;
    
    if (strongObject && strongPath && strongPath.length > 0) {
        [strongObject willChangeValueForKey: strongPath];
    }
}
-(void) didChangeNotify {
    id strongObject = self.notifyObject;
    NSString* strongPath = self.notifyPath;

    if (strongObject && strongPath && strongPath.length > 0) {
        [strongObject didChangeValueForKey: strongPath];
    }
}
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule {
    UIView* returnView;
    UICollectionView* strongCollectionView = self.collectionView;
    
    CGPoint collectionLoc = [self convertPoint: point toView: strongCollectionView];
    NSIndexPath* ruleIndexPath = [strongCollectionView indexPathForItemAtPoint: collectionLoc];
    MBLSRuleCollectionViewCell* collectionSourceCell = (MBLSRuleCollectionViewCell*)[strongCollectionView cellForItemAtIndexPath: ruleIndexPath];
    
    if (collectionSourceCell) {
        LSDrawingRule* draggedRule;
        if (_isReadOnly) {
            draggedRule = [collectionSourceCell.rule mutableCopy];
        } else {
            draggedRule = collectionSourceCell.rule;
        }
        
        self.lastEnteredView = strongCollectionView;
        self.lastIndexPath = ruleIndexPath;
        
        draggingRule.rule = draggedRule;
        draggingRule.sourceCollection = strongCollectionView;
        draggingRule.sourceCollectionIndexPath = ruleIndexPath;
        
        returnView = draggingRule.view;
    }
    return returnView;
}
#pragma message "There is a possibility this is entered for the same view right after the didStart"
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule {
    BOOL reloadContainer = NO;
    UICollectionView* strongCollectionView = self.collectionView;
    UIView* strongLastEnteredView = self.lastEnteredView;
    

    if (!self.isReadOnly) {
        CGRect collectionRect = [self convertRect: strongCollectionView.bounds fromView: strongCollectionView];
        
        if (CGRectContainsPoint(collectionRect, point)) {
            CGPoint collectionLoc = [self convertPoint: point toView: strongCollectionView];
            NSIndexPath* rulesCollectionIndexPath = [self.collectionView indexPathForDropInSection: 0 atPoint: collectionLoc];
            
            if (rulesCollectionIndexPath) {
                // is the touch over a cell or at the end. indexPath will be nil in cell margins.
                [self willChangeNotify];
                [self.rules insertObject: draggingRule.rule atIndex: rulesCollectionIndexPath.row];
                [strongCollectionView insertItemsAtIndexPaths: @[rulesCollectionIndexPath]];
                [self didChangeNotify];
                
                self.lastEnteredView = strongCollectionView;
                self.lastIndexPath = rulesCollectionIndexPath;
                
                CGFloat remainder = fmodf([strongCollectionView numberOfItemsInSection: 0], 22.0);
                if (remainder == 0.0) {
                    // flag to relayout collection with additional row
                    reloadContainer = YES;
                }
            }
            
        } else if (strongLastEnteredView == strongCollectionView) {
            [self dragDidExitDraggingRule: draggingRule];
        }
    }
    
    return reloadContainer;
}
-(BOOL) dragDidChangeToLocalPoint:(CGPoint)point draggingRule:(MBDraggingRule *)draggingRule {
    BOOL reloadContainer = NO;
    UICollectionView* strongCollectionView = self.collectionView;
    
    if (!self.isReadOnly) {
        CGRect collectionRect = [self convertRect: strongCollectionView.bounds fromView: strongCollectionView];
        
        if (CGRectContainsPoint(collectionRect, point)) {
            if (self.lastEnteredView == strongCollectionView) {
                // was already here and just a change
                // only change if collection indexPath changed.
                CGPoint collectionLoc = [self convertPoint: point toView: strongCollectionView];
                NSIndexPath* rulesCollectionIndexPath = [strongCollectionView indexPathForDropInSection: 0 atPoint: collectionLoc];
                
                NSInteger lastCellRow = [strongCollectionView numberOfItemsInSection: 0] - 1;
                
                // check if the insertion path is past the last row
                if (lastCellRow < rulesCollectionIndexPath.row) {
                    rulesCollectionIndexPath = [NSIndexPath indexPathForItem: rulesCollectionIndexPath.row-1 inSection: rulesCollectionIndexPath.section];
                }
                
                if (rulesCollectionIndexPath != nil && self.lastIndexPath != nil && [rulesCollectionIndexPath compare: self.lastIndexPath] != NSOrderedSame) {
                    [self willChangeNotify];
                    [self.rules moveObjectsAtIndexes: [NSIndexSet indexSetWithIndex: self.lastIndexPath.row] toIndex: rulesCollectionIndexPath.row];
                    [strongCollectionView moveItemAtIndexPath: self.lastIndexPath toIndexPath: rulesCollectionIndexPath];
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
    UICollectionView* strongCollectionView = self.collectionView;

    if (!self.isReadOnly) {
        NSUInteger removeIndex = [self.rules indexOfObject: draggingRule.rule];
        if (removeIndex != NSNotFound) {
            [self willChangeNotify];
            [self.rules removeObjectAtIndex: removeIndex];
            [strongCollectionView deleteItemsAtIndexPaths: @[[NSIndexPath indexPathForRow: removeIndex inSection: 0]]];
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
