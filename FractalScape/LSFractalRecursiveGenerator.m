//
//  LSFractalRecursiveGenerator.m
//  FractalScape
//
//  Created by Taun Chapman on 01/05/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "LSFractalRecursiveGenerator.h"

#import "LSFractal+addons.h"
#import "MBColor+addons.h"
#import "LSReplacementRule+addons.h"
#import "LSDrawingRuleType+addons.h"
#import "LSDrawingRule+addons.h"

#import <QuartzCore/QuartzCore.h>

#define MAXPRODUCTLENGTH 200000



typedef void (*MBFractalHelperFunction) (MBSegmentStruct* segmentPtr, CGFloat value);

void MBCGDrawCircle(MBSegmentStruct* segmentPtr, CGFloat radius);
void MBCGDrawSquare(MBSegmentStruct* segmentPtr, CGFloat width);



@interface LSFractalRecursiveGenerator () {
    CGFloat _maxLineWidth;
}
@property (nonatomic,strong) NSManagedObjectID      *fractalID;
@property (nonatomic,strong) NSManagedObjectContext *parentObjectContext;
@property (nonatomic,strong) NSManagedObjectContext *privateObjectContext;
@property (nonatomic,strong) LSFractal              *privateFractal;

@property (nonatomic,assign) BOOL                   pathNeedsGenerating;


@property (nonatomic,assign,readwrite) CGRect       bounds;
@property (nonatomic,strong) NSMapTable*            cachedDrawingFunctions;
@property (nonatomic,strong) NSArray*               cachedLineColors;
@property (nonatomic,strong) NSArray*               cachedFillColors;
@property (nonatomic,strong) UIColor*               defaultColor;

@property (nonatomic,assign) BOOL                   controlPointOn;
@property (nonatomic,assign) CGPoint                controlPointNode;
@property (nonatomic,assign) CGPoint                previousNode;


@property (nonatomic,strong) UIImage*               cachedImage;
@property (nonatomic,strong) NSDictionary*          cachedReplacementRules;

-(void) dispatchDrawingSelectorFromString:(NSString*)selector;
-(void) evaluateRule: (NSString*) rule;

-(void) addObserverForFractal: (LSFractal*)fractal;
-(void) removeObserverForFractal: (LSFractal*)fractal;

-(void) cacheColors: (LSFractal*)fractal;
-(void) cacheLineEnds: (LSFractal*)fractal;


@end

#pragma mark - Implementation

@implementation LSFractalRecursiveGenerator


