//
//  MBDraggingRule.m
//  FractalScape
//
//  Created by Taun Chapman on 10/09/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBDraggingRule.h"
#import <MDUiKit/MDKLayerView.h>

@interface MBDraggingRule ()

@property (nonatomic,strong) CALayer*       imageLayer;
@property (nonatomic,strong) UIImage*       image;

@end

@implementation MBDraggingRule
+(instancetype) newWithRule:(LSDrawingRule *)rule size:(NSInteger)size {
    return [[self alloc] initWithRule: rule size: size];
}
-(instancetype)initWithRule:(LSDrawingRule *)rule size:(NSInteger)size {
    self = [super init];
    if (self) {
        _size = size;
        _rule = rule;
        [self configureView];
        [self configureImage];
    }
    return self;
}
-(void) configureView {
    if (_size > 0) {
        CGRect frame = CGRectMake(0, 0, _size, _size);
        CGFloat margin = 2.0;
        
        if (!_view) {
            _view = [[UIView alloc] initWithFrame: frame];
            _view.contentMode = UIViewContentModeScaleAspectFit;
            
            CALayer* outlineLayer = _view.layer;
            
            outlineLayer.borderWidth = 1.0;
            outlineLayer.cornerRadius = 4.0;
            outlineLayer.borderColor = [UIColor blueColor].CGColor;
            outlineLayer.shadowOpacity = 0.5;
            outlineLayer.shadowRadius = 3.0;
            outlineLayer.shadowOffset = CGSizeMake(3, 3);
            outlineLayer.masksToBounds = NO;
            outlineLayer.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent: 0.95].CGColor;
            //    outlineView.contentMode = UIViewContentModeCenter;
            _imageLayer = [[CALayer alloc] init];
            _imageLayer.contentsScale = outlineLayer.contentsScale;
            _imageLayer.frame = CGRectInset(frame, margin, margin);
            _imageLayer.contentsGravity = kCAGravityResizeAspect;
            [outlineLayer addSublayer: _imageLayer];
        }
        
    }
}
-(void) configureImage {
    if (_rule) {
        _image = [_rule asImage];
        if (_image) {
            _imageLayer.contents = (__bridge id)(_image.CGImage);
        }
    }
}
-(void) setRule:(LSDrawingRule *)rule {
    if (_rule != rule) {
        _rule = rule;
        [self configureImage];
    }
}
-(void) setSize:(CGFloat)size {
    if (_size != size) {
        CGFloat deltaSize = (_size - size)/2.0;
        _size = size;
        self.view.frame = CGRectInset(self.view.frame, deltaSize, deltaSize);
    }
}
-(void) setViewCenter:(CGPoint)viewCenter {
    self.view.center = CGPointMake(viewCenter.x + self.touchToDragViewOffset.x,
                                   viewCenter.y + self.touchToDragViewOffset.y);
}
-(CGPoint) viewCenter {
    return self.view.center;
}
-(UIImage*)asImage {
    return _image;
}
#pragma mark - Convenience Properties
-(BOOL) isAlreadyDropped {
    return (self.lastDestinationArray != nil);
}
#pragma mark - Dragging state changes
-(void) setLastTableIndexPath:(NSIndexPath *)lastTableIndexPath andResetRuleIfDifferent: (BOOL) reset notify: (id)object forPropertyChange:(NSString*)property {
    BOOL lastIsNotNil = _lastTableIndexPath != nil;
    BOOL newIsNotNil = lastTableIndexPath != nil;
    BOOL indexesBothNotNil = lastIsNotNil & newIsNotNil;
    BOOL onlyOneIsNotNil = lastIsNotNil ^ newIsNotNil;
    if (onlyOneIsNotNil || (indexesBothNotNil && [lastTableIndexPath compare: _lastTableIndexPath]!=NSOrderedSame)) {
        // Table index is different so all of the saved values are obsolete and lastDrop destination needs to be removed
        if (reset) {
            [self removePreviousDropRepresentationNotify: object forPropertyChange: property];
        }
    }
    self.lastTableIndexPath = lastTableIndexPath;
}
-(BOOL) moveRuleToArray: (id)aCollectionType indexPath:(NSIndexPath *)indexPath notify:(id)object forPropertyChange:(NSString *)property {
    BOOL resized = NO;
    
    NSMutableOrderedSet* strongLastDestinationArray = self.lastDestinationArray;
    UICollectionView* strongLastDestinationCollection = self.lastDestinationCollection;

    NSInteger lastCellRow = [strongLastDestinationCollection numberOfItemsInSection: 0] - 1;

    if (object!=nil && property != nil && property.length > 0) {
        [object willChangeValueForKey: property];
    }
    
    
    if (strongLastDestinationArray) { // need to move item
                                     //
        [strongLastDestinationArray exchangeObjectAtIndex: self.lastCollectionIndexPath.row withObjectAtIndex: indexPath.row];
        [strongLastDestinationCollection moveItemAtIndexPath: self.lastCollectionIndexPath toIndexPath: indexPath];
        
        self.lastCollectionIndexPath = indexPath;
        
    } else { // need to append or insert, growing number of items
        self.lastDestinationArray = aCollectionType;
        
        [aCollectionType insertObject: self.rule atIndex: indexPath.row];
        [strongLastDestinationCollection insertItemsAtIndexPaths: @[indexPath]];
        
        self.lastCollectionIndexPath = indexPath;
        CGFloat cellWidth = strongLastDestinationCollection.bounds.size.width;
        UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)strongLastDestinationCollection.collectionViewLayout;
        NSInteger itemsPerLine = (cellWidth / (layout.itemSize.width+2*layout.minimumInteritemSpacing));
        CGFloat remainder = fmodf(lastCellRow+1, itemsPerLine);
        if (remainder == 0.0) {
            // flag to relayout collection with additional row
            resized = YES;
        }
    }
    
    if (object!=nil && property != nil && property.length > 0) {
        [object didChangeValueForKey: property];
    }
    return resized;
}
-(void) removePreviousDropRepresentationNotify: (id)object forPropertyChange:(NSString*)property {

    NSMutableOrderedSet* strongLastDestinationArray = self.lastDestinationArray;
    UICollectionView* strongLastDestinationCollection = self.lastDestinationCollection;

    if (strongLastDestinationArray && self.lastCollectionIndexPath) {
        if (object!=nil && property != nil && property.length > 0) {
            [object willChangeValueForKey: property];
        }
        
        [strongLastDestinationArray removeObject: _rule];
        
        if (object!=nil && property != nil && property.length > 0) {
            [object didChangeValueForKey: property];
        }
        
        [strongLastDestinationCollection deleteItemsAtIndexPaths: @[self.lastCollectionIndexPath]];
    }
    [self resetDestination];
}

-(void) resetDestination {
    self.lastCollectionIndexPath = nil;
    self.lastDestinationCollection = nil;
    self.lastDestinationArray = nil;
    self.lastTableIndexPath = nil;
}
@end
