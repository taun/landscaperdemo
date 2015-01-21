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
//#define LSDEBUGPERFORMANCE
//#define LSDEBUGPOSITION

struct MBCommandsStruct {
    char        command[kLSMaxRules][kLSMaxCommandLength];
};
typedef struct MBCommandsStruct MBCommandsStruct;

struct MBCommandSelectorsStruct {
    SEL        selector[kLSMaxRules];
};
typedef struct MBCommandSelectorsStruct MBCommandSelectorsStruct;


@interface LSFractalRecursiveGenerator () {
    CGFloat             _maxLineWidth;
    MBSegmentStruct     _segmentStack[kLSMaxLevels];
    NSUInteger          _segmentIndex;
    MBSegmentRef        _currentSegment;
    MBCommandsStruct    _commandsStruct;
    MBCommandSelectorsStruct _selectorsStruct;
}

@property (nonatomic,assign) BOOL                   pathNeedsGenerating;

@property (nonatomic,assign,readwrite) CGRect       bounds;
@property (nonatomic,strong) NSArray*               cachedLineUIColors;
@property (nonatomic,strong) NSArray*               cachedFillUIColors;
@property (nonatomic,strong) UIColor*               defaultColor;

@property (nonatomic,assign) BOOL                   controlPointOn;
@property (nonatomic,assign) CGPoint                controlPointNode;
@property (nonatomic,assign) CGPoint                previousNode;


@property (nonatomic,strong) UIImage*               cachedImage;
@property (nonatomic,strong) NSDictionary*          cachedReplacementRules;

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
        _showOrigin = YES;
        _translate = CGPointMake(0.0, 0.0);
        _bounds =  CGRectMake(0, 0, 300, 300);
        _defaultColor = [UIColor blueColor];
        _controlPointOn = NO;
        _segmentIndex = 0;
    }
    return self;
}

- (void) dealloc {
    // removes observer
    self.fractal = nil;
}
#pragma mark - getters setters
/* If fractal is not save, below will return nil for privateFractal. What to do? */
-(void) setFractal:(LSFractal *)fractal {
    if (_fractal != fractal) {
        
        [self removeObserverForFractal: _fractal];
        
        _fractal = fractal;
        
        [self cacheDrawingRules];
        [self addObserverForFractal: _fractal];
        [self productionRuleChanged];
    }
}
-(CGRect) bounds {
    // adjust for the lineWidth
    CGFloat margin = _maxLineWidth*2.0+1.0;
    CGRect result = CGRectInset(_bounds, -margin, -margin);
    return result;
    //    return _bounds;
}
/*!
 Needs to only be called from the main thread or passed the privateFractal on the privateFractal thread.
 If called on the private thread, what happens with the private thread colors.
 
 @param fractal the fractal with the colors to be cached.
 */
-(void) cacheColors: (LSFractal*)fractal {
    NSMutableArray* tempColors = [[NSMutableArray alloc] initWithCapacity: fractal.lineColors.count];
    
    for (MBColor* color in fractal.lineColors) {
        [tempColors addObject: color.asUIColor];
    }
    _cachedLineUIColors = [tempColors copy];
    
    tempColors = [[NSMutableArray alloc] initWithCapacity: fractal.fillColors.count];
    
    for (MBColor* color in fractal.fillColors) {
        [tempColors addObject: color.asUIColor];
    }
    
    _cachedFillUIColors = [tempColors copy];
}

-(void) cacheDrawingRules {
    
        NSPointerArray* tempArray;
        
//        __block LSFractal* self.fractal;
//        NSManagedObjectID *mainID = _fractalID;
//        NSManagedObjectContext* pcon = _privateObjectContext;
//        
//        [_privateObjectContext performBlockAndWait:^{
//            self.fractal = (LSFractal*)[pcon objectWithID: mainID];
    
            NSOrderedSet* rules = self.fractal.drawingRulesType.rules;

            for (LSDrawingRule* rule in rules) {
                unsigned char ruleIndex = rule.productionString.UTF8String[0];
                
                NSUInteger commandLength = rule.drawingMethodString.length;
                if (commandLength < kLSMaxCommandLength) {
                    strcpy(_commandsStruct.command[ruleIndex], rule.drawingMethodString.UTF8String);
                    
                } else {
                    NSAssert(YES, @"FractalScapeError: Rule CommandString '%@' is too long. Max length: %d, actual length: %lu",
                             rule.drawingMethodString,
                             kLSMaxCommandLength,
                             commandLength);
                }
             }
//        }];
    // clear selectors
    int i = 0;
    for (i=0; i < kLSMaxRules; i++) {
        _selectorsStruct.selector[i] = NULL;
    }
}
-(void) cacheReplacementRules {
    NSMutableDictionary* tempDictionary = [[NSMutableDictionary alloc] initWithCapacity: _fractal.replacementRules.count];
    
    NSOrderedSet* replacementRules =  _fractal.replacementRules;
    for (LSReplacementRule* replacementRule in replacementRules) {
        [tempDictionary setObject: replacementRule forKey: replacementRule.contextRule.productionString];
    }
    
    self.cachedReplacementRules = [tempDictionary copy];
}
-(void) clearCache {
    self.cachedImage = nil;
}

