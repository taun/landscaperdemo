//
//  MDBColorCategoryListView.m
//  FractalScape
//
//  Created by Taun Chapman on 12/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MDBColorCategoryListView.h"
#import "MDBTileObjectProtocol.h"
#import "FractalScapeIconSet.h"


@interface MDBColorCategoryListView ()

@property (nonatomic,strong) MBLSObjectListTileViewer        *colorListView;
@property (nonatomic,assign) CGRect                         lastBounds;

@end

@implementation MDBColorCategoryListView

- (instancetype)initWithFrame:(CGRect)frame {
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
    //    self.contentMode = UIViewContentModeRedraw;
    
    _tileWidth = 26.0;
    _tileMargin = 2.0;
    
}
-(void)setColorCategory:(MBColorCategory *)colorCategory {
    _colorCategory = colorCategory;
    [self setupSubviews];
}
-(void) setupSubviews {
    for (UIView* view in [self subviews]) {
        [view removeFromSuperview];
    }
    
    
    _categoryLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, _tileWidth, _tileWidth)];
    NSString* category = _colorCategory.name;
    if (category == nil || category.length == 0) {
        category = @"Category";
    }
    _categoryLabel.text = category;
    _categoryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview: _categoryLabel];
    
    
    CGRect replacementRect = CGRectMake(_tileWidth*3, 0, _tileWidth*50, _tileWidth*2);
    _colorListView = [[MBLSObjectListTileViewer alloc] initWithFrame: replacementRect];
    _colorListView.justify = _justify;
    _colorListView.showTileBorder = _showTileBorder;
    _colorListView.tileWidth = _tileWidth;
    _colorListView.tileMargin = _tileMargin;
    _colorListView.readOnly = _readOnly;
    
#if !TARGET_INTERFACE_BUILDER
    _colorListView.objectList = [self.colorCategory.colors mutableCopy];
#endif
    
    [self addSubview: _colorListView];
}

-(void) updateConstraints {
    [self removeConstraints: self.constraints];
    
    self.lastBounds = self.bounds;
    
    NSDictionary* adjacentViewsDictionary = NSDictionaryOfVariableBindings(_categoryLabel,_colorListView);
    
    NSDictionary* metricsDictionary = @{@"width":@(_tileWidth*0.2)};
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-6-[_colorListView]-6-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
    //    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_ruleView(60)]-70-[_separator(30)]-[_replacementsView(200)]-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
    //    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_ruleView]-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
    //    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_separator]-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[_categoryLabel]-[_colorListView]-6-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem: _categoryLabel
                                                      attribute: NSLayoutAttributeCenterX
                                                      relatedBy: NSLayoutRelationEqual
                                                         toItem: self
                                                      attribute: NSLayoutAttributeCenterX
                                                     multiplier: 1.0
                                                       constant: 0.0]];
    
    [_colorListView setContentHuggingPriority: UILayoutPriorityDefaultLow - 1 forAxis: UILayoutConstraintAxisHorizontal];
    [_colorListView setContentCompressionResistancePriority: UILayoutPriorityFittingSizeLevel forAxis: UILayoutConstraintAxisHorizontal];
    [_colorListView setNeedsUpdateConstraints];
    
    [super updateConstraints];
}
-(void) layoutSubviews {
    [super layoutSubviews];
    
    if (!CGRectEqualToRect(self.bounds, self.lastBounds)) {
        //
        [self setNeedsUpdateConstraints];
    }
    
}
-(void) setTileMargin:(CGFloat)tileMargin {
    _tileMargin = tileMargin;
    _colorListView.tileMargin = _tileMargin;
    
    [self setNeedsUpdateConstraints];
}

-(void) setTileWidth:(CGFloat)tileWidth {
    _tileWidth = tileWidth;
    _colorListView.tileWidth = _tileWidth;
    
    [self setNeedsUpdateConstraints];
}

-(void) setShowTileBorder:(BOOL)showTileBorder {
    _showTileBorder = showTileBorder;
    //    _ruleView.showTileBorder = _showTileBorder;
    _colorListView.showTileBorder = _showTileBorder;
    
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
    _colorListView.justify = _justify;
    
    [self setNeedsUpdateConstraints];
}
-(void) setReadOnly:(BOOL)readOnly {
    _readOnly = readOnly;
    
    self.colorListView.readOnly = _readOnly;
}

#pragma mark - Drag&Drop Implementation Details

#pragma mark - Drag&Drop
-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    UIView* dragView;
    
    return dragView;
}
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    
    return needsLayout;
}
-(BOOL) dragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    
    return needsLayout;
}
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
#pragma message "TODO: fix for uidocument"
    //
    id<MDBTileObjectProtocol> color = draggingItem.oldReplacedDragItem;
//    if (color && !color.isReferenced) {
//        draggingItem.oldReplacedDragItem = nil;
//        if ([color isKindOfClass: [NSManagedObject class]]) {
//            [((NSManagedObject*)color).managedObjectContext deleteObject: color];
//        }
//    }
    
    return needsLayout;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingItem {
    BOOL needsLayout = NO;
    
    return needsLayout;
}


@end