- (instancetype)init {
    self = [super init];
    if (self) {
        
        _pathNeedsGenerating = YES;
        _forceLevel = -1.0;
        _scale = 1.0;
        _autoscale = YES;
        _translate = CGPointMake(0.0, 0.0);
        _bounds =  CGRectMake(0, 0, 300, 300);
        _defaultColor = [UIColor blueColor];
        _controlPointOn = NO;
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
        
//        [self cacheColors: _fractal];
//        [self cacheLineEnds: _fractal];
        
        NSMutableDictionary* tempDictionary = [[NSMutableDictionary alloc] initWithCapacity: _fractal.replacementRules.count];
        
        NSOrderedSet* replacementRules =  _fractal.replacementRules;
        for (LSReplacementRule* replacementRule in replacementRules) {
            [tempDictionary setObject: replacementRule forKey: replacementRule.contextRule.productionString];
        }
        
        self.cachedReplacementRules = [tempDictionary copy];

        
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
        if (!(self.forceLevel > -1 && [keyPath isEqualToString: @"level"])) {
            [self productionRuleChanged];
//            [self cacheColors: _fractal];
//            [self cacheLineEnds: _fractal];
        }
        
        
    } else if ([[LSFractal appearanceProperties] containsObject: keyPath]) {
        // appearanceChanged
        [self geometryChanged];
//        [self cacheColors: _fractal];
//        [self cacheLineEnds: _fractal];
        
    } else if ([[LSFractal redrawProperties] containsObject: keyPath]) {
//        [self cacheColors: _fractal];
//        [self cacheLineEnds: _fractal];
        
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
    
    return [NSString stringWithFormat: @"<%@: fractal = %@; forceLevel = %g; bounds = %@>",
            NSStringFromClass([self class]),
            self.fractal,
            self.forceLevel,
            boundsDescription];
}
/*!
 Can be called in a private thread, operation.
 
 @param size
 @param uiColor
 
 @return
 */
-(UIImage*) generateImageSize:(CGSize)size withBackground:(UIColor*)uiColor {
    if ( self.pathNeedsGenerating || (self.cachedImage == nil) || !CGSizeEqualToSize(self.cachedImage.size, size)) {
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
        
        [self recursiveDrawInBounds: viewRect
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
    if ((self.cachedImage == nil) || !CGSizeEqualToSize(self.cachedImage.size, size)) {
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
//-(void) drawInBounds:(CGRect)layerBounds withContext:(CGContextRef)theContext flipped:(BOOL)isFlipped {
//    
//    NSDate *methodStart;
//    
//    NSTimeInterval executionTime = 0.0;
//    __block NSTimeInterval productExecutionTime = 0.0;
//    __block NSTimeInterval pathExecutionTime = 0.0;
//    
//    // Following is because layerBounds value disappears after 1st if statement line below.
//    // cause totally unknown.
//    CGRect localBounds = layerBounds;
//    
//    if (self.pathNeedsGenerating) {
//        //        [self.privateObjectContext performBlockAndWait:^{
//        
//        [self.privateObjectContext reset];
//        self.privateFractal = (LSFractal*)[self.privateObjectContext objectWithID: self.fractalID];
//        //            [self.privateObjectContext refreshObject: self.privateFractal mergeChanges: NO];
//        NSDate *blockMethodStart;
//        NSDate *blockMethodFinish;
//        
//        if (self.pathNeedsGenerating) {
//            blockMethodStart = [NSDate date];
//            [self generatePaths];
//            blockMethodFinish = [NSDate date];
//            pathExecutionTime = floorf(1000.0*[blockMethodFinish timeIntervalSinceDate: blockMethodStart]);
//        }
//        
//        //        }];
//    }
//    
//    
//    CGContextSaveGState(theContext);
//    
//
//    //    NSDictionary* lboundsDict = (__bridge NSDictionary*) CGRectCreateDictionaryRepresentation(bounds);
//    //    NSLog(@"Layer Bounds = %@", lboundsDict);
//    
//    //    NSDictionary* boundsDict = (__bridge NSDictionary*) CGRectCreateDictionaryRepresentation(self.bounds);
//    //    NSLog(@"Fractal Path Bounds = %@", boundsDict);
//    
//    //    NSLog(@"Layer anchor point: %g@%g", theLayer.anchorPoint.x, theLayer.anchorPoint.y);
//    
//    if (self.autoscale) {
//        // Scaling
//        CGFloat scaleWidth = localBounds.size.width/self.bounds.size.width;
//        CGFloat scaleHeight = localBounds.size.height/self.bounds.size.height;
//        
//        self.scale = MIN(scaleHeight, scaleWidth);
//        
//        //    CGFloat margin = -0.0/scale;
//        
//        //    CGContextScaleCTM(theContext, scale, scale);
//        //    NSLog(@"Min Layer/Fractal Scale = %g", scale);
//        
//        
//        //    CGRect fBounds = CGRectStandardize(CGRectInset(self.bounds, margin, margin) );
//        
//        // Translating
//        CGFloat fCenterX = (self.bounds.origin.x + self.bounds.size.width/2.0);
//        CGFloat fCenterY = (self.bounds.origin.y + self.bounds.size.height/2.0);
//        
//        CGFloat lCenterX = localBounds.origin.x + localBounds.size.width/2.0;
//        CGFloat lCenterY = localBounds.origin.y + localBounds.size.height/2.0;
//        
//        self.translate = CGPointMake(lCenterX - (fCenterX*self.scale), lCenterY - (fCenterY*self.scale));
//    }
//    
//    CGContextTranslateCTM(theContext, self.translate.x, self.translate.y);
//    
//    CGContextScaleCTM(theContext, self.scale, self.scale);
//    
//    //    NSLog(@"Translation FCenter = %g@%g; LCenter = %g@%g; tx = %g; ty = %g",
//    //          fCenterX, fCenterY, lCenterX, lCenterY, tx, ty);
//    //    CGRect localBounds = self.fractalLevelNLayer.bounds;
//    
//    //    CGAffineTransform pathTransform = CGAffineTransformIdentity;
//    //    CGPointMake(localBounds.origin.x, localBounds.origin.y + localBounds.size.height);
//    
//    methodStart = [NSDate date];
//    
//    CGMutablePathRef fractalPath = CGPathCreateMutable();
//    //    CGPathMoveToPoint(fractalPath, NULL, localBounds.origin.x, localBounds.origin.y + localBounds.size.height);
//    
//    for (MBFractalSegment* segment in self.finishedSegments) {
//        // stroke and or fill each segment
//        CGContextBeginPath(theContext);
//        
//        
//        //        NSDictionary* aboundsDict = (__bridge NSDictionary*) CGRectCreateDictionaryRepresentation(CGPathGetBoundingBox(segment.path));
//        //        NSLog(@"Actual segment bounds = %@", aboundsDict);
//        
//        // Scale the lineWidth to compensate for the overall scaling
//        //        CGContextSetLineWidth(ctx, segment.lineWidth);
//        //        CGContextSetLineWidth(theContext, segment.lineWidth/self.scale);
//        
//        CGContextSetLineCap(theContext, segment.lineCap);
//        CGContextSetLineJoin(theContext, segment.lineJoin);
//        CGContextSetLineWidth(theContext, segment.lineWidth);
//        
//        CGAffineTransform ctm = CGContextGetCTM(theContext);
//        CGAffineTransformScale(ctm, 1.0, -1.0);
//        CGContextAddPath(theContext, segment.path);
//        CGPathAddPath(fractalPath, &ctm, segment.path);
//        
//        CGPathDrawingMode strokeOrFill = kCGPathStroke;
//        if (segment.fill && segment.stroke) {
//            if (self.cachedEoFill) {
//                strokeOrFill = kCGPathEOFillStroke;
//            } else {
//                strokeOrFill = kCGPathFillStroke;
//            }
//            CGContextSetStrokeColorWithColor(theContext, [[self colorForIndex: segment.lineColorIndex inArray: self.cachedLineColors] CGColor]);
//            CGContextSetFillColorWithColor(theContext, [[self colorForIndex: segment.fillColorIndex inArray: self.cachedFillColors] CGColor]);
//        } else if (segment.stroke) {
//            strokeOrFill = kCGPathStroke;
//            CGContextSetStrokeColorWithColor(theContext, [[self colorForIndex: segment.lineColorIndex inArray: self.cachedLineColors] CGColor]);
//        } else if (segment.fill) {
//            if (self.cachedEoFill) {
//                strokeOrFill = kCGPathEOFill;
//            } else {
//                strokeOrFill = kCGPathFill;
//            }
//            CGContextSetFillColorWithColor(theContext, [[self colorForIndex: segment.fillColorIndex inArray: self.cachedFillColors] CGColor] );
//        }
//        CGContextDrawPath(theContext, strokeOrFill);
//    }
//    
//    self.fractalCGPathRef = fractalPath;
//    
//    CGContextRestoreGState(theContext);
//    
//    NSDate *methodFinish = [NSDate date];
//    executionTime = floorf(1000.0*[methodFinish timeIntervalSinceDate:methodStart]);
//    
//    CGPathRelease(fractalPath);
//    //    NSLog(@"production executionTime = %f", productExecutionTime);
//    //    NSLog(@"path executionTime = %f", pathExecutionTime);
//    //    NSLog(@"drawing executionTime = %f", executionTime);
//}

-(UIColor*) colorForIndex: (NSInteger)index inArray: (NSArray*) colorArray {
    CGFloat count = (CGFloat)colorArray.count;
    if (count == 0.0) {
        return self.defaultColor;
    }
    
    NSInteger moddedIndex = (NSInteger)fabs(fmod((CGFloat)index, count));
    
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

-(MBSegmentStruct) initialSegment {
    
    MBSegmentStruct newSegment;
    
    // Copy the fractal core data values to the segment
    
    [self.privateObjectContext reset];
    self.privateFractal = (LSFractal*)[self.privateObjectContext objectWithID: self.fractalID];
    //            [self.privateObjectContext refreshObject: self.privateFractal mergeChanges: NO];

    newSegment.lineColorIndex = 0;
    newSegment.fillColorIndex = 0;
    
    newSegment.lineLength = [self.privateFractal.lineLength floatValue];
    newSegment.lineLengthScaleFactor = [self.privateFractal.lineLengthScaleFactor floatValue];
    
    newSegment.lineWidth = [self.privateFractal.lineWidth floatValue];
    newSegment.lineWidthIncrement = [self.privateFractal.lineWidthIncrement floatValue];
    
    newSegment.turningAngle = [self.privateFractal turningAngleAsDouble];
    newSegment.turningAngleIncrement = [self.privateFractal.turningAngleIncrement floatValue];
    
    newSegment.randomness = [self.privateFractal.randomness floatValue];
    newSegment.lineChangeFactor = [self.privateFractal.lineChangeFactor floatValue];
    
    newSegment.lineCap = kCGLineCapRound;
    newSegment.lineJoin = kCGLineJoinRound;
    
    newSegment.stroke = YES;
    newSegment.fill = NO;
    newSegment.EOFill = self.privateFractal.eoFill ? [self.privateFractal.eoFill boolValue] : NO;
    
    newSegment.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -[self.privateFractal.baseAngle floatValue]);

    
    return newSegment;
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

-(NSMapTable*) cachedDrawingFunctions {
    if (_cachedDrawingFunctions == nil) {
        
        NSPointerFunctionsOptions mapKeyOptions = NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPersonality | NSPointerFunctionsCopyIn;
        
        NSPointerFunctionsOptions mapValueOptions = NSPointerFunctionsOpaqueMemory | NSPointerFunctionsOpaquePersonality;
        
        NSMapTable* mapTable = [NSMapTable mapTableWithKeyOptions: mapKeyOptions valueOptions: mapValueOptions];
        
        [mapTable setObject: (__bridge id) (void*)MBCGCommandDoNothingOnSegment forKey: @"commandDoNothing"];
        [mapTable setObject: (__bridge id)((void*)MBCGCommandDrawLineOnSegment) forKey: @"commandDrawLine"];
        [mapTable setObject: (__bridge id)((void*)MBCGCommandMoveByLineOnSegment) forKey: @"commandMoveByLine"];
        [mapTable setObject: (__bridge id)((void*)MBCGCommandRotateCCOnSegment) forKey: @"commandRotateCC"];
        [mapTable setObject: (__bridge id)((void*)MBCGCommandRotateCOnSegment) forKey: @"commandRotateC"];
        [mapTable setObject: (__bridge id)((void*)MBCGCommandStrokeOnOnSegment) forKey: @"commandStrokeOn"];
        [mapTable setObject: (__bridge id)((void*)MBCGCommandStrokeOffOnSegment) forKey: @"commandStrokeOff"];
        [mapTable setObject: (__bridge id)((void*)MBCGCommandFillOnOnSegment) forKey: @"commandFillOn"];
        [mapTable setObject: (__bridge id)((void*)MBCGCommandFillOffOnSegment) forKey: @"commandFillOff"];
        
        
        _cachedDrawingFunctions = mapTable;
        

    }
    return _cachedDrawingFunctions;
}

-(void) clearCache {
    self.cachedDrawingFunctions = nil;
    self.cachedImage = nil;
}


-(CGRect) bounds {
    // adjust for the lineWidth
    CGFloat margin = _maxLineWidth*2.0+1.0;
    CGRect result = CGRectInset(_bounds, -margin, -margin);
    return result;
    //    return _bounds;
}

#pragma mark Custom Getter Setters


-(void) setPathNeedsGenerating:(BOOL)pathNeedsGenerating {
    _pathNeedsGenerating = pathNeedsGenerating;
    if (_pathNeedsGenerating) {
    }
}

//-(void) setInitialTransform:(CGAffineTransform)transform {
//    segment.transform = transform;
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
    self.bounds = CGRectZero;
    self.pathNeedsGenerating = YES;
}

#pragma mark path generation

-(void) geometryChanged {
    self.pathNeedsGenerating = YES;
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
    //    CGRect tileBoundingRect = CGContextGetClipBoundingBox(theContext);
    //    CALayer* containerLayer = theLayer.superlayer;
    CGRect tempRect = theLayer.bounds;
    CGRect layerBounds = CGRectMake(tempRect.origin.x, tempRect.origin.y, tempRect.size.width, tempRect.size.height);
    [self recursiveDrawInBounds: layerBounds withContext: theContext flipped: [theLayer contentsAreFlipped]];
}

-(void) recursiveDrawInBounds:(CGRect)layerBounds withContext:(CGContextRef)cgContext flipped:(BOOL)isFlipped {
    NSDate *methodStart;
    
    NSTimeInterval executionTime = 0.0;
    __block NSTimeInterval productExecutionTime = 0.0;
    __block NSTimeInterval pathExecutionTime = 0.0;
    
    // Following is because layerBounds value disappears after 1st if statement line below.
    // cause totally unknown.
    CGRect localBounds = layerBounds;
    
    CGContextSaveGState(cgContext);
    
//    methodStart = [NSDate date];
    
    // Start path generation
    // ---------
    
    if (self.autoscale) {
        
        // Scaling
        CGFloat scaleWidth = localBounds.size.width/self.bounds.size.width;
        CGFloat scaleHeight = localBounds.size.height/self.bounds.size.height;
        
        self.scale = MIN(scaleHeight, scaleWidth);
        
        //    CGFloat margin = -0.0/scale;
        
        //    CGContextScaleCTM(theContext, scale, scale);
        //    NSLog(@"Min Layer/Fractal Scale = %g", scale);
        
        
        //    CGRect fBounds = CGRectStandardize(CGRectInset(self.bounds, margin, margin) );
        
        // Translating
        CGFloat fCenterX = (self.bounds.origin.x + self.bounds.size.width/2.0);
        CGFloat fCenterY = (self.bounds.origin.y + self.bounds.size.height/2.0);
        
        CGFloat lCenterX = localBounds.origin.x + localBounds.size.width/2.0;
        CGFloat lCenterY = localBounds.origin.y + localBounds.size.height/2.0;
        
        self.translate = CGPointMake(lCenterX - (fCenterX*self.scale), lCenterY - (fCenterY*self.scale));
    }

    
    [self createFractalLevel: [self.fractal.level unsignedIntegerValue]  withContext: cgContext];
    
    // ---------
    // End path generation
    
    CGContextRestoreGState(cgContext);
    
    
//    NSDate *methodFinish = [NSDate date];
//    executionTime = floorf(1000.0*[methodFinish timeIntervalSinceDate:methodStart]);
    
}
/*
 How to handle scaling?
 ** Two steps
    1. Create at a standard scale.
    2. Redraw at best scale.
    3. Change scale as necessary when changing properties but only draw once and cache scale.
 */
-(void) createFractalLevel: (NSUInteger) level withContext: (CGContextRef) cgContext{
    NSOrderedSet* rules = self.fractal.startingRules;
    
    
    CGContextTranslateCTM(cgContext, self.translate.x, self.translate.y);
    
    CGContextScaleCTM(cgContext, self.scale, self.scale);

//    CGContextTranslateCTM(cgContext, 300.5, 300.5);
//    CGContextScaleCTM(cgContext, 0.1, 0.1);
    CGContextScaleCTM(cgContext, 1.0, -1.0);

    CGContextBeginPath(cgContext);
    CGContextMoveToPoint(cgContext, 0.5f, 0.5f);
    
    CGContextSetStrokeColorWithColor(cgContext, [[UIColor blueColor] CGColor]);
    CGContextSetFillColorWithColor(cgContext, [[UIColor yellowColor] CGColor]);

    MBSegmentStruct startingSegment = [self initialSegment];
    startingSegment.context = cgContext;
    CGContextConcatCTM(cgContext, startingSegment.transform);

    BOOL stroke = startingSegment.stroke;
    BOOL fill = startingSegment.fill;
    BOOL eoFill = startingSegment.EOFill;
    
    CGPathDrawingMode strokeOrFill = kCGPathStroke;
    
    if (fill && stroke) {
        strokeOrFill = eoFill ? kCGPathEOFillStroke : kCGPathFillStroke;
    } else if (stroke && !fill) {
        strokeOrFill = kCGPathStroke;
    } else if (fill && !stroke) {
        strokeOrFill = eoFill ? kCGPathEOFill : kCGPathFill;
    }
    
    startingSegment.mode = strokeOrFill;

    [self segment: &startingSegment recursiveReplacementOf: rules replacements: self.cachedReplacementRules currentLevel: 0 desiredLevel: level];

    CGRect pathBounds = CGContextGetPathBoundingBox(startingSegment.context);
    CGRect tempBounds = CGRectUnion(_bounds, pathBounds);
    self.bounds = CGRectEqualToRect(tempBounds, CGRectNull) ? CGRectZero : tempBounds;
    NSLog(@"Fractal PathBounds: %@; total bounds: %@", NSStringFromCGRect(pathBounds),NSStringFromCGRect(tempBounds));
    CGContextDrawPath(startingSegment.context, startingSegment.mode);
    
//    CGRect pathBounds = CGContextGetPathBoundingBox(cgContext);
//    NSLog(@"Path Bounds: %@", NSStringFromCGRect(pathBounds));
//    NSLog(@"LineLength: %f; LineWidth: %f",startingSegment.lineLength, startingSegment.lineWidth);
}

/*
 A
 A+BF+
 -FA-B
 
 0: A
 1: A+BF+
 2: A+BF++-FA-BF+
 
 */

-(void) segment: (MBSegmentStruct*)segmentPtr recursiveReplacementOf: (NSOrderedSet*) rules replacements: (NSDictionary*) replacementRules currentLevel: (NSUInteger) currentLevel desiredLevel: (NSUInteger) desiredLevel {
    
    for (LSDrawingRule* rule in rules) {
        //
        if (currentLevel < desiredLevel) {
            // replace if necessary
            LSReplacementRule* replacementRule = replacementRules[rule.productionString];
            if (replacementRule) {
                NSOrderedSet* newRules = replacementRule.rules;
                [self segment: segmentPtr recursiveReplacementOf: newRules replacements: replacementRules currentLevel: currentLevel+1 desiredLevel: desiredLevel];
            } else {
                // no replacement rule so just use the rule for a node
                [self evaluateRule: rule.drawingMethodString onSegment: segmentPtr];
            }
        } else {
            // return node for current rule
            [self evaluateRule: rule.drawingMethodString onSegment: segmentPtr];
        }
    }
    
//    CGRect pathBounds = CGContextGetPathBoundingBox(segmentPtr->context);
//    CGRect tempBounds = CGRectUnion(_bounds, pathBounds);
//    self.bounds = CGRectEqualToRect(tempBounds, CGRectNull) ? CGRectZero : tempBounds;
//    //    NSLog(@"Fractal PathBounds: %@; total bounds: %@", NSStringFromCGRect(pathBounds),NSStringFromCGRect(tempBounds));
//    
//    CGPoint lastPoint = CGContextGetPathCurrentPoint(segmentPtr->context);
//    CGContextDrawPath(segmentPtr->context, segmentPtr->mode);
//    CGContextBeginPath(segmentPtr->context);
//    CGContextMoveToPoint(segmentPtr->context, lastPoint.x, lastPoint.y);
}


-(void) evaluateRule:(NSString *)rule onSegment: (MBSegmentStruct*) segmentPtr{
    //
//    NSLog(@"Evaluating rule: %@", rule);
    MBFractalCommandFunction commandFunction = (__bridge void*)[self.cachedDrawingFunctions objectForKey: rule];
    if (commandFunction != NULL) {
        commandFunction(segmentPtr);
    }
}


#pragma mark helper methods

-(CGFloat) aspectRatio {
    return self.bounds.size.height/self.bounds.size.width;
}

-(CGSize) unitBox {
    CGSize result = {1.0,1.0};
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
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


void MBCGDrawCircle(MBSegmentStruct* segmentPtr, CGFloat radius) {
    CGContextAddEllipseInRect(segmentPtr->context, CGRectMake(0.0, -radius, radius*2.0, radius*2.0));
    CGContextMoveToPoint(segmentPtr->context, radius*2.0, 0.0);
}

void MBCGDrawSquare(MBSegmentStruct* segmentPtr, CGFloat width) {
    CGContextAddRect(segmentPtr->context, CGRectMake(0.0, -width/2.0, width, width));
    CGContextMoveToPoint(segmentPtr->context, 0.0, 0.0);
}



#pragma mark Public Rule Methods

void MBCGCommandDoNothingOnSegment(MBSegmentStruct* segmentPtr) {
}

void MBCGCommandDrawLineOnSegment(MBSegmentStruct* segmentPtr) {
    CGContextRef aCGContext = segmentPtr->context;
    CGFloat tx = segmentPtr->lineLength;
    
    //    if (self.controlPointOn) {
    //        CGAffineTransform inverted = CGAffineTransformInvert(local);
    //        CGPoint p1 = CGPointApplyAffineTransform(self.previousNode, inverted);
    //        CGPoint cp0 = CGPointApplyAffineTransform(self.controlPointNode, inverted);
    //        //        CGPoint cp1 =
    //        //        CGPathAddCurveToPoint(segment.path, &local, cp0.x, cp0.y, cp0.x, cp0.y, tx, 0.0);
    //        CGPathAddArcToPoint(segment.path, &local, cp0.x, cp0.y, tx, 0.0, tx);
    //        CGPathAddLineToPoint(segment.path, &local, tx, 0.0);
    //        self.controlPointOn = NO;
    //    } else {
    CGContextAddLineToPoint(aCGContext, tx, 0.0);
    //    }
    CGContextTranslateCTM(aCGContext, tx, 0.0);
}

void MBCGCommandDrawLineVarLengthOnSegment(MBSegmentStruct* segmentPtr) {
    CGContextRef aCGContext = segmentPtr->context;
    CGFloat tx = segmentPtr->lineLength;
    
    //    if (self.controlPointOn) {
    //        CGAffineTransform inverted = CGAffineTransformInvert(local);
    //        CGPoint p1 = CGPointApplyAffineTransform(self.previousNode, inverted);
    //        CGPoint cp0 = CGPointApplyAffineTransform(self.controlPointNode, inverted);
    //        //        CGPoint cp1 =
    //        CGPathAddCurveToPoint(segment.path, &local, cp0.x, cp0.y, cp0.x, cp0.y, tx, 0.0);
    //        self.controlPointOn = NO;
    //    } else {
    CGContextAddLineToPoint(aCGContext, tx, 0.0);
    //    }
    CGContextTranslateCTM(aCGContext, tx, 0.0);
}

void MBCGCommandMoveByLineOnSegment(MBSegmentStruct* segmentPtr) {
    CGContextRef aCGContext = segmentPtr->context;
    CGFloat tx = segmentPtr->lineLength;
    CGContextMoveToPoint(aCGContext, tx, 0.0);
    CGContextTranslateCTM(aCGContext, tx, 0.0);
}

void MBCGCommandRotateCCOnSegment(MBSegmentStruct* segmentPtr) {
    CGContextRef aCGContext = segmentPtr->context;
    CGFloat theta = segmentPtr->turningAngle;
    CGContextRotateCTM(aCGContext, theta);
}

void MBCGCommandRotateCOnSegment(MBSegmentStruct* segmentPtr) {
    CGContextRef aCGContext = segmentPtr->context;
    CGFloat theta = segmentPtr->turningAngle;
    CGContextRotateCTM(aCGContext, -theta);
}

void MBCGCommandReverseDirectionOnSegment(MBSegmentStruct* segmentPtr) {
    segmentPtr->transform = CGAffineTransformRotate(segmentPtr->transform, M_PI);
}
void MBCGCommandCurveCOnSegment(MBSegmentStruct* segmentPtr) {
    MBCGCommandCurvePointOnSegment(segmentPtr);
    MBCGCommandRotateCOnSegment(segmentPtr);
    MBCGCommandDrawLineOnSegment(segmentPtr);
}
void MBCGCommandCurveCCOnSegment(MBSegmentStruct* segmentPtr) {
    MBCGCommandCurvePointOnSegment(segmentPtr);
    MBCGCommandRotateCCOnSegment(segmentPtr);
    MBCGCommandDrawLineOnSegment(segmentPtr);
}
void MBCGCommandCurvePointOnSegment(MBSegmentStruct* segmentPtr) {
    //    self.previousNode = CGPathGetCurrentPoint(segmentPtr->path);
    //
    //    CGFloat tx = segmentPtr->lineLength;
    //    segmentPtr->transform = CGAffineTransformTranslate(segmentPtr->transform, tx, 0.0);
    //
    //    CGAffineTransform local = segmentPtr->transform;
    //
    //    self.controlPointNode = CGPointApplyAffineTransform(CGPointMake(0.0, 0.0), local);
    //    self.controlPointOn = YES;
}

void MBCGCommandPushOnSegment(MBSegmentStruct* segmentPtr) {
    //    [self pushSegment];
}

void MBCGCommandPopOnSegment(MBSegmentStruct* segmentPtr) {
    //    [self popSegment];
}
/*!
 Assume lineWidthIncrement is a percentage like 10% means add 10% or subtract 10%
 */
void MBCGCommandIncrementLineWidthOnSegment(MBSegmentStruct* segmentPtr) {
    if (segmentPtr->lineChangeFactor > 0) {
        segmentPtr->lineWidth += segmentPtr->lineWidth * segmentPtr->lineChangeFactor;
    }
}

void MBCGCommandDecrementLineWidthOnSegment(MBSegmentStruct* segmentPtr) {
    if (segmentPtr->lineChangeFactor > 0) {
        segmentPtr->lineWidth -= segmentPtr->lineWidth * segmentPtr->lineChangeFactor;
    }
}

void MBCGCommandDrawDotOnSegment(MBSegmentStruct* segmentPtr) {
    MBCGDrawCircle(segmentPtr, segmentPtr->lineWidth);
}
void MBCGCommandDrawDotFilledNoStrokeOnSegment(MBSegmentStruct* segmentPtr) {
    MBCGCommandPushOnSegment(segmentPtr);
    MBCGCommandStrokeOffOnSegment(segmentPtr);
    MBCGCommandFillOnOnSegment(segmentPtr);
    MBCGCommandDrawDotOnSegment(segmentPtr);
    MBCGCommandPopOnSegment(segmentPtr);
}

void MBCGCommandOpenPolygonOnSegment(MBSegmentStruct* segmentPtr) {
    MBCGCommandPushOnSegment(segmentPtr);
    MBCGCommandStrokeOffOnSegment(segmentPtr);
    MBCGCommandFillOnOnSegment(segmentPtr);
}

void MBCGCommandClosePolygonOnSegment(MBSegmentStruct* segmentPtr) {
    MBCGCommandPopOnSegment(segmentPtr);
}
#pragma message "TODO: remove length scaling in favor of just manipulating the aspect ration with width"
void MBCGCommandUpscaleLineLengthOnSegment(MBSegmentStruct* segmentPtr) {
    if (segmentPtr->lineChangeFactor > 0) {
        segmentPtr->lineLength += segmentPtr->lineLength * segmentPtr->lineChangeFactor;
    }
}

void MBCGCommandDownscaleLineLengthOnSegment(MBSegmentStruct* segmentPtr) {
    if (segmentPtr->lineChangeFactor > 0) {
        segmentPtr->lineLength -= segmentPtr->lineLength * segmentPtr->lineChangeFactor;
    }
}

void MBCGCommandSwapRotationOnSegment(MBSegmentStruct* segmentPtr) {
    //    id tempMinusRule = (self.cachedDrawingRules)[@"-"];
    //    (self.cachedDrawingRules)[@"-"] = (self.cachedDrawingRules)[@"+"];
    //    (self.cachedDrawingRules)[@"+"] = tempMinusRule;
}

void MBCGCommandDecrementAngleOnSegment(MBSegmentStruct* segmentPtr) {
    if (segmentPtr->turningAngleIncrement > 0) {
        segmentPtr->turningAngle -= segmentPtr->turningAngle * segmentPtr->turningAngleIncrement;
    }
}

void MBCGCommandIncrementAngleOnSegment(MBSegmentStruct* segmentPtr) {
    if (segmentPtr->turningAngleIncrement > 0) {
        segmentPtr->turningAngle += segmentPtr->turningAngle * segmentPtr->turningAngleIncrement;
    }
}

void MBCGCommandStrokeOffOnSegment(MBSegmentStruct* segmentPtr) {
    //    [self startNewSegment];
    segmentPtr->stroke = NO;
}

void MBCGCommandStrokeOnOnSegment(MBSegmentStruct* segmentPtr) {
    //    [self startNewSegment];
    segmentPtr->stroke = YES;
}
void MBCGCommandFillOffOnSegment(MBSegmentStruct* segmentPtr) {
    //    [self startNewSegment];
    segmentPtr->fill = NO;
}
void MBCGCommandFillOnOnSegment(MBSegmentStruct* segmentPtr) {
    //    [self startNewSegment];
    segmentPtr->fill = YES;
}
void MBCGCommandRandomizeOffOnSegment(MBSegmentStruct* segmentPtr) {
    segmentPtr->randomize = NO;
}
void MBCGCommandRandomizeOnOnSegment(MBSegmentStruct* segmentPtr) {
    segmentPtr->randomize = YES;
}
void MBCGCommandNextColorOnSegment(MBSegmentStruct* segmentPtr) {
    //    [self startNewSegment];
    segmentPtr->lineColorIndex = ++segmentPtr->lineColorIndex;
}
void MBCGCommandPreviousColorOnSegment(MBSegmentStruct* segmentPtr) {
    //    [self startNewSegment];
    segmentPtr->lineColorIndex = --segmentPtr->lineColorIndex;
}
void MBCGCommandNextFillColorOnSegment(MBSegmentStruct* segmentPtr) {
    //    [self startNewSegment];
    segmentPtr->fillColorIndex = ++segmentPtr->fillColorIndex;
}
void MBCGCommandPreviousFillColorOnSegment(MBSegmentStruct* segmentPtr) {
    //    [self startNewSegment];
    segmentPtr->fillColorIndex = --segmentPtr->fillColorIndex;
}
void MBCGCommandLineCapButtOnSegment(MBSegmentStruct* segmentPtr) {
    segmentPtr->lineCap = kCGLineCapButt;
}
void MBCGCommandLineCapRoundOnSegment(MBSegmentStruct* segmentPtr) {
    segmentPtr->lineCap = kCGLineCapRound;
}
void MBCGCommandLineCapSquareOnSegment(MBSegmentStruct* segmentPtr) {
    segmentPtr->lineCap = kCGLineCapSquare;
}
void MBCGCommandLineJoinMiterOnSegment(MBSegmentStruct* segmentPtr) {
    segmentPtr->lineJoin = kCGLineJoinMiter;
}
void MBCGCommandLineJoinRoundOnSegment(MBSegmentStruct* segmentPtr) {
    segmentPtr->lineJoin = kCGLineJoinRound;
}
void MBCGCommandLineJoinBevelOnSegment(MBSegmentStruct* segmentPtr) {
    segmentPtr->lineJoin = kCGLineJoinBevel;
}

