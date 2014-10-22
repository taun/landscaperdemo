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
    _originalContextRule = nil;
}

-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule {
    UIView* returnView;
    
    CGRect collectionRect = [self convertRect: self.collectionView.bounds fromView: self.collectionView];
    CGRect placeholderImageRect = [self convertRect: self.customImageView.bounds fromView: self.customImageView];
    
    if (CGRectContainsPoint(collectionRect, point)) {
        // over collection
        // get data and collection and send to method
        CGPoint collectionPoint = [self convertPoint: point toView: self.collectionView];
        returnView = [super dragDidStartAtLocalPoint: collectionPoint draggingRule: draggingRule];
        
    } else if (CGRectContainsPoint(placeholderImageRect, point)) {
        // over rule placeholder imageView
        // ignoring readOnly for now
        // copy and leave placeholder in place to facillitate dragging placeholder into a replacement rules collection.
        draggingRule.rule = [self.replacementRule.contextRule mutableCopy];
        returnView = draggingRule.view;
    }
    return returnView;
}
/*!
 Pass on to contained views. Note entering the cell may not correspond to entering the subView due to margins.
 
 @param point        drag point in coordinates of receiving view
 @param draggingRule the draggingRule
 */
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingRule: (MBDraggingRule*) draggingRule {
    BOOL reloadContainer = NO;
    
    CGRect collectionRect = [self convertRect: self.collectionView.bounds fromView: self.collectionView];
    CGRect placeholderImageRect = [self convertRect: self.customImageView.bounds fromView: self.customImageView];
    
    if (CGRectContainsPoint(collectionRect, point)) {
        // over collection
        // get data and collection and send to method
        reloadContainer = [super dragDidEnterAtLocalPoint: point draggingRule: draggingRule];
        
    } else if (CGRectContainsPoint(placeholderImageRect, point)) {
        // over rule placeholder imageView
        // ignoring readOnly for now
        self.lastEnteredView = self.customImageView;
        _originalContextRule = self.replacementRule.contextRule;
        [self setContextRule: draggingRule.rule];
    }
    // this will just fall through until the touch is in one of the subviews
    return reloadContainer;
}
-(BOOL) dragDidChangeToLocalPoint:(CGPoint)point draggingRule:(MBDraggingRule *)draggingRule {
    BOOL reloadContainer = NO;
    CGRect collectionRect = [self convertRect: self.collectionView.bounds fromView: self.collectionView];
    CGRect placeholderImageRect = [self convertRect: self.customImageView.bounds fromView: self.customImageView];
    
    if (CGRectContainsPoint(collectionRect, point)) {
        // over collection
        // get data and collection and send to method
        reloadContainer = [super dragDidChangeToLocalPoint: point draggingRule: draggingRule];
        
    } else if (CGRectContainsPoint(placeholderImageRect, point)) {
        // over rule placeholder imageView
        // ignoring readOnly for now
        if (self.customImageView != self.lastEnteredView) {
            reloadContainer = [self dragDidEnterAtLocalPoint: point draggingRule: draggingRule];
        }
        // if point changing but still in view, do nothing
    } else {
        // in cell but not in either view
        if (self.lastEnteredView) {
            reloadContainer = [self dragDidExitDraggingRule: draggingRule];
        }
    }
    return reloadContainer;
}
-(BOOL) dragDidExitDraggingRule: (MBDraggingRule*) draggingRule {
    BOOL reloadContainer = NO;
    
    if ([self.replacementRule.rules containsObject: draggingRule.rule]) {
        // over collection
        // get data and collection and send to method
        reloadContainer = [super dragDidExitDraggingRule: draggingRule];
        
    } else if (self.replacementRule.contextRule == draggingRule.rule) {
        // over rule placeholder imageView
        // ignoring readOnly for now
        [self setContextRule: _originalContextRule];
    }
    
    _originalContextRule = nil;
    return reloadContainer;
}
-(BOOL) dragDidEndDraggingRule: (MBDraggingRule*) draggingRule {
    BOOL reloadContainer = NO;
    reloadContainer = [super dragDidEndDraggingRule: draggingRule];
    _originalContextRule = nil;
    return reloadContainer;
}

@end