#pragma mark Fractal Property KVO
/* will this cause threading problems? */
-(void) addObserverForFractal:(LSFractal *)fractal {
    if (fractal) {
//        [fractal.managedObjectContext performBlock:^{
        
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
//        }];
    }
}
-(void) removeObserverForFractal:(LSFractal *)fractal {
    if (fractal) {
//        [fractal.managedObjectContext performBlock:^{
        
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
//        }];
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
        // appearanceChanged - need to redo everything but rules
        [self geometryChanged];
//        [self cacheLineEnds: _fractal];
        
    } else if ([[LSFractal redrawProperties] containsObject: keyPath]) {
        // bounds won't change for autoscaling but will need to redraw image.
        [self geometryChanged];
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
-(BOOL)hasImageSize:(CGSize)size {
    BOOL status = YES;
    if ((self.cachedImage == nil) || !CGSizeEqualToSize(self.cachedImage.size, size)) {
        status = NO;
    }
    return status;
}


-(CGColorRef) colorForIndex: (NSInteger)index inArray: (NSArray*) colorArray {
    CGFloat count = (CGFloat)colorArray.count;
    if (count == 0.0) {
        return self.defaultColor.CGColor;
    }
    
    NSInteger moddedIndex = (NSInteger)fabs(fmod((CGFloat)index, count));
    
    UIColor* newColor = colorArray[moddedIndex];
    
    if (!newColor) {
        newColor = self.defaultColor;
    }
    
    return newColor.CGColor;
}

#pragma mark - lazy init getters

-(void) initialiseSegmentWithContext: (CGContextRef)aCGContext {
    
    // Copy the fractal core data values to the segment
    
//    [self.privateObjectContext reset];
    //            [self.privateObjectContext refreshObject: self.privateFractal mergeChanges: NO];

    _segmentIndex = 0;
    MBSegmentStruct newSegment;
    
//    __block LSFractal* self.fractal;
//    NSManagedObjectID *mainID = _fractalID;
//    NSManagedObjectContext* pcon = _privateObjectContext;
//    
//    [self.privateObjectContext performBlockAndWait:^{
    
    //        self.fractal = (LSFractal*)[pcon objectWithID: mainID];
    
    newSegment.lineColorIndex = 0;
    newSegment.fillColorIndex = 0;
    
    newSegment.lineLength = [self.fractal.lineLength floatValue];
    newSegment.lineLengthScaleFactor = [self.fractal.lineLengthScaleFactor floatValue];
    
    newSegment.lineWidth = [self.fractal.lineWidth floatValue];
    newSegment.lineWidthIncrement = [self.fractal.lineWidthIncrement floatValue];
    
    newSegment.turningAngle = [self.fractal turningAngleAsDouble];
    newSegment.turningAngleIncrement = [self.fractal.turningAngleIncrement floatValue];
    
    newSegment.randomness = [self.fractal.randomness floatValue];
    newSegment.lineChangeFactor = [self.fractal.lineChangeFactor floatValue];
    
    newSegment.lineCap = kCGLineCapRound;
    newSegment.lineJoin = kCGLineJoinRound;
    
    newSegment.stroke = YES;
    newSegment.fill = NO;
    newSegment.EOFill = self.fractal.eoFill ? [self.fractal.eoFill boolValue] : NO;
    
    newSegment.drawingModeUnchanged = NO;
    
    newSegment.transform = CGAffineTransformRotate(CGAffineTransformIdentity, 0.0);//-[self.fractal.baseAngle floatValue]);
    
    newSegment.points[0] = CGPointMake(0.0, 0.0);
    newSegment.pointIndex = -1;
    
    newSegment.baseAngle = [self.fractal.baseAngle floatValue];
    newSegment.context = aCGContext;
    
    //    }];
    self->_segmentStack[0] = newSegment;

}

//-(void) setInitialTransform:(CGAffineTransform)transform {
//    _segmentStack[_segmentIndex].transform = transform;
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
    self.fractal.rulesUnchanged = NO;
    [self cacheReplacementRules];
    self.bounds = CGRectZero;

    [self geometryChanged];
}

#pragma mark path generation

-(void) geometryChanged {
    [self cacheColors: _fractal];
    
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
        
        UIColor* pageColor = [UIColor clearColor]; // default
        
        
        MBColor* mbPageColor = self.fractal.backgroundColor;
        if (mbPageColor) pageColor = [mbPageColor asUIColor];
        
        CGContextSaveGState(context);
        UIColor* thumbNailBackground = [UIColor colorWithCGColor: pageColor.CGColor];
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
-(void) recursiveDrawInBounds:(CGRect)imageBounds withContext:(CGContextRef)aCGContext flipped:(BOOL)isFlipped {
    NSDate *methodStart;
    
#ifdef LSDEBUGPERFORMANCE
    NSTimeInterval executionTime = 0.0;
    NSTimeInterval pathExecutionTime = 0.0;
    methodStart = [NSDate date];
#endif
    // Following is because imageBounds value disappears after 1st if statement line below.
    // cause totally unknown.
    
    CGRect localBounds = imageBounds;
    
    CGContextSaveGState(aCGContext);
    
    CGFloat yOrientation = isFlipped ? -1.0 : 1.0;

    CGFloat scale = 1.0;
    CGFloat translationX = 0.0;
    CGFloat translationY = 0.0;
    
    if (self.autoscale) {
        
        /*
         
         fractal segment transforms in order
            initial:    identity
            scale:      yOrientation
            rotate:     baseRotation - rotation is about (0,0) which in iOS is top left corner
         
         Record self.bounds applying segment transform fractalPoints to viewPoints
         
         +if Autoscaling
            translate:  toViewCenter
            scale:      scaleToFillView
            translate:  to -fractalCenter
         */
        
        [self findFractalUntransformedBoundsForContext: aCGContext flipped: isFlipped];
        
         // Scaling
        CGFloat scaleWidth = (localBounds.size.width-40.0)/self.bounds.size.width;
        CGFloat scaleHeight = (localBounds.size.height-40.0)/self.bounds.size.height;
        
        scale = MIN(scaleHeight, scaleWidth);
        
        // Translating
        CGFloat fractalCenterX = scale * CGRectGetMidX(self.bounds);
        CGFloat fractalCenterY = scale * CGRectGetMidY(self.bounds)*yOrientation; //130
        
        CGFloat viewCenterX = CGRectGetMidX(localBounds);
        CGFloat viewCenterY = CGRectGetMidY(localBounds)*yOrientation; // -434
        
        translationX = viewCenterX - fractalCenterX;
        translationY = viewCenterY - fractalCenterY;
        
#ifdef LSDEBUGPOSITION
        NSLog(@"\nBounds pre-autoscale layout: %@", NSStringFromCGRect(self.bounds));
#endif
    } else {
        CGContextTranslateCTM(aCGContext, CGRectGetMidX(imageBounds), CGRectGetMidY(imageBounds));
    }
    
    [self initialiseSegmentWithContext: aCGContext];
    _segmentStack[_segmentIndex].noDrawPath = NO;
    _segmentStack[_segmentIndex].transform = CGAffineTransformScale(_segmentStack[_segmentIndex].transform, 1.0, yOrientation);
    _segmentStack[_segmentIndex].transform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, translationX, translationY);
    _segmentStack[_segmentIndex].transform = CGAffineTransformScale(_segmentStack[_segmentIndex].transform, scale, scale);
    _segmentStack[_segmentIndex].transform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, [self.fractal.baseAngle floatValue]);

    if (self.showOrigin) {
        // origin markers
        CGContextSaveGState(aCGContext);
        {
            CGContextConcatCTM(aCGContext, _segmentStack[_segmentIndex].transform);
            UIImage* originDirectionImage = [UIImage imageNamed: @"kBIconRuleDrawLine"]; // kBIconRuleDrawLine  kNorthArrow
            CGRect originDirectionRect = CGRectMake(0.0, -(originDirectionImage.size.height/2.0)/scale, originDirectionImage.size.width/scale, originDirectionImage.size.height/scale);
            CGContextDrawImage(aCGContext, originDirectionRect, [originDirectionImage CGImage]);
            
            UIImage* originCircle = [UIImage imageNamed: @"controlDragCircle16px"];
            CGRect originCircleRect = CGRectMake(-(originCircle.size.width/2.0)/scale, -(originCircle.size.height/2.0)/scale, originCircle.size.width/scale, originCircle.size.height/scale);
            CGContextDrawImage(aCGContext, originCircleRect, [originCircle CGImage]);

        }
        CGContextRestoreGState(aCGContext);
    }


    [self createFractalWithContext: aCGContext];
#ifdef LSDEBUGPOSITION
    NSLog(@"Bounds post-autoscale layout: %@", NSStringFromCGRect(self.bounds));
#endif

    CGContextRestoreGState(aCGContext);
    
#ifdef LSDEBUGPERFORMANCE
        NSDate *methodFinish = [NSDate date];
        executionTime = 1000.0*[methodFinish timeIntervalSinceDate:methodStart];
        NSLog(@"Recursive total execution time: %.2fms", executionTime);
#endif
}
-(void) findFractalUntransformedBoundsForContext: (CGContextRef) aCGContext flipped:(BOOL)isFlipped {
    CGFloat yOrientation = isFlipped ? -1.0 : 1.0;

    [self initialiseSegmentWithContext: aCGContext];
    _segmentStack[_segmentIndex].noDrawPath = YES;
    _segmentStack[_segmentIndex].transform = CGAffineTransformScale(_segmentStack[_segmentIndex].transform, 1.0, yOrientation);
    _segmentStack[_segmentIndex].transform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, [self.fractal.baseAngle floatValue]);
    self.bounds = CGRectZero;
    
    CGContextSaveGState(aCGContext);
    [self createFractalWithContext: aCGContext];
    CGContextRestoreGState(aCGContext);
}
/*
 How to handle scaling?
 ** Two steps
    1. Create at a standard scale.
    2. Redraw at best scale.
    3. Change scale as necessary when changing properties but only draw once and cache scale.
 */
