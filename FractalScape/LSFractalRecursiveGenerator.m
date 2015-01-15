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
#define kLSMaxRules 256
#define kLSMaxCommandLength 64

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

@property (nonatomic,strong) NSManagedObjectID      *fractalID;
@property (nonatomic,strong) NSManagedObjectContext *privateObjectContext;

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
        _autoscale = NO;
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
        
        _fractalID = _fractal.objectID;
        _privateObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
        _privateObjectContext.parentContext = _fractal.managedObjectContext;
        
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
    
        __block NSPointerArray* tempArray;
        
        __block LSFractal* aPrivateFractal;
        NSManagedObjectID *mainID = _fractalID;
        NSManagedObjectContext* pcon = _privateObjectContext;
        
        [_privateObjectContext performBlockAndWait:^{
            aPrivateFractal = (LSFractal*)[pcon objectWithID: mainID];
            
            NSOrderedSet* rules = aPrivateFractal.drawingRulesType.rules;

            for (LSDrawingRule* rule in rules) {
                NSData* ruleData = [rule.productionString dataUsingEncoding: NSASCIIStringEncoding];
                char* ruleBytes = (char*)ruleData.bytes;
                char ruleIndex = ruleBytes[0];
                
                NSUInteger commandLength = rule.drawingMethodString.length;
                if (commandLength < kLSMaxCommandLength) {
                    NSData* ruleMethodData = [rule.drawingMethodString dataUsingEncoding: NSASCIIStringEncoding];
                    char* ruleString = (char*)ruleMethodData.bytes;
                    int i = 0;
                    for (i=0; i<commandLength; i++) {
                        self->_commandsStruct.command[ruleIndex][i] = ruleString[i];
                    }
                    self->_commandsStruct.command[ruleIndex][i] = 0; // null terminate
                } else {
                    NSAssert(YES, @"FractalScapeError: Rule CommandString '%@' is too long. Max length: %d, actual length: %lu",
                             rule.drawingMethodString,
                             kLSMaxCommandLength,
                             commandLength);
                }
             }
        }];
    // clear selectors
    int i = 0;
    for (i=0; i < kLSMaxRules; i++) {
        _selectorsStruct.selector[i] = NULL;
    }
}
-(void) clearCache {
    self.cachedImage = nil;
}

#pragma mark Fractal Property KVO
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
        
        __block UIColor* pageColor = [UIColor clearColor]; // default
        
        __block LSFractal* aPrivateFractal;
        NSManagedObjectID *mainID = _fractalID;
        NSManagedObjectContext* pcon = _privateObjectContext;
        
        [_privateObjectContext performBlockAndWait:^{
            aPrivateFractal = (LSFractal*)[pcon objectWithID: mainID];
            
            MBColor* mbPageColor = aPrivateFractal.backgroundColor;
            if (mbPageColor) {
                pageColor = [mbPageColor asUIColor];
            }
        }];

        
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
    
    [self.privateObjectContext reset];
    //            [self.privateObjectContext refreshObject: self.privateFractal mergeChanges: NO];

    _segmentIndex = 0;
    __block MBSegmentStruct newSegment;
    
    __block LSFractal* aPrivateFractal;
    NSManagedObjectID *mainID = _fractalID;
    NSManagedObjectContext* pcon = _privateObjectContext;
    
    [self.privateObjectContext performBlockAndWait:^{

        aPrivateFractal = (LSFractal*)[pcon objectWithID: mainID];

        newSegment.lineColorIndex = 0;
        newSegment.fillColorIndex = 0;
        
        newSegment.lineLength = [aPrivateFractal.lineLength floatValue];
        newSegment.lineLengthScaleFactor = [aPrivateFractal.lineLengthScaleFactor floatValue];
        
        newSegment.lineWidth = [aPrivateFractal.lineWidth floatValue];
        newSegment.lineWidthIncrement = [aPrivateFractal.lineWidthIncrement floatValue];
        
        newSegment.turningAngle = [aPrivateFractal turningAngleAsDouble];
        newSegment.turningAngleIncrement = [aPrivateFractal.turningAngleIncrement floatValue];
        
        newSegment.randomness = [aPrivateFractal.randomness floatValue];
        newSegment.lineChangeFactor = [aPrivateFractal.lineChangeFactor floatValue];
        
        newSegment.lineCap = kCGLineCapRound;
        newSegment.lineJoin = kCGLineJoinRound;
        
        newSegment.stroke = YES;
        newSegment.fill = NO;
        newSegment.EOFill = aPrivateFractal.eoFill ? [aPrivateFractal.eoFill boolValue] : NO;
        
        newSegment.drawingModeUnchanged = NO;
        
        newSegment.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -[aPrivateFractal.baseAngle floatValue]);
        
        newSegment.points[0] = CGPointMake(0.0, 0.0);
        newSegment.pointIndex = -1;
        
        newSegment.baseAngle = [aPrivateFractal.baseAngle floatValue];
        newSegment.context = aCGContext;
        
    }];
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
    NSMutableDictionary* tempDictionary = [[NSMutableDictionary alloc] initWithCapacity: _fractal.replacementRules.count];
    
    NSOrderedSet* replacementRules =  _fractal.replacementRules;
    for (LSReplacementRule* replacementRule in replacementRules) {
        [tempDictionary setObject: replacementRule forKey: replacementRule.contextRule.productionString];
    }
    
    self.cachedReplacementRules = [tempDictionary copy];
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

