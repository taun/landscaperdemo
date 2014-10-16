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
-(void) setLastTableIndexPath:(NSIndexPath *)lastTableIndexPath andResetRuleIfDifferent: (BOOL) reset {
    if ([lastTableIndexPath compare: _lastTableIndexPath]!=NSOrderedSame) {
        // Table index is different so all of the saved values are obsolete and lastDrop destination needs to be removed
        if (reset) {
            [self removePreviousDropRepresentation];
        }
    }
    self.lastTableIndexPath = lastTableIndexPath;
}
-(void) removePreviousDropRepresentation {
    if (self.lastDestinationArray) {
        [self.lastDestinationArray removeObject: self];
        [self.lastDestinationCollection deleteItemsAtIndexPaths: @[self.lastCollectionIndexPath]];
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
