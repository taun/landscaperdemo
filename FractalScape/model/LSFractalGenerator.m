//
//  LSFractalGenerator.m
//  FractalScape
//
//  Created by Taun Chapman on 01/19/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "LSFractalGenerator.h"
#import "LSFractal+addons.h"
#import "MBColor+addons.h"
#import "MBFractalSegment.h"
#import "LSReplacementRule+addons.h"
#import "LSDrawingRuleType+addons.h"
#import "LSDrawingRule+addons.h"

#import <QuartzCore/QuartzCore.h>

#define MAXPRODUCTLENGTH 200000

#define SHOWDEBUGBORDER 0

@interface LSFractalGenerator () {
    double _maxLineWidth;
}
@property (nonatomic,strong) NSManagedObjectID      *fractalID;
@property (nonatomic,strong) NSManagedObjectContext *parentObjectContext;
@property (nonatomic,strong) NSManagedObjectContext *privateObjectContext;
@property (nonatomic,strong) LSFractal              *privateFractal;

@property (nonatomic,strong) NSMutableString*       production;
@property (nonatomic,assign) BOOL                   productNeedsGenerating;
@property (nonatomic,assign) BOOL                   pathNeedsGenerating;

//@property (nonatomic,strong) LSGeneratorStack       *stack;
//@property (nonatomic,strong) MBFractalSegment*      currentSegment;
@property (nonatomic,strong) NSMutableArray*        currentSegmentList;
@property (nonatomic,strong) NSMutableArray*        finishedSegments;
@property (nonatomic,strong) NSMutableArray*        segmentStack;

@property (nonatomic,assign,readwrite) CGRect       bounds;
@property (nonatomic,strong) NSMutableDictionary*   cachedDrawingRules;
@property (nonatomic,strong) NSArray*               cachedLineColors;
@property (nonatomic,strong) NSArray*               cachedFillColors;
@property (nonatomic,strong) UIColor*               defaultColor;

@property (nonatomic,assign) BOOL                   cachedEoFill;



@property (nonatomic,strong) UIImage*               cachedImage;
@property (nonatomic,strong) NSMutableDictionary*   cachedSelectors;

-(void) startNewSegment;
-(void) pushSegment;
-(void) popSegment;
-(void) addFinishedSegment: (MBFractalSegment*) segment;
-(void) finalizeSegments;

-(void) dispatchDrawingSelectorFromString:(NSString*)selector;
-(void) evaluateRule: (NSString*) rule;

-(void) addObserverForFractal: (LSFractal*)fractal;
-(void) removeObserverForFractal: (LSFractal*)fractal;
-(void) generateProduct;
-(void) generatePaths;

-(void) cacheColors: (LSFractal*)fractal;
-(void) cacheLineEnds: (LSFractal*)fractal;
@end

#pragma mark - Implementation

@implementation LSFractalGenerator

@synthesize fractalCGPathRef = _fractalCGPathRef;

- (instancetype)init {
    self = [super init];
    if (self) {

        _productNeedsGenerating = YES;
        _pathNeedsGenerating = YES;
        _forceLevel = -1.0;
        _scale = 1.0;
        _autoscale = YES;
        _translate = CGPointMake(0.0, 0.0);
        _bounds = CGRectZero;
        _defaultColor = [UIColor blueColor];
    }
    return self;
}

- (void) dealloc {
    // removes observer
    self.fractal = nil;
}

