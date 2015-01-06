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



typedef void (*MBFractalHelerFunction) (MBSegmentStruct segment, CGFloat value);

void MBCGDrawCircle(MBSegmentStruct segment, CGFloat radius);
void MBCGDrawSquare(MBSegmentStruct segment, CGFloat width);



@interface LSFractalRecursiveGenerator () {
    CGFloat _maxLineWidth;
}
@property (nonatomic,strong) NSManagedObjectID      *fractalID;
@property (nonatomic,strong) NSManagedObjectContext *parentObjectContext;
@property (nonatomic,strong) NSManagedObjectContext *privateObjectContext;
@property (nonatomic,strong) LSFractal              *privateFractal;

@property (nonatomic,assign) BOOL                   pathNeedsGenerating;


@property (nonatomic,assign,readwrite) CGRect       bounds;
@property (nonatomic,assign) CFDictionaryRef        cachedDrawingFunctions;
@property (nonatomic,strong) NSArray*               cachedLineColors;
@property (nonatomic,strong) NSArray*               cachedFillColors;
@property (nonatomic,strong) UIColor*               defaultColor;

@property (nonatomic,assign) BOOL                   controlPointOn;
@property (nonatomic,assign) CGPoint                controlPointNode;
@property (nonatomic,assign) CGPoint                previousNode;


@property (nonatomic,strong) UIImage*               cachedImage;
@property (nonatomic,strong) NSMutableDictionary*   cachedSelectors;

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
        _bounds = CGRectZero;
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
        if (!(self.forceLevel > -1 && [keyPath isEqualToString: @"level"])) {
            [self productionRuleChanged];
            [self cacheColors: _fractal];
            [self cacheLineEnds: _fractal];
        }
        
        
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
    
    return [NSString stringWithFormat: @"<%@: fractal = %@; forceLevel = %g; bounds = %@>",
            NSStringFromClass([self class]),
            self.fractal,
            self.forceLevel,
            boundsDescription];
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
    CGRect tileBoundingRect = CGContextGetClipBoundingBox(theContext);
    CGRect tempRect = theLayer.bounds;
    CGRect layerBounds = CGRectMake(tempRect.origin.x, tempRect.origin.y, tempRect.size.width, tempRect.size.height);
    [self.privateObjectContext performBlockAndWait:^{
        [self recursiveDrawInBounds: layerBounds withContext: theContext flipped: [theLayer contentsAreFlipped]];
    }];
    
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
    
    
    newSegment.lineColorIndex = 0;
    newSegment.fillColorIndex = 0;
    
    newSegment.lineLength = [self.privateFractal lineLengthAsDouble];
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

