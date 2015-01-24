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

@property (nonatomic,assign,readwrite) CGRect       rawFractalPathBounds;
@property (nonatomic,strong) NSArray*               cachedLineUIColors;
@property (nonatomic,strong) NSArray*               cachedFillUIColors;
@property (nonatomic,strong) UIColor*               defaultColor;

@property (nonatomic,assign) BOOL                   controlPointOn;
@property (nonatomic,assign) CGPoint                controlPointNode;
@property (nonatomic,assign) CGPoint                previousNode;

@end

#pragma mark - Implementation

@implementation LSFractalRecursiveGenerator

+(instancetype) newGeneratorWithFractal:(LSFractal *)aFractal {
    LSFractalRecursiveGenerator* newGenerator = [[LSFractalRecursiveGenerator alloc] initWithFractal: aFractal];
    return newGenerator;
}

-(instancetype) initWithFractal: (LSFractal*) aFractal {
    self = [super init];
    if (self) {
        _scale = 1.0;
        _autoscale = YES;
        _showOrigin = YES;
        _translateX = 0.0;
        _translateY = 0.0;
        _rawFractalPathBounds =  CGRectZero;
        _defaultColor = [UIColor blueColor];
        _controlPointOn = NO;
        _segmentIndex = 0;
        _margin = 0;
        _backgroundColor = [UIColor clearColor];
        
        [self setValuesForFractal: aFractal];
    }
    return self;
}

- (instancetype)init {
    self = [self initWithFractal: nil];
    return self;
}

#pragma mark - getters setters
/* If fractal is not save, below will return nil for privateFractal. What to do? */
-(void) setValuesForFractal:(LSFractal *)aFractal {
    [self cacheColors: aFractal];
    [self cacheDrawingRules: aFractal];
    [self setBaseSegmentForFractal: aFractal];
}
/*!
 Needs to only be called from the main thread or passed the privateFractal on the privateFractal thread.
 If called on the private thread, what happens with the private thread colors.
 
 @param fractal the fractal with the colors to be cached.
 */