#pragma mark Fractal Property KVO
/* If fractal is not save, below will return nil for privateFractal. What to do? */
-(void) setFractal:(LSFractal *)fractal {
    if (_fractal != fractal) {
        
        [self removeObserverForFractal: _fractal];
        
        _fractal = fractal;
        
        self.fractalID = _fractal.objectID;
        self.privateObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
        self.privateObjectContext.parentContext = _fractal.managedObjectContext;

        [self cacheColors: _fractal];
        [self cacheLineEnds: _fractal];
        
        [self addObserverForFractal: _fractal];
        [self productionRuleChanged];
    }
}
/* will this cause threading problems? */
-(void) addObserverForFractal:(LSFractal *)fractal {
    if (fractal) {
        [fractal.managedObjectContext performBlock:^{
            
            NSMutableSet* propertiesToObserve = [NSMutableSet setWithSet: [LSFractal productionRuleProperties]];
            [propertiesToObserve unionSet: [LSFractal appearanceProperties]];
            [propertiesToObserve unionSet: [LSFractal redrawProperties]];
            
            for (NSString* keyPath in propertiesToObserve) {
                [fractal addObserver: self forKeyPath:keyPath options: 0 context: NULL];
            }
                        
            for (LSReplacementRule* rRule in fractal.replacementRules) {
                [rRule addObserver: self forKeyPath: [LSReplacementRule contextRuleKey] options: 0 context: NULL];
                [rRule addObserver: self forKeyPath: [LSReplacementRule rulesKey] options: 0 context: NULL];
            }
        }];
    }
}
-(void) removeObserverForFractal:(LSFractal *)fractal {
    if (fractal) {
        [fractal.managedObjectContext performBlock:^{
            
            NSMutableSet* propertiesToObserve = [NSMutableSet setWithSet: [LSFractal productionRuleProperties]];
            [propertiesToObserve unionSet: [LSFractal appearanceProperties]];
            [propertiesToObserve unionSet: [LSFractal redrawProperties]];
            
            for (NSString* keyPath in propertiesToObserve) {
                [fractal removeObserver: self forKeyPath: keyPath];
            }
            
            for (LSReplacementRule* rule in fractal.replacementRules) {
                [rule removeObserver: self forKeyPath: [LSReplacementRule contextRuleKey]];
                [rule removeObserver: self forKeyPath: [LSReplacementRule rulesKey]];
            }
        }];
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([[LSFractal productionRuleProperties] containsObject: keyPath] ||
        [keyPath isEqualToString: [LSReplacementRule rulesKey]] ||
        [keyPath isEqualToString: [LSReplacementRule contextRuleKey]]) {
        // productionRuleChanged
        [self productionRuleChanged];
        [self cacheColors: _fractal];
        [self cacheLineEnds: _fractal];
        
    } else if ([[LSFractal appearanceProperties] containsObject: keyPath]) {
        // appearanceChanged
        [self geometryChanged];
        [self cacheColors: _fractal];
        [self cacheLineEnds: _fractal];
        
    } else if ([[LSFractal redrawProperties] containsObject: keyPath]) {
        [self cacheColors: _fractal];
        [self cacheLineEnds: _fractal];
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

/*
 <CALayer:0x6d6b0c0; position = CGPoint (578.5 110.5); bounds = CGRect (0 0; 369 211); delegate = <LSFractalGenerator: 0x6d6bd30>; borderWidth = 1; cornerRadius = 20; backgroundColor = <CGColor 0x6d6b260> [<CGColorSpace 0x6d38c80> (kCGColorSpaceDeviceRGB)] ( 1 1 1 1 )>
 */
-(NSString*) debugDescription {
    CFDictionaryRef boundsDict = CGRectCreateDictionaryRepresentation(_bounds);
    NSString* boundsDescription = [(__bridge NSDictionary*)boundsDict description];
    CFRelease(boundsDict);
    
    return [NSString stringWithFormat: @"<%@: fractal = %@; forceLevel = %g; bounds = %@; production = %@>",
            NSStringFromClass([self class]), 
            self.fractal, 
            self.forceLevel, 
            boundsDescription,
            self.production];
}
#pragma mark - layer delegate
/*!
 Transforms note:
 The transforms are the reverse of what I would expect.
 Calling a translate transform then scale transform seems to apply the transform to the data points as a scale then translate.
 
 Example point at 100@100
 Translate -50@-50 then scale x2 should be point at 100@100 actual point seems to be 150@150
 Scale x2 then translate -50@-50 results in 50@50, the desired location.
 
 Transforms seem to be stacked then applied as they are pulled off the stack. LIFO.
 */
- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext {
    CGRect tempRect = theLayer.bounds;
    CGRect layerBounds = CGRectMake(tempRect.origin.x, tempRect.origin.y, tempRect.size.width, tempRect.size.height);
    [self drawInBounds: layerBounds withContext: theContext flipped: [theLayer contentsAreFlipped]];
}
/*!
 Can be called in a private thread, operation.

 @param size
 @param uiColor
 
 @return
 */
-(UIImage*) generateImageSize:(CGSize)size withBackground:(UIColor*)uiColor {
    if (self.productNeedsGenerating || self.pathNeedsGenerating || (self.cachedImage == nil) || !CGSizeEqualToSize(self.cachedImage.size, size)) {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        CGRect viewRect = CGRectMake(0, 0, size.width, size.height);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        NSAssert(context, @"NULL Context being used. Context must be non-null.");
        MBColor* pageColor = self.fractal.backgroundColor;
        if (pageColor) {
            uiColor = [pageColor asUIColor];
        }
        
        CGContextSaveGState(context);
        UIColor* thumbNailBackground = [UIColor colorWithCGColor: uiColor.CGColor];
        [thumbNailBackground setFill];
        CGContextFillRect(context, viewRect);
        CGContextRestoreGState(context);
        
        [self drawInBounds: viewRect
               withContext: context
                   flipped: NO];
        
        UIImage* thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.cachedImage = thumbnail;
    }
    return self.cachedImage;
}
-(BOOL)hasImageSize:(CGSize)size {
    BOOL status = YES;
    if ([self productNeedsGenerating] || (self.cachedImage == nil) || !CGSizeEqualToSize(self.cachedImage.size, size)) {
        status = NO;
    }
    return status;
}
/*!
 Can be called in a private thread, operation
 
 @param layerBounds
 @param theContext
 @param isFlipped
 */
-(void) drawInBounds:(CGRect)layerBounds withContext:(CGContextRef)theContext flipped:(BOOL)isFlipped {

    
    // Following is because layerBounds value disappears after 1st if statement line below.
    // cause totally unknown.
    CGRect localBounds = layerBounds;
    
    if (self.productNeedsGenerating || self.pathNeedsGenerating) {
        [self.privateObjectContext performBlockAndWait:^{
        
            [self.privateObjectContext reset];
            self.privateFractal = (LSFractal*)[self.privateObjectContext objectWithID: self.fractalID];
//            [self.privateObjectContext refreshObject: self.privateFractal mergeChanges: NO];
            
            if (self.productNeedsGenerating) {
                [self generateProduct];
            }
            if (self.pathNeedsGenerating) {
                [self generatePaths];
            }
            
        }];
    }
    

    CGContextSaveGState(theContext);
    
    if (SHOWDEBUGBORDER) {
        // outline the layer bounding box
        CGContextBeginPath(theContext);
        CGContextAddRect(theContext, localBounds);
        CGContextSetLineWidth(theContext, 1.0);
        CGContextSetRGBStrokeColor(theContext, 0.5, 0.0, 0.0, 0.1);
        CGContextStrokePath(theContext);
        
        // move 0,0 down to the bottom left corner
        CGContextTranslateCTM(theContext, localBounds.origin.x, localBounds.origin.y + localBounds.size.height);
        // flip the Y axis so +Y is up direction from origin
        if (isFlipped) {
            //CGContextConcatCTM(ctx, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
            CGContextScaleCTM(theContext, 1.0, -1.0);
        }
        
        // put a small square at the origin
        CGContextBeginPath(theContext);
        CGContextAddRect(theContext, CGRectMake(0, 0, 10, 10));
        CGContextSetLineWidth(theContext, 2.0);
        CGContextSetRGBStrokeColor(theContext, 0.5, 0.0, 0.4, 0.1);
        CGContextStrokePath(theContext);
        
        CGContextRestoreGState(theContext);
    }
    
    CGContextSaveGState(theContext);
    
    //    NSDictionary* lboundsDict = (__bridge NSDictionary*) CGRectCreateDictionaryRepresentation(bounds);
    //    NSLog(@"Layer Bounds = %@", lboundsDict);
    
    //    NSDictionary* boundsDict = (__bridge NSDictionary*) CGRectCreateDictionaryRepresentation(self.bounds);
    //    NSLog(@"Fractal Path Bounds = %@", boundsDict);
    
    //    NSLog(@"Layer anchor point: %g@%g", theLayer.anchorPoint.x, theLayer.anchorPoint.y);
    
    if (self.autoscale) {
        // Scaling
        double scaleWidth = localBounds.size.width/self.bounds.size.width;
        double scaleHeight = localBounds.size.height/self.bounds.size.height;
        
        self.scale = MIN(scaleHeight, scaleWidth);
        
        //    double margin = -0.0/scale;
        
        //    CGContextScaleCTM(theContext, scale, scale);
        //    NSLog(@"Min Layer/Fractal Scale = %g", scale);
        
        
        //    CGRect fBounds = CGRectStandardize(CGRectInset(self.bounds, margin, margin) );
        
        // Translating
        double fCenterX = (self.bounds.origin.x + self.bounds.size.width/2.0);
        double fCenterY = (self.bounds.origin.y + self.bounds.size.height/2.0);
        
        double lCenterX = localBounds.origin.x + localBounds.size.width/2.0;
        double lCenterY = localBounds.origin.y + localBounds.size.height/2.0;
        
        self.translate = CGPointMake(lCenterX - (fCenterX*self.scale), lCenterY - (fCenterY*self.scale));
    }
    
    CGContextTranslateCTM(theContext, self.translate.x, self.translate.y);
    
    CGContextScaleCTM(theContext, self.scale, self.scale);
    
    //    NSLog(@"Translation FCenter = %g@%g; LCenter = %g@%g; tx = %g; ty = %g",
    //          fCenterX, fCenterY, lCenterX, lCenterY, tx, ty);
//    CGRect localBounds = self.fractalLevelNLayer.bounds;
    
//    CGAffineTransform pathTransform = CGAffineTransformIdentity;
//    CGPointMake(localBounds.origin.x, localBounds.origin.y + localBounds.size.height);

    CGMutablePathRef fractalPath = CGPathCreateMutable();
//    CGPathMoveToPoint(fractalPath, NULL, localBounds.origin.x, localBounds.origin.y + localBounds.size.height);

    for (MBFractalSegment* segment in self.finishedSegments) {
        // stroke and or fill each segment
        CGContextBeginPath(theContext);
        
        
        //        NSDictionary* aboundsDict = (__bridge NSDictionary*) CGRectCreateDictionaryRepresentation(CGPathGetBoundingBox(segment.path));
        //        NSLog(@"Actual segment bounds = %@", aboundsDict);
        
        // Scale the lineWidth to compensate for the overall scaling
        //        CGContextSetLineWidth(ctx, segment.lineWidth);
//        CGContextSetLineWidth(theContext, segment.lineWidth/self.scale);
        
        CGContextSetLineCap(theContext, segment.lineCap);
        CGContextSetLineJoin(theContext, segment.lineJoin);
        CGContextSetLineWidth(theContext, segment.lineWidth);
        
        CGAffineTransform ctm = CGContextGetCTM(theContext);
        CGAffineTransformScale(ctm, 1.0, -1.0);
        CGContextAddPath(theContext, segment.path);
        CGPathAddPath(fractalPath, &ctm, segment.path);
        
        CGPathDrawingMode strokeOrFill = kCGPathStroke;
        if (segment.fill && segment.stroke) {
            if (self.cachedEoFill) {
                strokeOrFill = kCGPathEOFillStroke;
            } else {
                strokeOrFill = kCGPathFillStroke;
            }
            CGContextSetStrokeColorWithColor(theContext, [[self colorForIndex: segment.lineColorIndex inArray: self.cachedLineColors] CGColor]);
            CGContextSetFillColorWithColor(theContext, [[self colorForIndex: segment.fillColorIndex inArray: self.cachedFillColors] CGColor]);
        } else if (segment.stroke) {
            strokeOrFill = kCGPathStroke;
            CGContextSetStrokeColorWithColor(theContext, [[self colorForIndex: segment.lineColorIndex inArray: self.cachedLineColors] CGColor]);
        } else if (segment.fill) {
            if (self.cachedEoFill) {
                strokeOrFill = kCGPathEOFill;
            } else {
                strokeOrFill = kCGPathFill;
            }
            CGContextSetFillColorWithColor(theContext, [[self colorForIndex: segment.fillColorIndex inArray: self.cachedFillColors] CGColor] );
        }
        CGContextDrawPath(theContext, strokeOrFill);
    }

    self.fractalCGPathRef = fractalPath;
    CGPathRelease(fractalPath);
    
    CGContextRestoreGState(theContext);
}
-(UIColor*) colorForIndex: (NSInteger)index inArray: (NSArray*) colorArray {
    double count = (double)colorArray.count;
    if (count == 0.0) {
        return self.defaultColor;
    }
    
    NSInteger moddedIndex = (NSInteger)fabs(fmod((double)index, count));

    MBColor* mbColor = colorArray[moddedIndex];

    UIColor* newColor;
    
    if (!mbColor) {
        newColor = self.defaultColor;
    } else {
        newColor = [mbColor asUIColor];
    }
    
    return newColor;
}

#pragma mark - lazy init getters

-(NSMutableArray*) segmentStack {
    if (_segmentStack == nil) _segmentStack = [[NSMutableArray alloc] initWithCapacity: 1];
    
    return _segmentStack;
}
-(NSMutableArray*) currentSegmentList {
    if (_currentSegmentList == nil) {
        _currentSegmentList = [[NSMutableArray alloc] initWithCapacity: 1];
    }
    return _currentSegmentList;
}
-(MBFractalSegment*) currentSegment {
    if (!_currentSegmentList || _currentSegmentList.count == 0) {
        
        MBFractalSegment* newSegment = [MBFractalSegment new];
        
        // Copy the fractal core data values to the segment
        
        newSegment.lineColorIndex = 0;
        newSegment.fillColorIndex = 0;
        
        newSegment.lineLength = [self.privateFractal lineLengthAsDouble];
        newSegment.lineLengthScaleFactor = [self.privateFractal.lineLengthScaleFactor doubleValue];
        
        newSegment.lineWidth = [self.privateFractal.lineWidth doubleValue];
        newSegment.lineWidthIncrement = [self.privateFractal.lineWidthIncrement doubleValue];
        
        newSegment.turningAngle = [self.privateFractal turningAngleAsDouble];
        newSegment.turningAngleIncrement = [self.privateFractal.turningAngleIncrement doubleValue];
        
        newSegment.randomness = [self.privateFractal.randomness doubleValue];
        newSegment.lineChangeFactor = [self.privateFractal.lineChangeFactor doubleValue];
        
        [self.currentSegmentList addObject: newSegment];
    }
    return [self.currentSegmentList lastObject];
}
/*!
 Needs to only be called from the main thread or passed the privateFractal on the privateFractal thread.
 If called on the private thread, what happens with the private thread colors.
 
 @param fractal the fractal with the colors to be cached.
 */
#pragma message "TODO: change this to just cache the UIColors rather than MBColors to avoid thread problems?"
-(void) cacheColors: (LSFractal*)fractal {
    _cachedLineColors = [fractal.lineColors array];
    _cachedFillColors = [fractal.fillColors array];
}
-(void) cacheLineEnds: (LSFractal*)fractal {
    _cachedEoFill = fractal.eoFill ? [fractal.eoFill boolValue] : NO;
}
-(NSMutableDictionary*) cachedDrawingRules {
    if (_cachedDrawingRules == nil) {
        
        NSOrderedSet* rules = self.privateFractal.drawingRulesType.rules;
        NSUInteger ruleCount = [rules count];
        NSMutableDictionary* tempDict = [[NSMutableDictionary alloc] initWithCapacity: ruleCount];
        
        for (LSDrawingRule* rule in rules) {
            tempDict[rule.productionString] = rule.drawingMethodString;
        }
        
        _cachedDrawingRules = tempDict;
    }
    return _cachedDrawingRules;
}

-(void) clearCache {
    self.cachedDrawingRules = nil;
    self.cachedImage = nil;
}

-(NSMutableDictionary*) cachedSelectors {
    if (!_cachedSelectors) {
        _cachedSelectors = [NSMutableDictionary dictionaryWithCapacity: 30];
    }
    return _cachedSelectors;
}

-(CGRect) bounds {
    // adjust for the lineWidth
    double margin = _maxLineWidth*2.0+1.0;
    CGRect result = CGRectInset(_bounds, -margin, -margin);
    return result;
//    return _bounds;
}

//-(void) setBounds:(CGRect)bounds {
//    _bounds = bounds;
//}

#pragma mark segment getter setters
-(CGPathRef) fractalCGPathRef {
    if (_fractalCGPathRef == NULL) {
        _fractalCGPathRef = CGPathCreateMutable();
    }
    return _fractalCGPathRef;
}

-(void) setFractalCGPathRef:(CGPathRef)path {
    if (CGPathEqualToPath(_fractalCGPathRef, path)) return;
    
    CGPathRelease(_fractalCGPathRef);
    if (path != NULL) {
        _fractalCGPathRef = (CGMutablePathRef) CGPathRetain(path);
    }
}

#pragma mark segment methods
-(void) startNewSegment {
    MBFractalSegment* newCurrentSegment = [[self.currentSegmentList lastObject] copySettings];
    [self.currentSegmentList addObject: newCurrentSegment];
}
/*!
 Should always be an initial current segment.
 Push the currentSegment
 Create a new currentSegment copying the old segments settings
 */
-(void) pushSegment {
    MBFractalSegment* newCurrentSegment = [[self.currentSegmentList lastObject] copySettings];
    [self.segmentStack addObject: self.currentSegmentList];
    self.currentSegmentList = nil; // force a new lazy list to be created
    
    [self.currentSegmentList addObject: newCurrentSegment];
}

/*!
 Check to make sure there is a segment on the stack
 Move the current segment to the final segments array
 */
-(void) popSegment {
    if ([self.segmentStack count]>0) {
        
        // add currentSegments to path
        for (MBFractalSegment* currentSegment in self.currentSegmentList) {
            [self addFinishedSegment: currentSegment];
        }
        
        // restore popped segments
        self.currentSegmentList = [self.segmentStack lastObject];
        
        [self.segmentStack removeLastObject];
    }
}

/*!
 Move the currentSegment to the segments array.
 Check to see if there are any segments left on the stack and move them.
 */
-(void) finalizeSegments {
    for (MBFractalSegment* segment in self.currentSegmentList) {
        [self addFinishedSegment: segment];
    }
    
    if (_segmentStack != nil) {
        // Copy segmentStack so it does not mutate during iteration.
        NSArray* localSegmentStackCopy = [self.segmentStack copy];
        for (NSArray* segmentList in [localSegmentStackCopy copy]) {
            for (MBFractalSegment* segment in segmentList) {
                [self addFinishedSegment: segment];
                [self.segmentStack removeObject: segment];
            }
        }
    }
}

-(void) addFinishedSegment: (MBFractalSegment*) segment {
    CGRect tempBounds = CGRectZero;
    
    if (_finishedSegments == nil) {
        _finishedSegments = [[NSMutableArray alloc] initWithCapacity: 2];
        
        // intiallize the bounds to the first segment
        tempBounds = CGPathGetBoundingBox(segment.path);
        self.bounds = CGRectEqualToRect(tempBounds, CGRectNull) ? CGRectZero : tempBounds;
    } else {
        tempBounds = CGRectUnion(_bounds, CGPathGetBoundingBox(segment.path));
        self.bounds = CGRectEqualToRect(tempBounds, CGRectNull) ? CGRectZero : tempBounds;
    }
    _maxLineWidth = MAX(_maxLineWidth, segment.lineWidth);
    [_finishedSegments addObject: segment];
}


#pragma mark Custom Getter Setters

-(void) setProductNeedsGenerating:(BOOL)productNeedsGenerating {
    _productNeedsGenerating = productNeedsGenerating;
    if (productNeedsGenerating) {
        self.production = nil;
        // path needs to be regenerated whenever the product changes
        // this is redundant since the end of the product generation method sets the pathNeedsGenerating flag.
        self.pathNeedsGenerating = YES;
    }
}

-(void) setPathNeedsGenerating:(BOOL)pathNeedsGenerating {
    _pathNeedsGenerating = pathNeedsGenerating;
    if (_pathNeedsGenerating) {
        for (MBFractalSegment* segment in _currentSegmentList) {
            [segment setPath: NULL];
        }
        [_currentSegmentList removeAllObjects];
        _currentSegmentList = nil;

        for (MBFractalSegment* segment in _finishedSegments) {
            [segment setPath: NULL];
        }
        [_finishedSegments removeAllObjects];
        _finishedSegments = nil;

        for (NSArray* segmentArray in _segmentStack) {
            for (MBFractalSegment* segment in segmentArray) {
                [segment setPath: NULL];
            }
        }
        [_segmentStack removeAllObjects];
        _segmentStack = nil;
    }
}

//-(void) setInitialTransform:(CGAffineTransform)transform {
//    self.currentSegment.transform = transform;
//}

//-(CGAffineTransform) currentTransform {
//    return _currentTransform;
//}
//
//-(void) setCurrentTransform:(CGAffineTransform)currentTransform {
//    
//}


#pragma mark Product Generation

-(void) productionRuleChanged {
    self.productNeedsGenerating = YES;
}
#pragma message "TODO convert from NSString to NSData"
//TODO convert this to GCD, one dispatch per axiom character? Then reassemble?
//TODO static var for max product length and way to flag max reached.
/*!
 Evaluates the production rules for each generation.
 */
-(void) generateProduct {
    //estimate the length
    
    NSMutableDictionary* localReplacementRules;
    NSMutableString* sourceData;
    NSInteger productionLength;
    double localLevel;
    
    localLevel = [self.privateFractal.level doubleValue];
    if (self.forceLevel >= 0) {
        localLevel = self.forceLevel;
    }
    
    productionLength = [self.privateFractal.startingRules count] * localLevel;
    
    sourceData = [[NSMutableString alloc] initWithCapacity: productionLength];
    [sourceData appendString: self.privateFractal.startingRulesString];
    
    // Create a local dictionary version of the replacement rules
    localReplacementRules = [[NSMutableDictionary alloc] initWithCapacity: [self.privateFractal.replacementRules count]];
    for (LSReplacementRule* replacementRule in self.privateFractal.replacementRules) {
        localReplacementRules[replacementRule.contextRule.productionString] = replacementRule.rulesString;
    }
    
    NSMutableString* destinationData = [[NSMutableString alloc] initWithCapacity: productionLength];
    NSMutableString* tempData = nil;
    
    
    for (int i = 0; i < localLevel ; i++) {
        NSUInteger sourceLength = sourceData.length;
        if (sourceLength > MAXPRODUCTLENGTH) {
            break;
        }
        
        NSString* key;
        NSString* replacement;
        
        
        // Replace each character for this level
        for (int y=0; y < sourceLength; y++) {
            //
            key = [sourceData substringWithRange: NSMakeRange(y, 1)];
            
            replacement = localReplacementRules[key];
            // If a specific rule is missing for a character, use the character
            if (replacement==nil) {
                replacement = key;
            } else {
//                replacement = [NSString stringWithFormat: @"[%@]", replacement];
            }
            [destinationData appendString: replacement];
        }
        //swap source and destination
        tempData = sourceData;
        sourceData = destinationData;
        destinationData = tempData;
        //zero out destination
        [destinationData deleteCharactersInRange: NSMakeRange(0, destinationData.length)];
    }
    
    
    destinationData = nil;
    tempData = nil;
    
    //code
    self.production = sourceData;
    self.productNeedsGenerating = NO;
    self.pathNeedsGenerating = YES;
    
    //    NSLog(@"Production result = %@", sourceData);
}


#pragma mark path generation

-(void) geometryChanged {
    self.pathNeedsGenerating = YES;
}
/*!
 Draws the path on the context following the rules from generateProduct.
 */
-(void) generatePaths {
    if (self.pathNeedsGenerating) {
        
        CGPathMoveToPoint(self.currentSegment.path, NULL, 0.0f, 0.0f);
        
        double startingRotation;
        
        startingRotation = [self.privateFractal.baseAngle doubleValue];
        
        self.currentSegment.transform = CGAffineTransformRotate(self.currentSegment.transform, -startingRotation);

        
        for (int c=0; c < [self.production length]; c++) {
            NSString* rule = [self.production substringWithRange: NSMakeRange(c , 1)];
            
            [self evaluateRule: rule];
        }
        if (self.currentSegment.fill) {
            CGPathCloseSubpath(self.currentSegment.path);
        }
        [self finalizeSegments];
        // release the production string now that we have the path
        // self.production = nil;
    }
    
    self.pathNeedsGenerating = NO;
}

-(void) evaluateRule:(NSString *)rule {    
    //
    id selectorId = (self.cachedDrawingRules)[rule];
    if ([selectorId isKindOfClass: [NSString class]]) {
        NSString* selectorString = (NSString*) selectorId;
        [self dispatchDrawingSelectorFromString: selectorString];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(void) dispatchDrawingSelectorFromString:(NSString*)selector {
    // Using cached selectors was a 50% performance improvement. Calling NSSelectorFromString is very expensive.
    SEL cachedSelector = [[self.cachedSelectors objectForKey: selector] pointerValue];
    
    if (!cachedSelector) {
        SEL uncachedSelector = NSSelectorFromString(selector);
        
        if ([self respondsToSelector: uncachedSelector]) {
            cachedSelector = uncachedSelector;
            [self.cachedSelectors setObject: [NSValue valueWithPointer: uncachedSelector] forKey: selector];
        }
    }
    
    [self performSelector: cachedSelector];

}

#pragma clang diagnostic pop

-(void) drawCircle: (double) radius {
    CGAffineTransform local = self.currentSegment.transform;
    CGPathAddEllipseInRect(self.currentSegment.path, &local, CGRectMake(0, -radius, radius*2.0, radius*2.0));
    CGPathMoveToPoint(self.currentSegment.path, &local, radius*2, 0);
}

-(void) drawSquare: (double) width {
    CGAffineTransform local = self.currentSegment.transform;
    CGPathAddRect(self.currentSegment.path, &local, CGRectMake(0, -width/2.0, width, width));
    CGPathMoveToPoint(self.currentSegment.path, &local, 0, 0);
}

#pragma mark Public Rule Methods

-(void) commandDoNothing {
}

-(void) commandDrawLine {
    double tx = self.currentSegment.lineLength;
    CGAffineTransform local = self.currentSegment.transform;
    CGPathAddLineToPoint(self.currentSegment.path, &local, tx, 0);
    self.currentSegment.transform = CGAffineTransformTranslate(self.currentSegment.transform, tx, 0.0f);
}

-(void) commandDrawLineVarLength {
    double tx = self.currentSegment.lineLength;
    CGAffineTransform local = self.currentSegment.transform;
    CGPathAddLineToPoint(self.currentSegment.path, &local, tx, 0);
    self.currentSegment.transform = CGAffineTransformTranslate(self.currentSegment.transform, tx, 0.0f);
}

-(void) commandMoveByLine {
    double tx = self.currentSegment.lineLength;
    CGAffineTransform local = self.currentSegment.transform;
    CGPathMoveToPoint(self.currentSegment.path, &local, tx, 0);
    self.currentSegment.transform = CGAffineTransformTranslate(self.currentSegment.transform, tx, 0.0f);
}

-(void) commandRotateCC {
    double theta = self.currentSegment.turningAngle;
    self.currentSegment.transform = CGAffineTransformRotate(self.currentSegment.transform, -theta);
}

-(void) commandRotateC {
    double theta = self.currentSegment.turningAngle;
    self.currentSegment.transform = CGAffineTransformRotate(self.currentSegment.transform, theta);
}

-(void) commandReverseDirection {
    self.currentSegment.transform = CGAffineTransformRotate(self.currentSegment.transform, M_PI);
}

-(void) commandPush {
    [self pushSegment];
}

-(void) commandPop {
    [self popSegment];
}
/*!
 Assume lineWidthIncrement is a percentage like 10% means add 10% or subtract 10%
 */
-(void) commandIncrementLineWidth {
    if (self.currentSegment.lineChangeFactor > 0) {
        self.currentSegment.lineWidth += self.currentSegment.lineWidth * self.currentSegment.lineChangeFactor;
    }
}

-(void) commandDecrementLineWidth {
    if (self.currentSegment.lineChangeFactor > 0) {
        self.currentSegment.lineWidth -= self.currentSegment.lineWidth * self.currentSegment.lineChangeFactor;
    }
}

-(void) commandDrawDot {
    [self drawCircle: self.currentSegment.lineWidth];
}
-(void) commandDrawDotFilledNoStroke {
    [self commandPush];
    [self commandStrokeOff];
    [self commandFillOn];
    [self commandDrawDot];
    [self commandPop];
}

#pragma message "TODO: implement openPolygon"
-(void) commandOpenPolygon {
    
}

#pragma message "TODO: implement closePolygon"
-(void) commandClosePolygon {
    
}
#pragma message "TODO: remove length scaling in favor of just manipulating the aspect ration with width"
-(void) commandUpscaleLineLength {
    if (self.currentSegment.lineChangeFactor > 0) {
        self.currentSegment.lineLength += self.currentSegment.lineLength * self.currentSegment.lineChangeFactor;
    }
}

-(void) commandDownscaleLineLength {
    if (self.currentSegment.lineChangeFactor > 0) {
        self.currentSegment.lineLength -= self.currentSegment.lineLength * self.currentSegment.lineChangeFactor;
    }
}

-(void) commandSwapRotation {
    id tempMinusRule = (self.cachedDrawingRules)[@"-"];
    (self.cachedDrawingRules)[@"-"] = (self.cachedDrawingRules)[@"+"];
    (self.cachedDrawingRules)[@"+"] = tempMinusRule;
}

-(void) commandDecrementAngle {
    if (self.currentSegment.turningAngleIncrement > 0) {
        self.currentSegment.turningAngle -= self.currentSegment.turningAngle * self.currentSegment.turningAngleIncrement;
    }
}

-(void) commandIncrementAngle {
    if (self.currentSegment.turningAngleIncrement > 0) {
        self.currentSegment.turningAngle += self.currentSegment.turningAngle * self.currentSegment.turningAngleIncrement;
    }
}

-(void) commandStrokeOff {
    [self startNewSegment];
    self.currentSegment.stroke = NO;
}

-(void) commandStrokeOn {
    [self startNewSegment];
    self.currentSegment.stroke = YES;
}
-(void) commandFillOff {
    [self startNewSegment];
    self.currentSegment.fill = NO;
}
-(void) commandFillOn {
    [self startNewSegment];
    self.currentSegment.fill = YES;
}
-(void) commandRandomizeOff {
    self.currentSegment.randomize = NO;
}
-(void) commandRandomizeOn {
    self.currentSegment.randomize = YES;
}
-(void)commandNextColor {
    [self startNewSegment];
    self.currentSegment.lineColorIndex = ++self.currentSegment.lineColorIndex;
}
-(void)commandPreviousColor {
    [self startNewSegment];
    self.currentSegment.lineColorIndex = --self.currentSegment.lineColorIndex;
}
-(void)commandNextFillColor {
    [self startNewSegment];
    self.currentSegment.fillColorIndex = ++self.currentSegment.fillColorIndex;
}
-(void)commandPreviousFillColor {
    [self startNewSegment];
    self.currentSegment.fillColorIndex = --self.currentSegment.fillColorIndex;
}
-(void)commandLineCapButt {
    self.currentSegment.lineCap = kCGLineCapButt;
}
-(void)commandLineCapRound {
    self.currentSegment.lineCap = kCGLineCapRound;
}
-(void)commandLineCapSquare {
    self.currentSegment.lineCap = kCGLineCapSquare;
}
-(void)commandLineJoinMiter {
    self.currentSegment.lineJoin = kCGLineJoinMiter;
}
-(void)commandLineJoinRound {
    self.currentSegment.lineJoin = kCGLineJoinRound;
}
-(void)commandLineJoinBevel {
    self.currentSegment.lineJoin = kCGLineJoinBevel;
}

#pragma mark helper methods

-(double) aspectRatio {
    return self.bounds.size.height/self.bounds.size.width;
}

-(CGSize) unitBox {
    CGSize result = {1.0,1.0};
    double width = self.bounds.size.width;
    double height = self.bounds.size.height;
    
    if (width >= height) {
        // wider than tall width is 1.0
        result.height = height/width;
    } else {
        // taller than wide height is 1.0
        result.width = width/height;
    }
    return result;
}
//TODO: why is this called. somehow related to adding a subview to LevelN view.
// When the subview is touched even "charge" gets called to the delegate which seems to be the generator even though the generator is only the delegate of the LevelN view layer.
//-(void) charge {
//    
//    NSLog(@"Charge called");
//}

@end