-(CFDictionaryRef) cachedDrawingFunctions {
    if (_cachedDrawingFunctions == nil) {
        
        NSPointerFunctionsOptions keyOptions=NSPointerFunctionsStrongMemory |
        NSPointerFunctionsObjectPersonality | NSPointerFunctionsCopyIn;
        NSPointerFunctionsOptions valueOptions=NSPointerFunctionsOpaqueMemory |
        NSPointerFunctionsOpaquePersonality;
        
        CFIndex commandCount = 8;
        
        char* commands[commandCount];
        MBFractalCommandFunction functions[commandCount];
        
        commands[0] = "commandDoNothing";
        functions[0] = MBCGCommandDoNothingOnSegment;

        commands[1] = "commandDrawLine";
        functions[1] = MBCGCommandDrawLineOnSegment;

        commands[2] = "commandMoveByLine";
        functions[2] = MBCGCommandMoveByLineOnSegment;

        commands[3] = "commandRotateCC";
        functions[3] = MBCGCommandRotateCCOnSegment;

        commands[4] = "commandRotateC";
        functions[4] = MBCGCommandRotateCOnSegment;

        commands[5] = "commandStrokeOn";
        functions[5] = MBCGCommandStrokeOnOnSegment;

        commands[6] = "commandStrokeOff";
        functions[6] = MBCGCommandStrokeOffOnSegment;

        commands[7] = "commandFillOn";
        functions[7] = MBCGCommandFillOnOnSegment;

        commands[8] = "commandFillOff";
        functions[8] = MBCGCommandFillOffOnSegment;
        
        _cachedDrawingFunctions = CFDictionaryCreate(NULL, (const void**)commands, (const void**)functions, commandCount, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        

    }
    return _cachedDrawingFunctions;
}

-(void) clearCache {
    self.cachedDrawingFunctions = nil;
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
    self.pathNeedsGenerating = YES;
}

#pragma mark path generation

-(void) geometryChanged {
    self.pathNeedsGenerating = YES;
}

-(void) recursiveDrawInBounds:(CGRect)layerBounds withContext:(CGContextRef)theContext flipped:(BOOL)isFlipped {
    NSDate *methodStart;
    
    NSTimeInterval executionTime = 0.0;
    __block NSTimeInterval productExecutionTime = 0.0;
    __block NSTimeInterval pathExecutionTime = 0.0;
    
    // Following is because layerBounds value disappears after 1st if statement line below.
    // cause totally unknown.
//    CGRect localBounds = layerBounds;
    
    CGContextSaveGState(theContext);
    
    methodStart = [NSDate date];
    
    // Start path generation
    // ---------
    
    [self createFractalLevel: 1 withContext: theContext];
    
    // ---------
    // End path generation
    
    CGContextRestoreGState(theContext);
    
//    NSDate *methodFinish = [NSDate date];
//    executionTime = floorf(1000.0*[methodFinish timeIntervalSinceDate:methodStart]);
    
}

-(void) createFractalLevel: (NSUInteger) level withContext: (CGContextRef) cgContext{
    NSOrderedSet* rules = self.fractal.startingRules;
    
    CGMutablePathRef fractalPath = CGPathCreateMutable();
    CGPathMoveToPoint(fractalPath, NULL, 0.0f, 0.0f);
    
    MBSegmentStruct startingSegment = [self initialSegment];
    startingSegment.path = fractalPath;
    startingSegment.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -[self.privateFractal.baseAngle floatValue]);

    [self segment: startingSegment recursiveReplacementOf: rules replacements: self.cachedReplacementRules currentLevel: 0 desiredLevel: level];
    
    
    startingSegment.path = nil;
    CGPathRelease(fractalPath);
}

/*
 A
 A+BF+
 -FA-B
 
 0: A
 1: A+BF+
 2: A+BF++-FA-BF+
 
 */

-(void) segment: (MBSegmentStruct)segment recursiveReplacementOf: (NSOrderedSet*) rules replacements: (NSDictionary*) replacementRules currentLevel: (NSUInteger) currentLevel desiredLevel: (NSUInteger) desiredLevel {
    
    CGContextRef localContext = segment.context;
    
//    for (LSDrawingRule* rule in rules) {
//        //
//        if (currentLevel < desiredLevel) {
//            // replace if necessary
//            LSReplacementRule* replacementRule = replacementRules[rule.productionString];
//            if (replacementRule) {
//                NSOrderedSet* newRules = replacementRule.rules;
//                CGContextRef newContext = [self cgContext: localContext recursiveReplacementOf: newRules replacements: replacementRules currentLevel: currentLevel+1 desiredLevel: desiredLevel];
//                if (localContext) {
//                    localContext = newContext;
//                }
//            } else {
//                // no replacement rule so just use the rule for a node
//                id node = [self evaluateRule: rule.productionString withParent: localParentNode withName: rule.productionString];
//                if (node) {
//                    localParentNode = node;
//                }
//            }
//        } else {
//            // return node for current rule
//            id node = [self evaluateRule: rule.productionString withParent: localParentNode withName: rule.productionString];
//            if (node) {
//                localParentNode = node;
//            }
//        }
//    }
//    
    return localContext;
}