-(void) cacheColors: (LSFractal*)fractal {
    MBColor* background = fractal.backgroundColor;
    if (background) {
        _backgroundColor = [background asUIColor];
    } else {
        _backgroundColor = [UIColor clearColor];
    }
    
    
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

-(void) cacheDrawingRules: (LSFractal*)aFractal {
    
        NSPointerArray* tempArray;
        
//        __block LSFractal* self.fractal;
//        NSManagedObjectID *mainID = _fractalID;
//        NSManagedObjectContext* pcon = _privateObjectContext;
//        
//        [_privateObjectContext performBlockAndWait:^{
//            self.fractal = (LSFractal*)[pcon objectWithID: mainID];
    
            NSOrderedSet* rules = aFractal.drawingRulesType.rules;

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

-(NSString*) debugDescription {
    CFDictionaryRef boundsDict = CGRectCreateDictionaryRepresentation(_rawFractalPathBounds);
    NSString* boundsDescription = [(__bridge NSDictionary*)boundsDict description];
    CFRelease(boundsDict);
    
    return [NSString stringWithFormat: @"<%@: bounds = %@>",
            NSStringFromClass([self class]),
            boundsDescription];
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
-(void) setBaseSegmentForFractal: (LSFractal*)aFractal {
    _baseSegment.lineColorIndex = 0;
    _baseSegment.fillColorIndex = 0;
    
    _baseSegment.lineLength = [aFractal.lineLength floatValue];
    _baseSegment.lineLengthScaleFactor = [aFractal.lineLengthScaleFactor floatValue];
    
    _baseSegment.lineWidth = [aFractal.lineWidth floatValue];
    _baseSegment.lineWidthIncrement = [aFractal.lineWidthIncrement floatValue];
    
    _baseSegment.turningAngle = [aFractal turningAngleAsDouble];
    _baseSegment.turningAngleIncrement = [aFractal.turningAngleIncrement floatValue];
    
    _baseSegment.randomness = [aFractal.randomness floatValue];
    _baseSegment.lineChangeFactor = [aFractal.lineChangeFactor floatValue];
    
    _baseSegment.lineCap = kCGLineCapRound;
    _baseSegment.lineJoin = kCGLineJoinRound;
    
    _baseSegment.stroke = YES;
    _baseSegment.fill = NO;
    _baseSegment.EOFill = aFractal.eoFill ? [aFractal.eoFill boolValue] : NO;
    
    _baseSegment.drawingModeUnchanged = NO;
    
    _baseSegment.transform = CGAffineTransformRotate(CGAffineTransformIdentity, 0.0);//-[aFractal.baseAngle floatValue]);
    _baseSegment.scale = 1.0;
    
    _baseSegment.points[0] = CGPointMake(0.0, 0.0);
    _baseSegment.pointIndex = -1;
    
    _baseSegment.baseAngle = [aFractal.baseAngle floatValue];
}
-(void) initialiseSegmentWithContext: (CGContextRef)aCGContext {
    
    MBSegmentStruct newSegment = _baseSegment;
    newSegment.context = aCGContext;
    
    _segmentIndex = 0;
    _segmentStack[_segmentIndex] = newSegment;
}
-(void) generateImage {
    if (self.imageView && self.operation && self.operation.isCancelled) {
        return;
    }
    
    CGSize size = self.imageView ? self.imageView.bounds.size : self.imageBounds.size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, self.pixelScale);
    {
        CGContextRef aCGontext = UIGraphicsGetCurrentContext();
        [self drawInContext: aCGontext];
        self.image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    if (self.imageView && self.operation) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
//            [CATransaction begin];
//            [CATransaction setValue:(id)kCFBooleanTrue
//                             forKey:kCATransactionDisableActions];
            
            self.imageView.image = self.image;
            
//            [CATransaction commit];
        });
    }
}
-(void) fillBackgroundInContext: (CGContextRef)aCGContext {
    
    CGRect bounds = self.imageView ? self.imageView.bounds : self.imageBounds;

    CGContextSaveGState(aCGContext);
    {
        UIColor* thumbNailBackground = self.backgroundColor;
        [thumbNailBackground setFill];
        CGContextFillRect(aCGContext, bounds);
    }
    CGContextRestoreGState(aCGContext);
}
-(void) drawInContext:(CGContextRef)aCGContext {

    NSAssert(aCGContext, @"NULL Context being used. Context must be non-null.");
    
    [self fillBackgroundInContext: aCGContext];

    CGRect bounds = self.imageView ? self.imageView.bounds : self.imageBounds;

    NSDate *methodStart;
    
#ifdef LSDEBUGPERFORMANCE
    NSTimeInterval executionTime = 0.0;
    NSTimeInterval pathExecutionTime = 0.0;
    methodStart = [NSDate date];
#endif
    // Following is because imageBounds value disappears after 1st if statement line below.
    // cause totally unknown.

    CGContextSaveGState(aCGContext);
    
    CGFloat yOrientation = self.flipY ? -1.0 : 1.0;
    
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
        
        [self findFractalUntransformedBoundsForContext: aCGContext];
        
         // Scaling
        CGFloat scaleWidth = (bounds.size.width-2.0*self.margin)/self.rawFractalPathBounds.size.width;
        CGFloat scaleHeight = (bounds.size.height-2.0*self.margin)/self.rawFractalPathBounds.size.height;
        
        _scale = MIN(scaleHeight, scaleWidth);
        
        // Translating
        CGFloat fractalCenterX = _scale * CGRectGetMidX(self.rawFractalPathBounds);
        CGFloat fractalCenterY = _scale * CGRectGetMidY(self.rawFractalPathBounds)*yOrientation; //130
        
        CGFloat viewCenterX = CGRectGetMidX(bounds);
        CGFloat viewCenterY = CGRectGetMidY(bounds)*yOrientation; // -434
        
        _translateX = viewCenterX - fractalCenterX;
        _translateY = viewCenterY - fractalCenterY;
        
#ifdef LSDEBUGPOSITION
        NSLog(@"\nBounds pre-autoscale layout: %@", NSStringFromCGRect(self.rawFractalPathBounds));
#endif
    }
    
    [self initialiseSegmentWithContext: aCGContext];
    _segmentStack[_segmentIndex].noDrawPath = NO;
    _segmentStack[_segmentIndex].transform = CGAffineTransformScale(_segmentStack[_segmentIndex].transform, 1.0, yOrientation);
    _segmentStack[_segmentIndex].transform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, _translateX, _translateY);
    _segmentStack[_segmentIndex].transform = CGAffineTransformScale(_segmentStack[_segmentIndex].transform, _scale, _scale);
    _segmentStack[_segmentIndex].transform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, _segmentStack[_segmentIndex].baseAngle);
    _segmentStack[_segmentIndex].scale = _scale;
    
    CGAffineTransform fractalOriginTransform = _segmentStack[_segmentIndex].transform;


    [self createFractalInContext: aCGContext];


    if (self.showOrigin) {
        // put origin markers on top of fractal so draw after fractal
        CGContextSaveGState(aCGContext);
        {
            UIColor* shadowColor = [UIColor colorWithWhite: 1.0 alpha: 0.85];
            CGContextSetShadowWithColor(aCGContext, CGSizeMake(1.0, 1.0), 0.0, [shadowColor CGColor]);
            CGContextConcatCTM(aCGContext, fractalOriginTransform);
            UIImage* originDirectionImage = [UIImage imageNamed: @"kBIconRuleDrawLine"]; // kBIconRuleDrawLine  kNorthArrow
            CGRect originDirectionRect = CGRectMake(0.0, -(originDirectionImage.size.height/2.0)/_scale, originDirectionImage.size.width/_scale, originDirectionImage.size.height/_scale);
            CGContextDrawImage(aCGContext, originDirectionRect, [originDirectionImage CGImage]);
            
            UIImage* originCircle = [UIImage imageNamed: @"controlDragCircle16px"];
            CGRect originCircleRect = CGRectMake(-(originCircle.size.width/2.0)/_scale, -(originCircle.size.height/2.0)/_scale, originCircle.size.width/_scale, originCircle.size.height/_scale);
            CGContextDrawImage(aCGContext, originCircleRect, [originCircle CGImage]);
            
        }
        CGContextRestoreGState(aCGContext);
    }