-(void) createFractalWithContext: (CGContextRef) aCGContext {

#ifdef LSDEBUGPERFORMANCE
    NSTimeInterval productExecutionTime = 0.0;
    NSDate *productionStart = [NSDate date];
#endif
    
    CGFloat localLevel;
    NSData* levelXRuleData;
    
    localLevel = [self.fractal.level floatValue];
    if (self.forceLevel >= 0) {
        localLevel = self.forceLevel;
    }
    
    
    if (localLevel == 0) {
        levelXRuleData = self.fractal.level0Rules;
    } else if (localLevel == 1) {
        levelXRuleData = self.fractal.level1Rules;
    } else if (localLevel == 2) {
        levelXRuleData = self.fractal.level2Rules;
    } else {
        levelXRuleData = self.fractal.levelNRules;
    }
    
#ifdef LSDEBUGPERFORMANCE
    NSDate *productionFinish = [NSDate date];
    CGFloat productionTime = 1000.0*[productionFinish timeIntervalSinceDate: productionStart];
    NSLog(@"Recursive production time: %.2fms", productionTime);
#endif
    
    CGContextBeginPath(aCGContext);
    CGContextMoveToPoint(aCGContext, 0.0f, 0.0f);
    
    CGContextSetStrokeColorWithColor(aCGContext, [[UIColor blueColor] CGColor]);
    CGContextSetFillColorWithColor(aCGContext, [[UIColor yellowColor] CGColor]);
    
    char* bytes = (char*)levelXRuleData.bytes;
    
    for (long i=0; i < levelXRuleData.length; i++) {[self evaluateRule: bytes[i]];}
    
    [self drawPath];
    
//    NSLog(@"Bounds: %@", NSStringFromCGRect(_bounds));
    
//    [self segment: &startingSegment recursiveReplacementOf: rules replacements: self.cachedReplacementRules currentLevel: 0 desiredLevel: level];

//    CGRect pathBounds = CGContextGetPathBoundingBox(_currentSegment->context); // path based on current transform! 0,0 is top left corner of screen
    
//    CGAffineTransform pathTransform = CGContextGetCTM(_currentSegment->context);
//    CGAffineTransform pathInverse = CGAffineTransformInvert(pathTransform);
//    CGRect normalizedRect = CGRectApplyAffineTransform(CGRectApplyAffineTransform(pathBounds, initialTransform ), pathInverse);
    
//    CGRect deviceBounds = CGContextConvertRectToDeviceSpace(_currentSegment->context, pathBounds);
//    CGRect tempBounds = CGRectUnion(_bounds, deviceBounds);
//    self.bounds = CGRectEqualToRect(tempBounds, CGRectNull) ? CGRectZero : tempBounds;
//    NSLog(@"Fractal \nPathBounds:\t %@;\nNorm Bounds:\t %@;\nTotal bounds: %@", NSStringFromCGRect(pathBounds), NSStringFromCGRect(normalizedRect),NSStringFromCGRect(tempBounds));
    
//    CGRect pathBounds = CGContextGetPathBoundingBox(cgContext);
//    NSLog(@"Path Bounds: %@", NSStringFromCGRect(pathBounds));
//    NSLog(@"LineLength: %f; LineWidth: %f",_currentSegment->lineLength, _currentSegment->lineWidth);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(void) evaluateRule:(char)rule {
    //
    SEL cachedSelector = _selectorsStruct.selector[rule];
    if (!cachedSelector) {
        NSString* selectorString = [NSString stringWithUTF8String: _commandsStruct.command[rule]];
        SEL uncachedSelector = NSSelectorFromString(selectorString);
        
        if ([self respondsToSelector: uncachedSelector]) {
            cachedSelector = uncachedSelector;
            _selectorsStruct.selector[rule] = cachedSelector;
        } else {
            NSLog(@"FractalScape error: missing command for key '%@'",selectorString);
            return;
        }
    }
    [self performSelector: cachedSelector];
}


