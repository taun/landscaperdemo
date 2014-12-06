//
//  MDBColorCategoriesListView.m
//  FractalScape
//
//  Created by Taun Chapman on 12/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MDBColorCategoriesListView.h"
#import "MDBColorCategoryListView.h"
#import "NSLayoutConstraint+MDBAddons.h"
#import "FractalScapeIconSet.h"

@interface MDBColorCategoriesListView ()
@property (nonatomic,assign) CGRect                         lastBounds;
@end

@implementation MDBColorCategoriesListView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupDefaults];
        [self setupSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupDefaults];
        [self setupSubviews];
    }
    return self;
}

-(void) setupDefaults {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    
    _rowSpacing = 0.0;
    _tileWidth = 26.0;
    _tileMargin = 2.0;
}
-(void) setupSubviews {
    for (UIView* view in [self subviews]) {
        [view removeFromSuperview];
    }
    
    NSInteger lineNum = 0;
    
    NSInteger rrCount;
#if !TARGET_INTERFACE_BUILDER
    for (MBColorCategory* category in self.colorCategories) {
#else
        for (rrCount = 0; rrCount < 3; rrCount++) {
#endif
            
            CGRect rrFrame = CGRectMake(0, lineNum*_tileWidth, self.bounds.size.width, _tileWidth);
            MDBColorCategoryListView* newRR = [[MDBColorCategoryListView alloc] initWithFrame: rrFrame];
#if !TARGET_INTERFACE_BUILDER
            newRR.colorCategory = category;
#endif
            newRR.justify = _justify;
            newRR.tileMargin = _tileMargin;
            newRR.tileWidth = _tileWidth;
            newRR.showTileBorder = _showTileBorder;
            newRR.showOutline = NO;
            newRR.readOnly = _readOnly;
            
            [self addSubview: newRR];
            
            lineNum++;
#if !TARGET_INTERFACE_BUILDER
        }
#else
    }
#endif
    
    [self setNeedsUpdateConstraints];
}

-(void) updateConstraints {
    if (self.subviews.count > 0) {
        [self removeConstraints: self.constraints];
        
        
        NSInteger lineNumber;
        // anchor each line
        
        for (UIView* view in self.subviews) {
            //
            NSDictionary* viewsDictionary = NSDictionaryOfVariableBindings(view);
            [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options: 0 metrics: 0 views: viewsDictionary]];
        }
        
        [self addConstraints: [NSLayoutConstraint constraintsForFlowing: self.subviews
                                                       inContainingView: self
                                                         forOrientation: UILayoutConstraintAxisVertical
                                                            withSpacing: self.rowSpacing]];
        
    }
    
    [super updateConstraints];
}


#pragma mark - Setters & Getters
-(void) setColorCategories:(NSArray *)colorCategories {
    _colorCategories = colorCategories;
    
    [self setupSubviews];
}

-(void) setRowSpacing:(CGFloat)rowSpacing {
    _rowSpacing = rowSpacing;
    
    [self setNeedsUpdateConstraints];
}

-(void) setTileMargin:(CGFloat)tileMargin {
    _tileMargin = tileMargin;
    
    for (MDBColorCategoryListView* rrView in self.subviews) {
        rrView.tileMargin = _tileMargin;
    }
    
    [self setNeedsUpdateConstraints];
}

-(void) setTileWidth:(CGFloat)tileWidth {
    _tileWidth = tileWidth;
    
    for (MDBColorCategoryListView* rrView in self.subviews) {
        rrView.tileWidth = _tileWidth;
    }
    
    [self setNeedsUpdateConstraints];
}

-(void) setShowTileBorder:(BOOL)showTileBorder {
    _showTileBorder = showTileBorder;
    
    for (MDBColorCategoryListView* rrView in self.subviews) {
        rrView.showTileBorder = _showTileBorder;
    }
}
-(void) setShowOutline:(BOOL)showOutline {
    _showOutline = showOutline;
    
    if (_showOutline) {
        self.layer.borderWidth = 1.0;
        self.layer.cornerRadius = 6.0;
        self.layer.borderColor = [FractalScapeIconSet groupBorderColor].CGColor;
    } else {
        self.layer.borderWidth = 0.0;
    }
}
-(void) setJustify:(BOOL)justify {
    _justify = justify;
    
    for (MDBColorCategoryListView* rrView in self.subviews) {
        rrView.justify = _justify;
    }
    
    [self setNeedsUpdateConstraints];
}
-(void) setReadOnly:(BOOL)readOnly {
    _readOnly = readOnly;
    
    for (MDBColorCategoryListView* subview in self.subviews) {
        subview.readOnly = _readOnly;
    }
    
}

#pragma mark - Drag&Drop
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    UIView* dragView;
    
    return dragView;
}
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL needsLayout = NO;
    
    return needsLayout;
}

@end
