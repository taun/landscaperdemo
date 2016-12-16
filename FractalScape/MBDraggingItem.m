//
//  MBDraggingItem.m
//  FractalScape
//
//  Created by Taun Chapman on 10/09/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBDraggingItem.h"

@interface MBDraggingItem ()

@property (nonatomic,strong) CALayer*       imageLayer;
@property (nonatomic,strong) UIImage*       image;

@end

@implementation MBDraggingItem
+(instancetype) newWithItem:(id)representedObject size:(NSInteger)size {
    return [[self alloc] initWithItem: representedObject size: size];
}
- (instancetype)init
{
    return [self initWithItem: nil size: 0];
}
-(instancetype)initWithItem:(id)representedObject size:(NSInteger)size {
    self = [super init];
    if (self) {
        _size = size;
        _dragItem = representedObject;
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
    if (_dragItem) {
        _image = [_dragItem asImage];
        if (_image) {
            _imageLayer.contents = (__bridge id)(_image.CGImage);
        }
    }
}
-(void) setDragItem:(LSDrawingRule *)rule {
    if (_dragItem != rule) {
        _dragItem = rule;
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

@end