//-(void) dispatchDrawingSelectorFromCString:(char*)selector {
//    // Using cached selectors was a 50% performance improvement. Calling NSSelectorFromString is very expensive.
//    SEL cachedSelector = [[self.cachedSelectors objectForKey: selector] pointerValue];
//    
//    if (!cachedSelector) {
//        SEL uncachedSelector = NSSelectorFromString(selector);
//        
//        if ([self respondsToSelector: uncachedSelector]) {
//            cachedSelector = uncachedSelector;
//            [self.cachedSelectors setObject: [NSValue valueWithPointer: uncachedSelector] forKey: selector];
//        }
//    }
//    
//    [self performSelector: cachedSelector];
//    
//}

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

-(void) updateBoundsWithPoint: (CGPoint) aPoint {
    CGRect tempBounds = CGRectUnion(_bounds, CGRectMake(aPoint.x, aPoint.y, 1.0, 1.0));
    _bounds = CGRectEqualToRect(tempBounds, CGRectNull) ? CGRectZero : tempBounds;
}
/*!
 static inline without method dispatch saves 50ms out of 850ms.
 
 @param bounds old bounds
 @param aPoint point to add to bounds
 
 @return new potentially larger bounds
 */
static inline CGRect inlineUpdateBounds(CGRect bounds, CGPoint aPoint) {
    CGRect tempBounds = CGRectUnion(bounds, CGRectMake(aPoint.x, aPoint.y, 1.0, 1.0));
    return CGRectEqualToRect(tempBounds, CGRectNull) ? CGRectZero : tempBounds;
}
//TODO: why is this called. somehow related to adding a subview to LevelN view.
// When the subview is touched even "charge" gets called to the delegate which seems to be the generator even though the generator is only the delegate of the LevelN view layer.
//-(void) charge {
//    
//    NSLog(@"Charge called");
//}