#ifdef LSDEBUGPOSITION
    NSLog(@"Bounds post-autoscale layout: %@", NSStringFromCGRect(self.rawFractalPathBounds));
#endif

    CGContextRestoreGState(aCGContext);
    
#ifdef LSDEBUGPERFORMANCE
        NSDate *methodFinish = [NSDate date];
        executionTime = 1000.0*[methodFinish timeIntervalSinceDate:methodStart];
        NSLog(@"Recursive total execution time: %.2fms", executionTime);
#endif
}
-(void) findFractalUntransformedBoundsForContext: (CGContextRef) aCGContext {
    CGFloat yOrientation = self.flipY ? -1.0 : 1.0;

    [self initialiseSegmentWithContext: aCGContext];
    _segmentStack[_segmentIndex].noDrawPath = YES;
    _segmentStack[_segmentIndex].transform = CGAffineTransformScale(_segmentStack[_segmentIndex].transform, 1.0, yOrientation);
    _segmentStack[_segmentIndex].transform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, _segmentStack[_segmentIndex].baseAngle);
    self.rawFractalPathBounds = CGRectZero;
    
    CGContextSaveGState(aCGContext);
    [self createFractalInContext: aCGContext];
    CGContextRestoreGState(aCGContext);
}
/*
 How to handle scaling?
 ** Two steps
    1. Create at a standard scale.
    2. Redraw at best scale.
    3. Change scale as necessary when changing properties but only draw once and cache scale.
 */
-(void) createFractalInContext: (CGContextRef) aCGContext {

#ifdef LSDEBUGPERFORMANCE
    NSTimeInterval productExecutionTime = 0.0;
    NSDate *productionStart = [NSDate date];
#endif
    
#ifdef LSDEBUGPERFORMANCE
    NSDate *productionFinish = [NSDate date];
    CGFloat productionTime = 1000.0*[productionFinish timeIntervalSinceDate: productionStart];
    NSLog(@"Recursive production time: %.2fms", productionTime);
#endif
    
    CGContextBeginPath(aCGContext);
    CGContextMoveToPoint(aCGContext, 0.0f, 0.0f);
    
    char* bytes = (char*)self.levelData.bytes;
    
    for (long i=0; i < self.levelData.length; i++) {
        [self evaluateRule: bytes[i]];
        if (self.operation.isCancelled) {
            break;
        }
    }
    
    [self drawPath];
    
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

#pragma mark helper methods

-(CGFloat) aspectRatio {
    return self.rawFractalPathBounds.size.height/self.rawFractalPathBounds.size.width;
}

-(CGSize) unitBox {
    CGSize result = {1.0,1.0};
    CGFloat width = self.rawFractalPathBounds.size.width;
    CGFloat height = self.rawFractalPathBounds.size.height;
    
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
    CGRect tempBounds = CGRectUnion(_rawFractalPathBounds, CGRectMake(aPoint.x, aPoint.y, 1.0, 1.0));
    _rawFractalPathBounds = CGRectEqualToRect(tempBounds, CGRectNull) ? CGRectZero : tempBounds;
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
    
    _rawFractalPathBounds = inlineUpdateBounds(_rawFractalPathBounds, transformedPoint);
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
    CGContextSetLineWidth(_segmentStack[_segmentIndex].context, _segmentStack[_segmentIndex].lineWidth * _segmentStack[_segmentIndex].scale);
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


