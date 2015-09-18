//
//  MDBImageFiltersListView.m
//  FractalScapes
//
//  Created by Taun Chapman on 04/12/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBImageFiltersListView.h"

#import "MBImageFilter.h"
#import "MDBFractalObjectList.h"
#import "NSLayoutConstraint+MDBAddons.h"
#import "FractalScapeIconSet.h"

@import CoreImage;

@interface MDBImageFiltersListView ()

@property (nonatomic,strong) MBLSObjectListTileViewer        *filtersListView;
@property (nonatomic,assign) CGRect                         lastBounds;

@end

@implementation MDBImageFiltersListView

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
-(void)setFilterCategory:(NSString *)filterCategory {
    _filterCategory = filterCategory;
    [self setupSubviews];
}
-(void) setupSubviews {
    for (UIView* view in [self subviews]) {
        [view removeFromSuperview];
    }
    
    
    _categoryLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, _tileWidth, _tileWidth)];
    
    NSString* category = [[NSBundle mainBundle] localizedStringForKey: _filterCategory value: _filterCategory table: nil];
//    if (category == nil || category.length == 0) {
//        category = @"Filter";
//    }
    _categoryLabel.text = category;
    _categoryLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview: _categoryLabel];
    
    
    CGRect replacementRect = CGRectMake(_tileWidth*3, 0, _tileWidth*50, _tileWidth*2);
    _filtersListView = [[MBLSObjectListTileViewer alloc] initWithFrame: replacementRect];
    _filtersListView.justify = _justify;
    _filtersListView.showTileBorder = _showTileBorder;
    _filtersListView.tileWidth = _tileWidth;
    _filtersListView.tileMargin = _tileMargin;
    _filtersListView.readOnly = _readOnly;
    
    MDBFractalObjectList* objectList = [MDBFractalObjectList new];
    if (_filterCategory)
    {
        @autoreleasepool
        {
            NSSet* filtersToIgnore = [NSSet setWithObjects: @"CIStretchCrop", @"CIGlassDistortion", @"CIGlassLozenge", @"CIDisplacementDistortion", nil];

            NSArray* filters = [CIFilter filterNamesInCategory: _filterCategory];
            for (NSString* filterName in filters)
            {
                if ([filtersToIgnore containsObject: filterName]) continue;
                
                MBImageFilter* newFilter = [MBImageFilter newFilterWithIdentifier: filterName];
                //            [newFilter.inputValues addEntriesFromDictionary: @{kCIInputAngleKey:[NSNumber numberWithFloat: self.fractal.turningAngle]}];
                [objectList addObject: newFilter];
            }
        }
    }
    
    
#if !TARGET_INTERFACE_BUILDER
    _filtersListView.objectList = objectList;
#endif
    
    [self addSubview: _filtersListView];
}

-(void) updateConstraints {
    [self removeConstraints: self.constraints];
    
    self.lastBounds = self.bounds;
    
    NSDictionary* adjacentViewsDictionary = NSDictionaryOfVariableBindings(_categoryLabel,_filtersListView);
    
    NSDictionary* metricsDictionary = @{@"width":@(_tileWidth*0.2)};
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-6-[_filtersListView]-6-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
    //    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[_ruleView(60)]-70-[_separator(30)]-[_replacementsView(200)]-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
    //    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_ruleView]-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
    //    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_separator]-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-6-[_categoryLabel]-[_filtersListView]-6-|" options: 0 metrics: metricsDictionary views: adjacentViewsDictionary]];
    
    [self addConstraint: [NSLayoutConstraint constraintWithItem: _categoryLabel
                                                      attribute: NSLayoutAttributeCenterX
                                                      relatedBy: NSLayoutRelationEqual
                                                         toItem: self
                                                      attribute: NSLayoutAttributeCenterX
                                                     multiplier: 1.0
                                                       constant: 0.0]];
    
    [_filtersListView setContentHuggingPriority: UILayoutPriorityDefaultLow - 1 forAxis: UILayoutConstraintAxisHorizontal];
    [_filtersListView setContentCompressionResistancePriority: UILayoutPriorityFittingSizeLevel forAxis: UILayoutConstraintAxisHorizontal];
    [_filtersListView setNeedsUpdateConstraints];
    
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
    _filtersListView.tileMargin = _tileMargin;
    
    [self setNeedsUpdateConstraints];
}

-(void) setTileWidth:(CGFloat)tileWidth {
    _tileWidth = tileWidth;
    _filtersListView.tileWidth = _tileWidth;
    
    [self setNeedsUpdateConstraints];
}

-(void) setShowTileBorder:(BOOL)showTileBorder {
    _showTileBorder = showTileBorder;
    //    _ruleView.showTileBorder = _showTileBorder;
    _filtersListView.showTileBorder = _showTileBorder;
    
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
    _filtersListView.justify = _justify;
    
    [self setNeedsUpdateConstraints];
}
-(void) setReadOnly:(BOOL)readOnly {
    _readOnly = readOnly;
    
    self.filtersListView.readOnly = _readOnly;
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
//    id<MDBTileObjectProtocol> color = draggingItem.oldReplacedDragItem;
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