#pragma mark - Segment routines

-(void) segmentAddPoint: (CGPoint) aUserPoint {
//    [self updateBoundsWithPoint: aUserPoint];
    
    if (_segmentStack[_segmentIndex].pointIndex >= (kLSMaxSegmentPointsSize-1)) {
        CGContextAddLines(_segmentStack[_segmentIndex].context,_segmentStack[_segmentIndex].points,_segmentStack[_segmentIndex].pointIndex+1);
        _segmentStack[_segmentIndex].pointIndex = -1;
    }
    if (_segmentStack[_segmentIndex].pointIndex < 0) {
        // no start point so add default (0,0)
        CGPoint transformedSPoint = CGPointApplyAffineTransform(CGPointMake(0.0, 0.0), _segmentStack[_segmentIndex].transform);
        _segmentStack[_segmentIndex].pointIndex += 1;
        _segmentStack[_segmentIndex].points[_segmentStack[_segmentIndex].pointIndex] = transformedSPoint;
    }

    CGPoint transformedPoint = CGPointApplyAffineTransform(aUserPoint, _segmentStack[_segmentIndex].transform);
    _segmentStack[_segmentIndex].pointIndex += 1;
    _segmentStack[_segmentIndex].points[_segmentStack[_segmentIndex].pointIndex] = transformedPoint;
    
    _bounds = inlineUpdateBounds(_bounds, transformedPoint);
}

-(NSUInteger) segmentPointCount {
    return _segmentStack[_segmentIndex].pointIndex + 1;
}

-(CGPathDrawingMode) getSegmentDrawingMode {
    
    if (!_segmentStack[_segmentIndex].drawingModeUnchanged) {
        BOOL stroke = _segmentStack[_segmentIndex].stroke;
        BOOL fill = _segmentStack[_segmentIndex].fill;
        BOOL eoFill = _segmentStack[_segmentIndex].EOFill;
        
        CGPathDrawingMode strokeOrFill = kCGPathStroke;
        
        if (fill && stroke) {
            strokeOrFill = eoFill ? kCGPathEOFillStroke : kCGPathFillStroke;
        } else if (stroke && !fill) {
            strokeOrFill = kCGPathStroke;
        } else if (fill && !stroke) {
            strokeOrFill = eoFill ? kCGPathEOFill : kCGPathFill;
        }
        
        _segmentStack[_segmentIndex].mode = strokeOrFill;
    }
    return _segmentStack[_segmentIndex].mode;
}