-(void) recursiveDrawInBounds:(CGRect)layerBounds withContext:(CGContextRef)cgContext flipped:(BOOL)isFlipped {
    NSDate *methodStart;
    
    NSTimeInterval executionTime = 0.0;
    
    __block NSTimeInterval pathExecutionTime = 0.0;
    
    // Following is because layerBounds value disappears after 1st if statement line below.
    // cause totally unknown.
    
    self.bounds = CGRectZero;
    
    CGRect localBounds = layerBounds;
    
    CGContextSaveGState(cgContext);
    
    methodStart = [NSDate date];
    
    // Start path generation
    // ---------
    
    if ((NO) || self.autoscale) {
        
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

    
    CGContextTranslateCTM(cgContext, CGRectGetMidX(layerBounds), CGRectGetMidY(layerBounds));
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self createFractalWithContext: cgContext];
    });
    
    // ---------
    // End path generation
    
    CGContextRestoreGState(cgContext);
    
    
    NSDate *methodFinish = [NSDate date];
    executionTime = 1000.0*[methodFinish timeIntervalSinceDate:methodStart];
    NSLog(@"Recursive total execution time: %.2fms", executionTime);
}
/*
 How to handle scaling?
 ** Two steps
    1. Create at a standard scale.
    2. Redraw at best scale.
    3. Change scale as necessary when changing properties but only draw once and cache scale.
 */
-(void) createFractalWithContext: (CGContextRef) aCGContext {
    
//    CGAffineTransform initialTransform = CGContextGetCTM(cgContext);
//    CGContextTranslateCTM(cgContext, self.translate.x, self.translate.y);
//    
//    CGContextScaleCTM(cgContext, self.scale, self.scale);

//    CGContextTranslateCTM(cgContext, 300.5, 300.5);
//    CGContextScaleCTM(cgContext, 0.1, 0.1);
    CGContextScaleCTM(aCGContext, -1.0, 1.0);

//    CGContextDrawImage(aCGContext, CGRectMake(-18, -18, 36, 36), [[UIImage imageNamed: @"controlDragCircle"] CGImage]);
    CGContextDrawImage(aCGContext, CGRectMake(-12, -12, 24, 24), [[UIImage imageNamed: @"controlDragCircle16px"] CGImage]);
    
    CGContextBeginPath(aCGContext);
    CGContextMoveToPoint(aCGContext, 0.5f, 0.5f);
    
    CGContextSetStrokeColorWithColor(aCGContext, [[UIColor blueColor] CGColor]);
    CGContextSetFillColorWithColor(aCGContext, [[UIColor yellowColor] CGColor]);
    
    [self initialiseSegmentWithContext: aCGContext];
    _segmentStack[_segmentIndex].noDrawPath = NO;
    
////    CGContextConcatCTM(cgContext, _currentSegment->transform);

    
    
    NSTimeInterval productExecutionTime = 0.0;
    NSDate *productionStart = [NSDate date];

    __block CGFloat localLevel;
    __block  NSString* levelCommandsArray;

    __block LSFractal* aPrivateFractal;
    NSManagedObjectID *mainID = _fractalID;
    NSManagedObjectContext* pcon = _privateObjectContext;
    
    [self.privateObjectContext performBlockAndWait:^{
        
        aPrivateFractal = (LSFractal*)[pcon objectWithID: mainID];
        
        localLevel = [aPrivateFractal.level floatValue];
        if (self.forceLevel >= 0) {
            localLevel = self.forceLevel;
        }
        
        
        if (localLevel == 0) {
            levelCommandsArray = aPrivateFractal.level0Rules;
        } else if (localLevel == 1) {
            levelCommandsArray = aPrivateFractal.level1Rules;
        } else if (localLevel == 2) {
            levelCommandsArray = aPrivateFractal.level2Rules;
        } else {
            levelCommandsArray = aPrivateFractal.levelNRules;
        }
    }];
    
    
    NSDate *productionFinish = [NSDate date];
    CGFloat productionTime = 1000.0*[productionFinish timeIntervalSinceDate: productionStart];
    NSLog(@"Recursive production time: %.2fms", productionTime);

    CGFloat scaleLevel = 4.0 / (localLevel + 1);
    CGContextScaleCTM(aCGContext, scaleLevel, scaleLevel);

    NSData* levelCommandsData = [levelCommandsArray dataUsingEncoding: NSASCIIStringEncoding];
    char* bytes = (char*)levelCommandsData.bytes;
    
    NSRange ruleRange = NSMakeRange(0, 1);
    for (long i=0; i < levelCommandsArray.length; i++) {
        ruleRange.location = i;
    
        char commandByte = bytes[i];
        
//        NSString* commandKey = [levelCommandsArray substringWithRange: ruleRange];
        if (commandByte > 0 && commandByte < kLSMaxRules) {
            //
            [self evaluateRule: commandByte];

        } else {
            break;
        }
    }
    
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
    char* commandCStr = _commandsStruct.command[rule];
    SEL cachedSelector = _selectorsStruct.selector[rule];
    if (!cachedSelector) {
        SEL uncachedSelector = NSSelectorFromString([NSString stringWithCString: commandCStr encoding: NSASCIIStringEncoding]);
        
        if ([self respondsToSelector: uncachedSelector]) {
            cachedSelector = uncachedSelector;
            _selectorsStruct.selector[rule] = cachedSelector;
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
        [self drawPath];
    }
    if (_segmentStack[_segmentIndex].pointIndex < 1) {
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
                CGContextDrawPath(_segmentStack[_segmentIndex].context, [self getSegmentDrawingMode]);
//            }
            
        }
        
        _segmentStack[_segmentIndex].pointIndex = -1;
    }
}

