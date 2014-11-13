//
//  MBLSReplacementRuleTableViewCell.m
//  FractalScape
//
//  Created by Taun Chapman on 10/01/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBLSReplacementRuleTableViewCell.h"
#import "MBRuleCollectionDataSource.h"
#import "MBLSRuleDragAndDropProtocol.h"

@interface MBLSReplacementRuleTableViewCell ()

@property (nonatomic,strong) LSDrawingRule                  *originalContextRule;

@end

@implementation MBLSReplacementRuleTableViewCell

/*!
 Initializes a table cell with a style and a reuse identifier and returns it to the caller.
 
 @param style           A constant indicating a cell style. See UITableViewCellStyle for descriptions of these constants.
 @param reuseIdentifier A string used to identify the cell object if it is to be reused for drawing multiple rows of a table view. Pass nil if the cell object is not to be reused. You should use the same reuse identifier for all cells of the same form.
 
 @return An initialized UITableViewCell object or nil if the object could not be created.
 */
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}
-(void)setReplacementRule:(LSReplacementRule *)replacementRule {
    if (_replacementRule != replacementRule) {
        _replacementRule = replacementRule;
        
        if (_replacementRule) {
            self.rules = [_replacementRule mutableOrderedSetValueForKey: @"rules"];

            self.customImageView.image = [_replacementRule.contextRule asImage];
        } else {
            self.rules = nil;
            _customImageView.image = nil;
        }
    }
}
-(void) setContextRule: (LSDrawingRule*) contextRule {
    [self.notifyObject willChangeValueForKey: self.notifyPath];
    _replacementRule.contextRule = contextRule;
    self.customImageView.image = [_replacementRule.contextRule asImage];
    [self.notifyObject didChangeValueForKey: self.notifyPath];
}
/*!
 Prepares a reusable cell for reuse by the table view's delegate.
 Just here for future reference.
 */
-(void)prepareForReuse {
    [super prepareForReuse];
    self.replacementRule = nil;
}

-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingItem*) draggingRule {
    UIView* returnView;
    
    UICollectionView* strongCollectionView = self.collectionView;
    UIImageView* strongImageView = self.customImageView;
    
    CGRect collectionRect = [self convertRect: strongCollectionView.bounds fromView: strongCollectionView];
    CGRect placeholderImageRect = [self convertRect: strongImageView.bounds fromView: strongImageView];
    
    if (CGRectContainsPoint(collectionRect, point)) {
        // over collection
        // get data and collection and send to method
        returnView = [super dragDidStartAtLocalPoint: point draggingItem: draggingRule];
        
    } else if (CGRectContainsPoint(placeholderImageRect, point)) {
        // over rule placeholder imageView
        // ignoring readOnly for now
        // copy and leave placeholder in place to facillitate dragging placeholder into a replacement rules collection.
        draggingRule.dragItem = [self.replacementRule.contextRule mutableCopy];
        returnView = draggingRule.view;
    }
    return returnView;
}
/*!
 Pass on to contained views. Note entering the cell may not correspond to entering the subView due to margins.
 
 @param point        drag point in coordinates of receiving view
 @param draggingRule the draggingRule
 */
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingItem*) draggingRule {
    BOOL reloadContainer = NO;
    
    UICollectionView* strongCollectionView = self.collectionView;
    UIImageView* strongImageView = self.customImageView;

    CGRect collectionRect = [self convertRect: strongCollectionView.bounds fromView: strongCollectionView];
    CGRect placeholderImageRect = [self convertRect: strongImageView.bounds fromView: strongImageView];
    
    if (CGRectContainsPoint(collectionRect, point)) {
        // over collection
        // get data and collection and send to method
        reloadContainer = [super dragDidEnterAtLocalPoint: point draggingItem: draggingRule];
        
    } else if (CGRectContainsPoint(placeholderImageRect, point)) {
        // over rule placeholder imageView
        // ignoring readOnly for now
        draggingRule.oldReplacedDragItem = self.replacementRule.contextRule;
        [self setContextRule: draggingRule.dragItem];
    }
    // this will just fall through until the touch is in one of the subviews
    return reloadContainer;
}
-(BOOL) dragDidChangeToLocalPoint:(CGPoint)point draggingRule:(MBDraggingItem *)draggingRule {
    BOOL reloadContainer = NO;

    UICollectionView* strongCollectionView = self.collectionView;
    UIImageView* strongImageView = self.customImageView;
    
    CGRect collectionRect = [self convertRect: strongCollectionView.bounds fromView: strongCollectionView];
    CGRect placeholderImageRect = [self convertRect: strongImageView.bounds fromView: strongImageView];

    if (CGRectContainsPoint(collectionRect, point)) {
        // over collection
        // get data and collection and send to method
        reloadContainer = [super dragDidChangeToLocalPoint: point draggingItem: draggingRule];
        
    } else if (CGRectContainsPoint(placeholderImageRect, point)) {
        // over rule placeholder imageView
        // ignoring readOnly for now
        if (self.replacementRule.contextRule != draggingRule.dragItem) {
            // imageView rule is not already the dragging rule so enter fresh
            reloadContainer = [self dragDidEnterAtLocalPoint: point draggingItem: draggingRule];
        }
        // if point changing but still in view, do nothing
    } else {
        // in cell but not in either view
        if (self.replacementRule.contextRule == draggingRule.dragItem || [self.rules containsObject: draggingRule.dragItem]) {
            reloadContainer = [self dragDidExitDraggingItem: draggingRule];
        }
    }
    return reloadContainer;
}
-(BOOL) dragDidExitDraggingRule: (MBDraggingItem*) draggingRule {
    BOOL reloadContainer = NO;
    
    if ([self.replacementRule.rules containsObject: draggingRule.dragItem]) {
        // over collection
        // get data and collection and send to method
        reloadContainer = [super dragDidExitDraggingItem: draggingRule];
        
    } else if (self.replacementRule.contextRule == draggingRule.dragItem) {
        // over rule placeholder imageView
        // ignoring readOnly for now
        [self setContextRule: draggingRule.oldReplacedDragItem];
        draggingRule.oldReplacedDragItem = nil;
    }
    
    return reloadContainer;
}
-(BOOL) dragDidEndDraggingRule: (MBDraggingItem*) draggingRule {
    BOOL reloadContainer = NO;
    reloadContainer = [super dragDidEndDraggingItem: draggingRule];
    return reloadContainer;
}

@end