-(void) setCGGraphicsStateFromCurrentSegment {
    CGContextSetLineJoin(_segmentStack[_segmentIndex].context, _segmentStack[_segmentIndex].lineJoin);
    CGContextSetLineCap(_segmentStack[_segmentIndex].context, _segmentStack[_segmentIndex].lineCap);
    CGContextSetLineWidth(_segmentStack[_segmentIndex].context, _segmentStack[_segmentIndex].lineWidth);
    CGContextSetFillColorWithColor(_segmentStack[_segmentIndex].context, [self colorForIndex: _segmentStack[_segmentIndex].fillColorIndex inArray: self.cachedFillUIColors]);
    CGContextSetStrokeColorWithColor(_segmentStack[_segmentIndex].context, [self colorForIndex: _segmentStack[_segmentIndex].lineColorIndex inArray: self.cachedLineUIColors]);
}

#pragma mark - Private Draw Methods
-(void) drawPath {
    
    if (_segmentStack[_segmentIndex].pointIndex > 0) {
        // need at least two points
        if (!_segmentStack[_segmentIndex].noDrawPath) {
            [self setCGGraphicsStateFromCurrentSegment];
            
            // Not worth using CGContextStrokeLineSegments
//            CGPathDrawingMode mode = [self getSegmentDrawingMode];
//            if (mode == kCGPathStroke) {
//                // use faster drawing
//                CGPoint p1;
//                CGPoint p2;
//                long pointsCount = _segmentStack[_segmentIndex].pointIndex + 1;
//                long di = 0;
//                CGPoint doubledPoints[2*pointsCount];
//                for (long i=1; i < pointsCount; i++) {
//                    di = 2*i;
//                    doubledPoints[di-2] = _segmentStack[_segmentIndex].points[i-1];
//                    doubledPoints[di-1] = _segmentStack[_segmentIndex].points[i];
//                }
//                CGContextStrokeLineSegments(_segmentStack[_segmentIndex].context, doubledPoints, di);
//            } else {
            // need to fill
            CGContextAddLines(_segmentStack[_segmentIndex].context,_segmentStack[_segmentIndex].points,_segmentStack[_segmentIndex].pointIndex+1);
            _segmentStack[_segmentIndex].pointIndex = -1;
            CGContextDrawPath(_segmentStack[_segmentIndex].context, [self getSegmentDrawingMode]);
//            }
            
        }
        
    }
}

-(void) drawCircleRadius: (CGFloat) radius {
    [self setCGGraphicsStateFromCurrentSegment];
    CGRect transformedRect = CGRectApplyAffineTransform(CGRectMake(0.0, -radius, radius*2.0, radius*2.0), _segmentStack[_segmentIndex].transform);
    CGContextAddEllipseInRect(_segmentStack[_segmentIndex].context, transformedRect);
    CGContextDrawPath(_segmentStack[_segmentIndex].context, [self getSegmentDrawingMode]);
    [self segmentAddPoint: CGPointMake(radius*2.0, 0.0)];
}

-(void) drawSquareWidth: (CGFloat) width {
    [self setCGGraphicsStateFromCurrentSegment];
    CGRect transformedRect = CGRectApplyAffineTransform(CGRectMake(0.0, -width/2.0, width, width), _segmentStack[_segmentIndex].transform);
    CGContextAddRect(_segmentStack[_segmentIndex].context, transformedRect);
}

#pragma mark - Public Rule Draw Methods

-(void) commandDoNothing {
}

-(void) commandPush {
    [self drawPath]; // draw before saving state

    _segmentIndex = _segmentIndex < kLSMaxSegmentStackSize ? ++_segmentIndex : _segmentIndex;
    _segmentStack[_segmentIndex] = _segmentStack[_segmentIndex-1];
    NSAssert(_segmentIndex >= 0 && _segmentIndex < kLSMaxSegmentStackSize, @"_segmentIndex out of range!");
}

-(void) commandPop {
    [self drawPath]; // draw before restoring previous state
    
    _segmentIndex = _segmentIndex > 0 ? --_segmentIndex : _segmentIndex;
    NSAssert(_segmentIndex >= 0 && _segmentIndex < kLSMaxSegmentStackSize, @"_segmentIndex out of range!");
}

-(void) commandDrawLine {
    
    CGFloat tx = _segmentStack[_segmentIndex].lineLength;
    [self segmentAddPoint: CGPointMake(tx, 0.0)];
    
    CGAffineTransform newTransform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, tx, 0.0);
    _segmentStack[_segmentIndex].transform = newTransform;
    
    //    if (self.controlPointOn) {
    //        CGAffineTransform inverted = CGAffineTransformInvert(local);
    //        CGPoint p1 = CGPointApplyAffineTransform(self.previousNode, inverted);
    //        CGPoint cp0 = CGPointApplyAffineTransform(self.controlPointNode, inverted);
    //        //        CGPoint cp1 =
    //        //        CGPathAddCurveToPoint(_segmentStack[_segmentIndex].path, &local, cp0.x, cp0.y, cp0.x, cp0.y, tx, 0.0);
    //        CGPathAddArcToPoint(_segmentStack[_segmentIndex].path, &local, cp0.x, cp0.y, tx, 0.0, tx);
    //        CGPathAddLineToPoint(_segmentStack[_segmentIndex].path, &local, tx, 0.0);
    //        self.controlPointOn = NO;
    //    } else {