-(void) drawCircleRadius: (CGFloat) radius {
    CGRect transformedRect = CGRectApplyAffineTransform(CGRectMake(0.0, -radius, radius*2.0, radius*2.0), _segmentStack[_segmentIndex].transform);
    CGContextAddEllipseInRect(_segmentStack[_segmentIndex].context, transformedRect);
    CGContextDrawPath(_segmentStack[_segmentIndex].context, [self getSegmentDrawingMode]);
    [self segmentAddPoint: CGPointMake(radius*2.0, 0.0)];
}

-(void) drawSquareWidth: (CGFloat) width {
    CGRect transformedRect = CGRectApplyAffineTransform(CGRectMake(0.0, -width/2.0, width, width), _segmentStack[_segmentIndex].transform);
    CGContextAddRect(_segmentStack[_segmentIndex].context, transformedRect);
}



#pragma mark - Public Rule Draw Methods

-(void) commandDoNothing {
}

-(void) commandPush {
    [self drawPath]; // draw before saving state

    _segmentIndex++;
    _segmentStack[_segmentIndex] = _segmentStack[_segmentIndex-1];
}

-(void) commandPop {
    [self drawPath]; // draw before restoring previous state
    
    if (_segmentIndex > 0) {
        _segmentIndex--;
    }
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
    [self commandPush];
    [self commandStrokeOff];
    [self commandFillOn];
    [self commandDrawDot];
    [self commandPop];
}

-(void) commandOpenPolygon {
    [self commandPush];
}

-(void) commandClosePolygon {
    [self commandStrokeOff];
    [self commandFillOn];
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
    _segmentStack[_segmentIndex].stroke = NO;
}

-(void) commandStrokeOn {
    //    [self startNewSegment];
    _segmentStack[_segmentIndex].stroke = YES;
}
-(void) commandFillOff {
    //    [self startNewSegment];
    _segmentStack[_segmentIndex].fill = NO;
}
-(void) commandFillOn {
    //    [self startNewSegment];
    _segmentStack[_segmentIndex].fill = YES;
}
-(void) commandRandomizeOff {
    _segmentStack[_segmentIndex].randomize = NO;
}
-(void) commandRandomizeOn {
    _segmentStack[_segmentIndex].randomize = YES;
}
-(void) commandNextColor {
    //    [self startNewSegment];
    _segmentStack[_segmentIndex].lineColorIndex = ++_segmentStack[_segmentIndex].lineColorIndex;
}
-(void) commandPreviousColor {
    //    [self startNewSegment];
    _segmentStack[_segmentIndex].lineColorIndex = --_segmentStack[_segmentIndex].lineColorIndex;
}
-(void) commandNextFillColor {
    //    [self startNewSegment];
    _segmentStack[_segmentIndex].fillColorIndex = ++_segmentStack[_segmentIndex].fillColorIndex;
}
-(void) commandPreviousFillColor {
    //    [self startNewSegment];
    _segmentStack[_segmentIndex].fillColorIndex = --_segmentStack[_segmentIndex].fillColorIndex;
}
-(void) commandLineCapButt {
    _segmentStack[_segmentIndex].lineCap = kCGLineCapButt;
}
-(void) commandLineCapRound {
    _segmentStack[_segmentIndex].lineCap = kCGLineCapRound;
}
-(void) commandLineCapSquare {
    _segmentStack[_segmentIndex].lineCap = kCGLineCapSquare;
}
-(void) commandLineJoinMiter {
    _segmentStack[_segmentIndex].lineJoin = kCGLineJoinMiter;
}
-(void) commandLineJoinRound {
    _segmentStack[_segmentIndex].lineJoin = kCGLineJoinRound;
}
-(void) commandLineJoinBevel {
    _segmentStack[_segmentIndex].lineJoin = kCGLineJoinBevel;
}

@end


