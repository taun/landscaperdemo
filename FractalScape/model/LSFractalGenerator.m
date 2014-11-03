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

#define MAXPRODUCTLENGTH 10000

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

@property (nonatomic,strong) NSMutableArray*        finishedSegments;
@property (nonatomic,strong) NSMutableArray*        segmentStack;

@property (nonatomic,assign,readwrite) CGRect       bounds;
@property (nonatomic,strong) NSMutableDictionary*   cachedDrawingRules;

@property (nonatomic,strong) MBFractalSegment*      currentSegment;

@property (nonatomic,strong) UIImage*               cachedImage;
@property (nonatomic,strong) NSMutableDictionary*   cachedSelectors;

@property (nonatomic,assign) BOOL                   randomize;

-(void) addSegment: (MBFractalSegment*) segment;
-(void) pushSegment;
-(void) popSegment;
-(void) finalizeSegments;

-(void) dispatchDrawingSelectorFromString:(NSString*)selector;
-(void) evaluateRule: (NSString*) rule;

-(void) addObserverForFractal: (LSFractal*)fractal;
-(void) removeObserverForFractal: (LSFractal*)fractal;
-(void) generateProduct;
-(void) generatePaths;

#pragma mark Default Drawing Rule Methods
-(void) commandDoNothing;
-(void) commandDrawLine;
-(void) commandMoveByLine;
-(void) commandRotateCC;
-(void) commandRotateC;
-(void) commandReverseDirection;
-(void) commandPush;
-(void) commandPop;
-(void) commandIncrementLineWidth;
-(void) commandDecrementLineWidth;
-(void) commandDrawDot;
-(void) commandDrawDotFilledNoStroke;
-(void) commandOpenPolygon;
-(void) commandClosePolygon;
-(void) commandUpscaleLineLength;
-(void) commandDownscaleLineLength;
-(void) commandSwapRotation;
-(void) commandDecrementAngle;
-(void) commandIncrementAngle;
-(void) commandStrokeOff;
-(void) commandStrokeOn;
-(void) commandFillOn;
-(void) commandFillOff;
-(void) commandRandomizeOn;
-(void) commandRandomizeOff;
@end

#pragma mark - Implementation

@implementation LSFractalGenerator 

@synthesize fractal = _fractal;
@synthesize forceLevel = _forceLevel;
@synthesize scale = _scale, autoscale = _autoscale, translate = _translate;
@synthesize production = _production, productNeedsGenerating = _productNeedsGenerating;
@synthesize pathNeedsGenerating = _pathNeedsGenerating;
@synthesize finishedSegments = _segments;
@synthesize segmentStack = _segmentStack, bounds = _bounds;
@synthesize path = _path;

@synthesize currentSegment = _currentSegment;
@synthesize cachedDrawingRules = _cachedDrawingRules;