//    CGContextAddLineToPoint(aCGContext, tx, 0.0);
    //    }
//    CGContextTranslateCTM(aCGContext, tx, 0.0);
}

-(void) commandDrawLineVarLength {
    
    CGFloat tx = _segmentStack[_segmentIndex].lineLength;
    [self segmentAddPoint: CGPointMake(tx, 0.0)];
    
    CGAffineTransform newTransform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, tx, 0.0);
    _segmentStack[_segmentIndex].transform = newTransform;
    //    if (self.controlPointOn) {
    //        CGAffineTransform inverted = CGAffineTransformInvert(local);
    //        CGPoint p1 = CGPointApplyAffineTransform(self.previousNode, inverted);
    //        CGPoint cp0 = CGPointApplyAffineTransform(self.controlPointNode, inverted);
    //        //        CGPoint cp1 =
    //        CGPathAddCurveToPoint(_segmentStack[_segmentIndex].path, &local, cp0.x, cp0.y, cp0.x, cp0.y, tx, 0.0);
    //        self.controlPointOn = NO;
    //    } else {
//    CGContextAddLineToPoint(aCGContext, tx, 0.0);
    //    }
//    CGContextTranslateCTM(aCGContext, tx, 0.0);
}

-(void) commandMoveByLine {
    [self drawPath]; // Draw all points before moving on
    
    
    CGFloat tx = _segmentStack[_segmentIndex].lineLength;
    
    CGAffineTransform newTransform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, tx, 0.0);
    _segmentStack[_segmentIndex].transform = newTransform;

////   CGContextRef aCGContext = _segmentStack[_segmentIndex].context;
//    CGFloat tx = _segmentStack[_segmentIndex].lineLength;
//    CGContextMoveToPoint(aCGContext, tx, 0.0);
//    CGContextTranslateCTM(aCGContext, tx, 0.0);
}

-(void) commandRotateCC {

    CGFloat theta = _segmentStack[_segmentIndex].turningAngle;
    CGAffineTransform newTransform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, theta);
    _segmentStack[_segmentIndex].transform = newTransform;

    //    CGContextRotateCTM(aCGContext, theta);
}

-(void) commandRotateC {
    
    CGFloat theta = _segmentStack[_segmentIndex].turningAngle;
    CGAffineTransform newTransform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, -theta);
    _segmentStack[_segmentIndex].transform = newTransform;
}

-(void) commandReverseDirection {
    
    CGAffineTransform newTransform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, M_PI);
    _segmentStack[_segmentIndex].transform = newTransform;
}

-(void) commandCurveC {
    [self commandCurvePoint];
    [self commandRotateC];
    [self commandDrawLine];
}
-(void) commandCurveCC {
    [self commandCurvePoint];
    [self commandRotateCC];
    [self commandDrawLine];
}
-(void) commandCurvePoint {
    //    self.previousNode = CGPathGetCurrentPoint(_segmentStack[_segmentIndex].path);
    //
    //    CGFloat tx = _segmentStack[_segmentIndex].lineLength;
    //    _segmentStack[_segmentIndex].transform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, tx, 0.0);
    //
    //    CGAffineTransform local = _segmentStack[_segmentIndex].transform;
    //
    //    self.controlPointNode = CGPointApplyAffineTransform(CGPointMake(0.0, 0.0), local);
    //    self.controlPointOn = YES;
}

/*!
 Assume lineWidthIncrement is a percentage like 10% means add 10% or subtract 10%
 */
-(void) commandIncrementLineWidth {
    [self drawPath];
    
    
    if (_segmentStack[_segmentIndex].lineChangeFactor > 0) {
        _segmentStack[_segmentIndex].lineWidth += _segmentStack[_segmentIndex].lineWidth * _segmentStack[_segmentIndex].lineChangeFactor;
    }
}

-(void) commandDecrementLineWidth {
    [self drawPath];
    
    
    if (_segmentStack[_segmentIndex].lineChangeFactor > 0) {
        _segmentStack[_segmentIndex].lineWidth -= _segmentStack[_segmentIndex].lineWidth * _segmentStack[_segmentIndex].lineChangeFactor;
    }
}

-(void) commandDrawDot {
    [self drawCircleRadius: _segmentStack[_segmentIndex].lineWidth];
}
-(void) commandDrawDotFilledNoStroke {
//    [self commandPush];
    [self commandStrokeOff];
    [self commandFillOn];
    [self commandDrawDot];
//    [self commandPop];
}

-(void) commandOpenPolygon {
    [self commandPush];
    [self commandStrokeOff];
    [self commandFillOn];
}