-(void) evaluateRule:(NSString *)rule onSegment: (MBSegmentStruct) segment{
    //
    MBFractalCommandFunction commandFunction = CFDictionaryGetValue(self.cachedDrawingFunctions, (__bridge const void *)(rule));
    if (commandFunction != NULL) {
        commandFunction(segment);
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


void MBCGDrawCircle(MBSegmentStruct segment, CGFloat radius) {
    CGAffineTransform local = segment.transform;
    CGPathAddEllipseInRect(segment.path, &local, CGRectMake(0.0, -radius, radius*2.0, radius*2.0));
    CGPathMoveToPoint(segment.path, &local, radius*2.0, 0.0);
}

void MBCGDrawSquare(MBSegmentStruct segment, CGFloat width) {
    CGAffineTransform local = segment.transform;
    CGPathAddRect(segment.path, &local, CGRectMake(0.0, -width/2.0, width, width));
    CGPathMoveToPoint(segment.path, &local, 0.0, 0.0);
}



#pragma mark Public Rule Methods

void MBCGCommandDoNothingOnSegment(MBSegmentStruct segment) {
}

void MBCGCommandDrawLineOnSegment(MBSegmentStruct segment) {
    CGFloat tx = segment.lineLength;
    CGAffineTransform local = segment.transform;
    
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
    CGPathAddLineToPoint(segment.path, &local, tx, 0.0);
    //    }
    segment.transform = CGAffineTransformTranslate(segment.transform, tx, 0.0);
}

void MBCGCommandDrawLineVarLengthOnSegment(MBSegmentStruct segment) {
    CGFloat tx = segment.lineLength;
    CGAffineTransform local = segment.transform;
    
    //    if (self.controlPointOn) {
    //        CGAffineTransform inverted = CGAffineTransformInvert(local);
    //        CGPoint p1 = CGPointApplyAffineTransform(self.previousNode, inverted);
    //        CGPoint cp0 = CGPointApplyAffineTransform(self.controlPointNode, inverted);
    //        //        CGPoint cp1 =
    //        CGPathAddCurveToPoint(segment.path, &local, cp0.x, cp0.y, cp0.x, cp0.y, tx, 0.0);
    //        self.controlPointOn = NO;
    //    } else {
    CGPathAddLineToPoint(segment.path, &local, tx, 0.0);
    //    }
    segment.transform = CGAffineTransformTranslate(segment.transform, tx, 0.0);
}

void MBCGCommandMoveByLineOnSegment(MBSegmentStruct segment) {
    CGFloat tx = segment.lineLength;
    CGAffineTransform local = segment.transform;
    CGPathMoveToPoint(segment.path, &local, tx, 0.0);
    segment.transform = CGAffineTransformTranslate(segment.transform, tx, 0.0);
}

void MBCGCommandRotateCCOnSegment(MBSegmentStruct segment) {
    CGFloat theta = segment.turningAngle;
    segment.transform = CGAffineTransformRotate(segment.transform, -theta);
}

void MBCGCommandRotateCOnSegment(MBSegmentStruct segment) {
    CGFloat theta = segment.turningAngle;
    segment.transform = CGAffineTransformRotate(segment.transform, theta);
}

void MBCGCommandReverseDirectionOnSegment(MBSegmentStruct segment) {
    segment.transform = CGAffineTransformRotate(segment.transform, M_PI);
}
void MBCGCommandCurveCOnSegment(MBSegmentStruct segment) {
    MBCGCommandCurvePointOnSegment(segment);
    MBCGCommandRotateCOnSegment(segment);
    MBCGCommandDrawLineOnSegment(segment);
}
void MBCGCommandCurveCCOnSegment(MBSegmentStruct segment) {
    MBCGCommandCurvePointOnSegment(segment);
    MBCGCommandRotateCCOnSegment(segment);
    MBCGCommandDrawLineOnSegment(segment);
}
void MBCGCommandCurvePointOnSegment(MBSegmentStruct segment) {
    //    self.previousNode = CGPathGetCurrentPoint(segment.path);
    //
    //    CGFloat tx = segment.lineLength;
    //    segment.transform = CGAffineTransformTranslate(segment.transform, tx, 0.0);
    //
    //    CGAffineTransform local = segment.transform;
    //
    //    self.controlPointNode = CGPointApplyAffineTransform(CGPointMake(0.0, 0.0), local);
    //    self.controlPointOn = YES;
}

void MBCGCommandPushOnSegment(MBSegmentStruct segment) {
    //    [self pushSegment];
}

void MBCGCommandPopOnSegment(MBSegmentStruct segment) {
    //    [self popSegment];
}
/*!
 Assume lineWidthIncrement is a percentage like 10% means add 10% or subtract 10%
 */
void MBCGCommandIncrementLineWidthOnSegment(MBSegmentStruct segment) {
    if (segment.lineChangeFactor > 0) {
        segment.lineWidth += segment.lineWidth * segment.lineChangeFactor;
    }
}

void MBCGCommandDecrementLineWidthOnSegment(MBSegmentStruct segment) {
    if (segment.lineChangeFactor > 0) {
        segment.lineWidth -= segment.lineWidth * segment.lineChangeFactor;
    }
}

void MBCGCommandDrawDotOnSegment(MBSegmentStruct segment) {
    MBCGDrawCircle(segment, segment.lineWidth);
}
void MBCGCommandDrawDotFilledNoStrokeOnSegment(MBSegmentStruct segment) {
    MBCGCommandPushOnSegment(segment);
    MBCGCommandStrokeOffOnSegment(segment);
    MBCGCommandFillOnOnSegment(segment);
    MBCGCommandDrawDotOnSegment(segment);
    MBCGCommandPopOnSegment(segment);
}

void MBCGCommandOpenPolygonOnSegment(MBSegmentStruct segment) {
    MBCGCommandPushOnSegment(segment);
    MBCGCommandStrokeOffOnSegment(segment);
    MBCGCommandFillOnOnSegment(segment);
}

void MBCGCommandClosePolygonOnSegment(MBSegmentStruct segment) {
    MBCGCommandPopOnSegment(segment);
}
#pragma message "TODO: remove length scaling in favor of just manipulating the aspect ration with width"
void MBCGCommandUpscaleLineLengthOnSegment(MBSegmentStruct segment) {
    if (segment.lineChangeFactor > 0) {
        segment.lineLength += segment.lineLength * segment.lineChangeFactor;
    }
}

void MBCGCommandDownscaleLineLengthOnSegment(MBSegmentStruct segment) {
    if (segment.lineChangeFactor > 0) {
        segment.lineLength -= segment.lineLength * segment.lineChangeFactor;
    }
}

void MBCGCommandSwapRotationOnSegment(MBSegmentStruct segment) {
    //    id tempMinusRule = (self.cachedDrawingRules)[@"-"];
    //    (self.cachedDrawingRules)[@"-"] = (self.cachedDrawingRules)[@"+"];
    //    (self.cachedDrawingRules)[@"+"] = tempMinusRule;
}

void MBCGCommandDecrementAngleOnSegment(MBSegmentStruct segment) {
    if (segment.turningAngleIncrement > 0) {
        segment.turningAngle -= segment.turningAngle * segment.turningAngleIncrement;
    }
}

void MBCGCommandIncrementAngleOnSegment(MBSegmentStruct segment) {
    if (segment.turningAngleIncrement > 0) {
        segment.turningAngle += segment.turningAngle * segment.turningAngleIncrement;
    }
}

void MBCGCommandStrokeOffOnSegment(MBSegmentStruct segment) {
    //    [self startNewSegment];
    segment.stroke = NO;
}

void MBCGCommandStrokeOnOnSegment(MBSegmentStruct segment) {
    //    [self startNewSegment];
    segment.stroke = YES;
}
void MBCGCommandFillOffOnSegment(MBSegmentStruct segment) {
    //    [self startNewSegment];
    segment.fill = NO;
}
void MBCGCommandFillOnOnSegment(MBSegmentStruct segment) {
    //    [self startNewSegment];
    segment.fill = YES;
}
void MBCGCommandRandomizeOffOnSegment(MBSegmentStruct segment) {
    segment.randomize = NO;
}
void MBCGCommandRandomizeOnOnSegment(MBSegmentStruct segment) {
    segment.randomize = YES;
}
void MBCGCommandNextColorOnSegment(MBSegmentStruct segment) {
    //    [self startNewSegment];
    segment.lineColorIndex = ++segment.lineColorIndex;
}
void MBCGCommandPreviousColorOnSegment(MBSegmentStruct segment) {
    //    [self startNewSegment];
    segment.lineColorIndex = --segment.lineColorIndex;
}
void MBCGCommandNextFillColorOnSegment(MBSegmentStruct segment) {
    //    [self startNewSegment];
    segment.fillColorIndex = ++segment.fillColorIndex;
}
void MBCGCommandPreviousFillColorOnSegment(MBSegmentStruct segment) {
    //    [self startNewSegment];
    segment.fillColorIndex = --segment.fillColorIndex;
}
void MBCGCommandLineCapButtOnSegment(MBSegmentStruct segment) {
    segment.lineCap = kCGLineCapButt;
}
void MBCGCommandLineCapRoundOnSegment(MBSegmentStruct segment) {
    segment.lineCap = kCGLineCapRound;
}
void MBCGCommandLineCapSquareOnSegment(MBSegmentStruct segment) {
    segment.lineCap = kCGLineCapSquare;
}
void MBCGCommandLineJoinMiterOnSegment(MBSegmentStruct segment) {
    segment.lineJoin = kCGLineJoinMiter;
}
void MBCGCommandLineJoinRoundOnSegment(MBSegmentStruct segment) {
    segment.lineJoin = kCGLineJoinRound;
}
void MBCGCommandLineJoinBevelOnSegment(MBSegmentStruct segment) {
    segment.lineJoin = kCGLineJoinBevel;
}