- (instancetype)init {
    self = [super init];
    if (self) {
        _productNeedsGenerating = YES;
        _pathNeedsGenerating = YES;
        _forceLevel = -1.0;
        _scale = 1.0;
        _autoscale = YES;
        _translate = CGPointMake(0.0, 0.0);
        _randomize = NO;
        _bounds = CGRectZero;
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

        [self addObserverForFractal: _fractal];
        [self productionRuleChanged];
    }
}
/* will this cause threading problems? */
-(void) addObserverForFractal:(LSFractal *)fractal {
    if (fractal) {
        [fractal.managedObjectContext performBlock:^{
            
            NSSet* propertiesToObserve = [[LSFractal productionRuleProperties] setByAddingObjectsFromSet:[LSFractal appearanceProperties]];
            
            for (NSString* keyPath in propertiesToObserve) {
                [fractal addObserver: self forKeyPath:keyPath options: 0 context: NULL];
            }
                        
            for (LSReplacementRule* rule in fractal.replacementRules) {
                [rule addObserver: self forKeyPath: @"contextRule" options: 0 context: NULL];
                [rule addObserver: self forKeyPath: @"rules" options: 0 context: NULL];
            }
        }];
    }
}
-(void) removeObserverForFractal:(LSFractal *)fractal {
    if (fractal) {
        [fractal.managedObjectContext performBlock:^{
            
            NSSet* propertiesToObserve = [[LSFractal productionRuleProperties] setByAddingObjectsFromSet:[LSFractal appearanceProperties]];
            
            for (NSString* keyPath in propertiesToObserve) {
                [fractal removeObserver: self forKeyPath: keyPath];
            }
            
            for (LSReplacementRule* rule in fractal.replacementRules) {
                [rule removeObserver: self forKeyPath: @"contextRule"];
                [rule removeObserver: self forKeyPath: @"rules"];
            }
        }];
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([[LSFractal productionRuleProperties] containsObject: keyPath] || [keyPath isEqualToString: @"rules"] || [keyPath isEqualToString: @"contextRule"]) {
        // productionRuleChanged
        [self productionRuleChanged];
    } else if ([[LSFractal appearanceProperties] containsObject: keyPath]) {
        // appearanceChanged
        [self appearanceChanged];
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
-(UIImage*) generateImageSize:(CGSize)size withBackground:(UIColor*)uiColor {
    if (self.productNeedsGenerating || self.pathNeedsGenerating || (self.cachedImage == nil) || !CGSizeEqualToSize(self.cachedImage.size, size)) {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        CGRect viewRect = CGRectMake(0, 0, size.width, size.height);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        NSAssert(context, @"NULL Context being used. Context must be non-null.");
        
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
-(void) drawInBounds:(CGRect)layerBounds withContext:(CGContextRef)theContext flipped:(BOOL)isFlipped {

    __block BOOL eoFill = NO;
    __block CGLineCap lineCap = kCGLineCapButt;
    __block CGLineJoin lineJoin = kCGLineJoinBevel;
    
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
            
            eoFill = [self.privateFractal.eoFill boolValue];
            lineCap = [self.privateFractal.lineCap intValue];
            lineJoin = [self.privateFractal.lineJoin intValue];
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
        
        CGContextSetLineCap(theContext,lineCap);
        CGContextSetLineJoin(theContext, lineJoin);
        CGContextSetLineWidth(theContext, segment.lineWidth);
        
        CGAffineTransform ctm = CGContextGetCTM(theContext);
        CGAffineTransformScale(ctm, 1.0, -1.0);
        CGContextAddPath(theContext, segment.path);
        CGPathAddPath(fractalPath, &ctm, segment.path);
        
        CGPathDrawingMode strokeOrFill = kCGPathStroke;
        if (segment.fill && segment.stroke) {
            if (eoFill) {
                strokeOrFill = kCGPathEOFillStroke;
            } else {
                strokeOrFill = kCGPathFillStroke;
            }
            CGContextSetStrokeColorWithColor(theContext, segment.lineColor);
            CGContextSetFillColorWithColor(theContext, segment.fillColor);
        } else if (segment.stroke) {
            strokeOrFill = kCGPathStroke;
            CGContextSetStrokeColorWithColor(theContext, segment.lineColor);
        } else if (segment.fill) {
            if (eoFill) {
                strokeOrFill = kCGPathEOFill;
            } else {
                strokeOrFill = kCGPathFill;
            }
            CGContextSetFillColorWithColor(theContext, segment.fillColor);
        }
        CGContextDrawPath(theContext, strokeOrFill);
    }

    self.path = CGPathCreateCopy(fractalPath);

    CGContextRestoreGState(theContext);
}

#pragma mark layer delegate
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

#pragma mark lazy init getters
//-(void)setSegmentStack:(NSMutableArray *)segmentStack {
//    if (segmentStack != _segmentStack) {
//        _segmentStack = segmentStack;
//    }
//}
-(NSMutableArray*) segmentStack {
    if (_segmentStack == nil) _segmentStack = [[NSMutableArray alloc] initWithCapacity: 1];
    
    return _segmentStack;
}

//TODO: just reference the fractal in the segment?
-(MBFractalSegment*) currentSegment {
    if (_currentSegment == nil) {
        
        MBFractalSegment* newSegment;
        
        newSegment = [[MBFractalSegment alloc] init];
        
        // Copy the fractal core data values to the segment
        newSegment.lineColor = [self.privateFractal lineColorAsUI].CGColor;
        
        newSegment.fillColor = [self.privateFractal fillColorAsUI].CGColor;
        newSegment.fill = [self.privateFractal.fill boolValue];
        
        newSegment.lineLength = [self.privateFractal lineLengthAsDouble];
        newSegment.lineLengthScaleFactor = [self.privateFractal.lineLengthScaleFactor doubleValue];
        newSegment.lineWidth = [self.privateFractal.lineWidth doubleValue];
        newSegment.lineWidthIncrement = [self.privateFractal.lineWidthIncrement doubleValue];
        newSegment.stroke = [self.privateFractal.stroke boolValue];
        
        newSegment.turningAngle = [self.privateFractal turningAngleAsDouble];
        newSegment.turningAngleIncrement = [self.privateFractal.turningAngleIncrement doubleValue];
        
        newSegment.randomness = [self.privateFractal.randomness doubleValue];
        
        //code
        _currentSegment = newSegment;
        
    }
    return _currentSegment;
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
-(CGPathRef) path {
    if (_path == NULL) {
        _path = CGPathCreateMutable();
        CGPathRetain(_path);
    }
    return _path;
}

-(void) setPath:(CGPathRef)path {
    if (CGPathEqualToPath(_path, path)) return;
    
    CGPathRelease(_path);
    if (path != NULL) {
        _path = (CGMutablePathRef) CGPathRetain(path);
    }
}
-(double) randomness {
    return self.currentSegment.randomness;
}
-(double) turningAngle {
    double value = self.currentSegment.turningAngle;
    if (self.randomize) {
        value *= [self randomScalar];
    }
    return value;
}

-(void) setTurningAngle:(double)turningAngle {
    self.currentSegment.turningAngle = turningAngle;
}

-(double) turningAngleIncrement {
    double value = self.currentSegment.turningAngleIncrement;
    if (self.randomize) {
        value *= [self randomScalar];
    }
    return value;
}

-(void) setTurningAngleIncrement:(double)turningAngleIncrement {
    self.currentSegment.turningAngleIncrement = turningAngleIncrement;
}

-(double) lineLength {
    double value = self.currentSegment.lineLength;
    if (self.randomize) {
        value *= [self randomScalar];
    }
    return value;
}

-(void) setLineLength:(double)lineLength {
    self.currentSegment.lineLength = lineLength;
}

-(double) lineLengthScaleFactor {
    double value = self.currentSegment.lineLengthScaleFactor;
    if (self.randomize) {
        value *= [self randomScalar];
    }
    return value;
}

-(void) setLineLengthScaleFactor:(double)lineLengthScaleFactor {
    self.currentSegment.lineLengthScaleFactor = lineLengthScaleFactor;
}

-(double) lineWidth {
    double value = fabs(self.currentSegment.lineWidth);
    if (self.randomize) {
        value *= [self randomScalar];
    }
    return value;
}

-(void) setLineWidth:(double)lineWidth {
    self.currentSegment.lineWidth = lineWidth;
}

-(double) lineWidthIncrement {
    double value = self.currentSegment.lineWidthIncrement;
    if (self.randomize) {
        value *= [self randomScalar];
    }
    return value;
}

-(void) setLineWidthIncrement:(double)lineWidthIncrement {
    self.currentSegment.lineWidthIncrement = lineWidthIncrement;
}

-(CGColorRef) lineColor {
    return self.currentSegment.lineColor;
}

-(void) setLineColor:(CGColorRef)lineColor {
    self.currentSegment.lineColor = lineColor;
}

-(BOOL) stroke {
    return self.currentSegment.stroke;
}

-(void) setStroke:(BOOL)stroke {
    self.currentSegment.stroke = stroke;
}

-(CGColorRef) fillColor {
    return self.currentSegment.fillColor;
}

-(void) setFillColor:(CGColorRef)fillColor {
    self.currentSegment.fillColor = fillColor;
}

-(BOOL) fill {
    return self.currentSegment.fill;
}

-(void) setFill:(BOOL)fill {
    self.currentSegment.fill = fill;
}

#pragma mark segment methods

/*!
 Should always be an initial current segment.
 Push the currentSegment
 Create a new currentSegment copying the old segments settings
 */
-(void) pushSegment {
    [self.segmentStack addObject: self.currentSegment];
    MBFractalSegment* newCurrentSegment = [self.currentSegment copySettings];
    
    self.currentSegment = newCurrentSegment;
}

/*!
 Check to make sure there is a segment on the stack
 Move the current segment to the final segments array
 */
-(void) popSegment {
    if ([self.segmentStack count]>0) {
        MBFractalSegment* olderCurrentSegment = [self.segmentStack lastObject];
        [self.segmentStack removeLastObject];
        
        [self addSegment: self.currentSegment];
        self.currentSegment = olderCurrentSegment;
    }
}

/*!
 Move the currentSegment to the segments array.
 Check to see if there are any segments left on the stack and move them.
 */
-(void) finalizeSegments {
    [self addSegment: self.currentSegment];
    if (_segmentStack != nil) {
        // Copy segmentStack so it does not mutate during iteration.
        NSArray* localSegmentStackCopy = [self.segmentStack copy];
        for (MBFractalSegment* segment in localSegmentStackCopy) {
            [self addSegment: segment];
            [self.segmentStack removeObject: segment];
        }
    }
}

-(void) addSegment: (MBFractalSegment*) segment {
    CGRect tempBounds = CGRectZero;
    
    if (_segments == nil) {
        _segments = [[NSMutableArray alloc] initWithCapacity: 2];
        
        // intiallize the bounds to the first segment
        tempBounds = CGPathGetBoundingBox(segment.path);
        self.bounds = CGRectEqualToRect(tempBounds, CGRectNull) ? CGRectZero : tempBounds;
    } else {
        tempBounds = CGRectUnion(_bounds, CGPathGetBoundingBox(segment.path));
        self.bounds = CGRectEqualToRect(tempBounds, CGRectNull) ? CGRectZero : tempBounds;
    }
    _maxLineWidth = MAX(_maxLineWidth, segment.lineWidth);
    [_segments addObject: segment];
}


#pragma mark Custom Getter Setters

-(BOOL) productNeedsGenerating {
    return _productNeedsGenerating;
}

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
        _currentSegment = nil;
        _segments = nil;
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
        
        for (int y=0; y < sourceLength; y++) {
            //
            key = [sourceData substringWithRange: NSMakeRange(y, 1)];
            
            replacement = localReplacementRules[key];
            // If a specific rule is missing for a character, use the character
            if (replacement==nil) {
                replacement = key;
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

-(void) appearanceChanged {
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
        if (self.fill) {
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
    double tx = self.lineLength;
    CGAffineTransform local = self.currentSegment.transform;
    CGPathAddLineToPoint(self.currentSegment.path, &local, tx, 0);
    self.currentSegment.transform = CGAffineTransformTranslate(self.currentSegment.transform, tx, 0.0f);
}

-(void) commandMoveByLine {
    double tx = self.lineLength;
    CGAffineTransform local = self.currentSegment.transform;
    CGPathMoveToPoint(self.currentSegment.path, &local, tx, 0);
    self.currentSegment.transform = CGAffineTransformTranslate(self.currentSegment.transform, tx, 0.0f);
}

-(void) commandRotateCC {
    double theta = self.turningAngle;
    self.currentSegment.transform = CGAffineTransformRotate(self.currentSegment.transform, -theta);
}

-(void) commandRotateC {
    double theta = self.turningAngle;
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

-(void) commandIncrementLineWidth {
    self.currentSegment.lineWidth += self.lineWidthIncrement;
}

-(void) commandDecrementLineWidth {
    self.currentSegment.lineWidth = fmax(0,(self.lineWidth - self.lineWidthIncrement));
}

-(void) commandDrawDot {
    [self drawCircle: self.lineWidth];
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

-(void) commandUpscaleLineLength {
    self.currentSegment.lineLength *= self.lineLengthScaleFactor;
}

-(void) commandDownscaleLineLength {
    if (self.currentSegment.lineLengthScaleFactor > 0) {
        self.currentSegment.lineLength = fmax(0,(self.lineLength / self.lineLengthScaleFactor));
    }
}

-(void) commandSwapRotation {
    id tempMinusRule = (self.cachedDrawingRules)[@"-"];
    (self.cachedDrawingRules)[@"-"] = (self.cachedDrawingRules)[@"+"];
    (self.cachedDrawingRules)[@"+"] = tempMinusRule;
}

-(void) commandDecrementAngle {
    self.currentSegment.turningAngle -= self.turningAngleIncrement;
}

-(void) commandIncrementAngle {
    self.currentSegment.turningAngle += self.turningAngleIncrement;
}

-(void) commandStrokeOff {
    self.currentSegment.stroke = NO;
}

-(void) commandStrokeOn {
    self.currentSegment.stroke = YES;
}
-(void) commandFillOff {
    self.currentSegment.fill = NO;
}
-(void) commandFillOn {
    self.currentSegment.fill = YES;
}
-(void) commandRandomizeOff {
    self.randomize = NO;
}
-(void) commandRandomizeOn {
    self.randomize = YES;
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
-(double) randomScalar {
    return [LSFractalGenerator randomDoubleBetween: (1.0 - self.randomness)  and: (1.0 + self.randomness)];
}
+ (double)randomDoubleBetween:(double)smallNumber and:(double)bigNumber {
    double diff = bigNumber - smallNumber;
    return (((double) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * diff) + smallNumber;
}
//TODO: why is this called. somehow related to adding a subview to LevelN view.
// When the subview is touched even "charge" gets called to the delegate which seems to be the generator even though the generator is only the delegate of the LevelN view layer.
//-(void) charge {
//    
//    NSLog(@"Charge called");
//}

@end