-(void) commandClosePolygon {
    [self commandPop];
}
#pragma message "TODO: remove length scaling in favor of just manipulating the aspect ration with width"
-(void) commandUpscaleLineLength {
    [self drawPath];
    
    if (_segmentStack[_segmentIndex].lineChangeFactor > 0) {
        _segmentStack[_segmentIndex].lineLength += _segmentStack[_segmentIndex].lineLength * _segmentStack[_segmentIndex].lineChangeFactor;
    }
}

-(void) commandDownscaleLineLength {
    [self drawPath];
    
    if (_segmentStack[_segmentIndex].lineChangeFactor > 0) {
        _segmentStack[_segmentIndex].lineLength -= _segmentStack[_segmentIndex].lineLength * _segmentStack[_segmentIndex].lineChangeFactor;
    }
}

-(void) commandSwapRotation {
    //    id tempMinusRule = (self.cachedDrawingRules)[@"-"];
    //    (self.cachedDrawingRules)[@"-"] = (self.cachedDrawingRules)[@"+"];
    //    (self.cachedDrawingRules)[@"+"] = tempMinusRule;
}

-(void) commandDecrementAngle {
    [self drawPath];
    
    if (_segmentStack[_segmentIndex].turningAngleIncrement > 0) {
        _segmentStack[_segmentIndex].turningAngle -= _segmentStack[_segmentIndex].turningAngle * _segmentStack[_segmentIndex].turningAngleIncrement;
    }
}

-(void) commandIncrementAngle {
    [self drawPath];
    
    if (_segmentStack[_segmentIndex].turningAngleIncrement > 0) {
        _segmentStack[_segmentIndex].turningAngle += _segmentStack[_segmentIndex].turningAngle * _segmentStack[_segmentIndex].turningAngleIncrement;
    }
}

#pragma mark - block [] level drawing commands. IE. they do not force a draw
/*!
 Forcing the following draw commands to drawPath after setting would mess with fills.
 If the user wants a filled rectangle but they are dragging the fill or stroke or any of the following
 through the block, it would split the drawing operation into two separate draws eliminating the desired fill.
 */
-(void) commandStrokeOff {
    //    [self startNewSegment];
    [self drawPath];
    _segmentStack[_segmentIndex].stroke = NO;
}

-(void) commandStrokeOn {
    //    [self startNewSegment];
    [self drawPath];
    _segmentStack[_segmentIndex].stroke = YES;
}
-(void) commandFillOff {
    //    [self startNewSegment];
    [self drawPath];
    _segmentStack[_segmentIndex].fill = NO;
}
-(void) commandFillOn {
    //    [self startNewSegment];
    [self drawPath];
    _segmentStack[_segmentIndex].fill = YES;
}
-(void) commandRandomizeOff {
    [self drawPath];
    _segmentStack[_segmentIndex].randomize = NO;
}
-(void) commandRandomizeOn {
    [self drawPath];
    _segmentStack[_segmentIndex].randomize = YES;
}
-(void) commandNextColor {
    //    [self startNewSegment];
    [self drawPath];
    _segmentStack[_segmentIndex].lineColorIndex = ++_segmentStack[_segmentIndex].lineColorIndex;
}
-(void) commandPreviousColor {
    //    [self startNewSegment];
    [self drawPath];
    _segmentStack[_segmentIndex].lineColorIndex = --_segmentStack[_segmentIndex].lineColorIndex;
}
-(void) commandNextFillColor {
    //    [self startNewSegment];
    [self drawPath];
    _segmentStack[_segmentIndex].fillColorIndex = ++_segmentStack[_segmentIndex].fillColorIndex;
}
-(void) commandPreviousFillColor {
    //    [self startNewSegment];
    [self drawPath];
    _segmentStack[_segmentIndex].fillColorIndex = --_segmentStack[_segmentIndex].fillColorIndex;
}
-(void) commandLineCapButt {
    [self drawPath];
    _segmentStack[_segmentIndex].lineCap = kCGLineCapButt;
}
-(void) commandLineCapRound {
    [self drawPath];
    _segmentStack[_segmentIndex].lineCap = kCGLineCapRound;
}
-(void) commandLineCapSquare {
    [self drawPath];
    _segmentStack[_segmentIndex].lineCap = kCGLineCapSquare;
}
-(void) commandLineJoinMiter {
    [self drawPath];
    _segmentStack[_segmentIndex].lineJoin = kCGLineJoinMiter;
}
-(void) commandLineJoinRound {
    [self drawPath];
    _segmentStack[_segmentIndex].lineJoin = kCGLineJoinRound;
}
-(void) commandLineJoinBevel {
    [self drawPath];
    _segmentStack[_segmentIndex].lineJoin = kCGLineJoinBevel;
}

@end


