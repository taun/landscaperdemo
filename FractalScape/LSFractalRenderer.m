//
//  LSFractalRenderer.m
//  FractalScape
//
//  Created by Taun Chapman on 01/05/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "LSFractalRenderer.h"

#import "LSFractal+addons.h"
#import "MBColor+addons.h"
#import "LSReplacementRule+addons.h"
#import "LSDrawingRuleType+addons.h"
#import "LSDrawingRule+addons.h"

#import <QuartzCore/QuartzCore.h>

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


@interface LSFractalRenderer () {
    CGFloat             _maxLineWidth;
    MBSegmentStruct     _segmentStack[kLSMaxSegmentStackSize];
    NSInteger           _segmentIndex;
    MBSegmentRef        _currentSegment;
    MBCommandsStruct    _commandsStruct;
    MBCommandSelectorsStruct _selectorsStruct;
}

@property (nonatomic,assign) MBSegmentStruct        baseSegment;
@property (nonatomic,assign,readwrite) CGRect       rawFractalPathBounds;
@property (nonatomic,assign) BOOL                   controlPointOn;
@property (nonatomic,assign) CGPoint                controlPointNode;
@property (nonatomic,assign) CGPoint                previousNode;

@end

#pragma mark - Implementation

@implementation LSFractalRenderer

@synthesize pixelScale = _pixelScale;

+(instancetype) newRendererForFractal:(LSFractal *)aFractal {
    LSFractalRenderer* newGenerator = [[LSFractalRenderer alloc] initWithFractal: aFractal];
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
        _defaultLineColor = [UIColor blueColor];
        _defaultFillColor = [UIColor whiteColor];
        _controlPointOn = NO;
        _segmentIndex = 0;
        _margin = 0;
        _backgroundColor = [UIColor clearColor];
        
        [self nullOutBaseSegment];
        [self setValuesForFractal: aFractal];
    }
    return self;
}

- (instancetype)init {
    self = [self initWithFractal: nil];
    return self;
}
-(void) dealloc
{
    [self releaseSegmentCGReferences];
}

#pragma mark - getters setters
-(void) setPixelScale:(CGFloat)pixelScale
{
    NSAssert(pixelScale < 8.0, @"FractalScape:Error out of range pixelScale. Should be < 8, is: %f",pixelScale);
    _pixelScale = pixelScale;
}
-(CGFloat) pixelScale
{
    NSAssert(_pixelScale < 8.0, @"FractalScape:Error out of range pixelScale. Should be < 8, is: %f",_pixelScale);
    return _pixelScale;
}
/* If fractal is not save, below will return nil for privateFractal. What to do? */
-(void) setValuesForFractal:(LSFractal *)aFractal
{
    [self cacheDrawingRules: aFractal];
    [self setBaseSegmentForFractal: aFractal];
}

-(void) cacheDrawingRules: (LSFractal*)aFractal
{
    NSOrderedSet* rules = aFractal.drawingRulesType.rules;
    
    // setup internal noop rule placeholder "Z"
    unsigned char zIndex = [@"Z" UTF8String][0];
    strcpy(_commandsStruct.command[zIndex], [@"commandDoNothing" UTF8String]);
    
    for (LSDrawingRule* rule in rules)
    {
        unsigned char ruleIndex = rule.productionString.UTF8String[0];
        
        NSInteger commandLength = rule.drawingMethodString.length;
        if (commandLength < kLSMaxCommandLength)
        {
            strcpy(_commandsStruct.command[ruleIndex], rule.drawingMethodString.UTF8String);
            
        }
        else
        {
            NSAssert(YES, @"FractalScapeError: Rule CommandString '%@' is too long. Max length: %d, actual length: %lu",
                     rule.drawingMethodString,
                     kLSMaxCommandLength,
                     (unsigned long)commandLength);
        }
    }
    
    int i = 0;
    for (i=0; i < kLSMaxRules; i++)
    {
        // initialize all selector slots to NULL. They will be filled lazily.
        _selectorsStruct.selector[i] = NULL;
    }
}

-(NSString*) debugDescription
{
    CFDictionaryRef boundsDict = CGRectCreateDictionaryRepresentation(_rawFractalPathBounds);
    NSString* boundsDescription = [(__bridge NSDictionary*)boundsDict description];
    CFRelease(boundsDict);
    
    return [NSString stringWithFormat: @"<%@: bounds = %@>",
            NSStringFromClass([self class]),
            boundsDescription];
}

#pragma mark - lazy init getters
-(void) nullOutBaseSegment
{
    _baseSegment.path = NULL;
    _baseSegment.context = NULL;
    
    _baseSegment.defaultLineColor = NULL;
    _baseSegment.defaultFillColor = NULL;
    
    for (NSInteger colorIndex = 0; colorIndex < kLSMaxColors; colorIndex++)
    {
        _baseSegment.lineColors[colorIndex] = NULL;
        _baseSegment.fillColors[colorIndex] = NULL;
    }

}
-(void) setBaseSegmentForFractal: (LSFractal*)aFractal
{
    [self releaseSegmentCGReferences];
    
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
    
    _baseSegment.defaultLineColor = [self.defaultLineColor CGColor];
    _baseSegment.defaultFillColor = [self.defaultFillColor CGColor];
    
    NSInteger colorIndex;
    
    for (colorIndex = 0; colorIndex+1 < kLSMaxColors; colorIndex++)
    {
        _baseSegment.lineColors[colorIndex] = NULL;
        _baseSegment.fillColors[colorIndex] = NULL;
    }
    
    colorIndex = 0;
    for (MBColor* mbColor in aFractal.lineColors)
    {
        _baseSegment.lineColors[colorIndex] = CGColorCreateCopy([[mbColor asUIColor] CGColor]);
        colorIndex++;
        if(colorIndex >= kLSMaxColors)
        {
            NSLog(@"FractalScape:Warning fillColors exceeded max render array size of %ld",kLSMaxColors);
            break;
        }
    }
    _baseSegment.lineColorsCount = MIN(aFractal.lineColors.count,kLSMaxColors);
    _baseSegment.lineColorIndex = 0;
    
    
    colorIndex = 0;
    for (MBColor* mbColor in aFractal.fillColors)
    {
        _baseSegment.fillColors[colorIndex] = CGColorCreateCopy([[mbColor asUIColor] CGColor]);
        colorIndex++;
        if(colorIndex >= kLSMaxColors)
        {
            NSLog(@"FractalScape:Warning fillColors exceeded max render array size of %ld",kLSMaxColors);
            break;
        }
    }
    _baseSegment.fillColorsCount = MIN(aFractal.fillColors.count, kLSMaxColors);
    _baseSegment.fillColorIndex = 0;
    
}
-(void) releaseSegmentCGReferences {
    // all other segments are just copied references with no retains.
    CGPathRef pathRef = _baseSegment.path;
    if (pathRef != NULL) CGPathRelease(pathRef);
    _baseSegment.path = NULL;
    
    CGColorRef color;
    // default line and fill color are local properties and released using ARC.
    
    for (NSInteger colorIndex = 0; colorIndex < kLSMaxColors; colorIndex++)
    {
        color = _baseSegment.lineColors[colorIndex];
        if (color != NULL) CGColorRelease(color);
        _baseSegment.lineColors[colorIndex] = NULL;
        
        color = _baseSegment.fillColors[colorIndex];
        if (color != NULL) CGColorRelease(color);
        _baseSegment.fillColors[colorIndex] = NULL;
    }
}
-(void) initialiseSegmentWithContext: (CGContextRef)aCGContext
{
    
    MBSegmentStruct newSegment = _baseSegment;
    newSegment.context = aCGContext;
    
    _segmentIndex = 0;
    _segmentStack[_segmentIndex] = newSegment;
}
-(void) generateImage
{
    [self generateImagePercent: 100.0];
}
-(void) generateImagePercent:(CGFloat)percent
{
    if (!self.imageView || (self.operation && self.operation.isCancelled) || percent <= 0.0)
    {
        return;
    }
    
    CGSize size = self.imageView.bounds.size;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, self.pixelScale);
    {
        CGContextRef aCGontext = UIGraphicsGetCurrentContext();
        [self drawInContext: aCGontext size: size percent: percent];
        self.image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
}
-(void) fillBackgroundInContext: (CGContextRef)aCGContext size: (CGSize)size
{
    
    CGContextSaveGState(aCGContext);
    {
        UIColor* thumbNailBackground = self.backgroundColor;
        [thumbNailBackground setFill];
        CGContextFillRect(aCGContext, CGRectMake(0.0, 0.0, size.width, size.height));
    }
    CGContextRestoreGState(aCGContext);
}
-(void) drawInContext:(CGContextRef)aCGContext size:(CGSize)size
{
    [self drawInContext: aCGContext size: size percent: 100.0];
}
-(void) drawInContext:(CGContextRef)aCGContext size: (CGSize)size percent:(CGFloat)percent
{

    NSAssert(aCGContext, @"NULL Context being used. Context must be non-null.");
    
    [self fillBackgroundInContext: aCGContext size: size];

    NSDate *methodStart;
    
    NSTimeInterval executionTime = 0.0;
    NSTimeInterval pathExecutionTime = 0.0;
    methodStart = [NSDate date];

    CGContextSaveGState(aCGContext);
    
    CGFloat yOrientation = self.flipY ? -1.0 : 1.0;
    
    if (self.autoscale)
    {
        
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
        CGFloat scaleWidth = (size.width-2.0*self.margin)/self.rawFractalPathBounds.size.width;
        CGFloat scaleHeight = (size.height-2.0*self.margin)/self.rawFractalPathBounds.size.height;
        
        // scale > 1 means grow, < 1 means shrink,
        // only scale if we need to shrink to fit
        if (self.autoExpand)
        {
            _scale = MIN(scaleHeight, scaleWidth);
        }
        else
        {
            _scale = MIN(1.0,MIN(scaleHeight, scaleWidth));
        }
        
        // Translating
        CGFloat fractalCenterX = _scale * CGRectGetMidX(self.rawFractalPathBounds);
        CGFloat fractalCenterY = _scale * CGRectGetMidY(self.rawFractalPathBounds)*yOrientation; //130
        
        CGFloat viewCenterX = (size.width/2.0);
        CGFloat viewCenterY = (size.height/2.0)*yOrientation; // -434
        
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


    [self createFractalInContext: aCGContext percent: percent];
    if (_segmentStack[_segmentIndex].path != NULL)
    {
        CGPathRelease(_segmentStack[_segmentIndex].path);
        _segmentStack[_segmentIndex].path = NULL;
    }

    if (self.showOrigin)
    {
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
    
    NSDate *methodFinish = [NSDate date];
    _renderTime = 1000.0*[methodFinish timeIntervalSinceDate:methodStart];
#ifdef LSDEBUGPERFORMANCE
        NSLog(@"Recursive total execution time: %.2fms", _renderTime);
#endif
}
-(void) findFractalUntransformedBoundsForContext: (CGContextRef) aCGContext
{
    CGFloat yOrientation = self.flipY ? -1.0 : 1.0;

    [self initialiseSegmentWithContext: aCGContext];
    _segmentStack[_segmentIndex].noDrawPath = YES;
    _segmentStack[_segmentIndex].transform = CGAffineTransformScale(_segmentStack[_segmentIndex].transform, 1.0, yOrientation);
    _segmentStack[_segmentIndex].transform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, _segmentStack[_segmentIndex].baseAngle);
    self.rawFractalPathBounds = CGRectZero;
    
    CGContextSaveGState(aCGContext);
    [self createFractalInContext: aCGContext percent: 100.0];
    CGContextRestoreGState(aCGContext);
}
/*
 How to handle scaling?
 ** Two steps
    1. Create at a standard scale.
    2. Redraw at best scale.
    3. Change scale as necessary when changing properties but only draw once and cache scale.
 */
-(void) createFractalInContext: (CGContextRef) aCGContext percent: (CGFloat)percent
{

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
    
    CGFloat maxPercent = MIN(100.0, percent);
    CGFloat minPercent = (MAX(1.0, maxPercent))/100.0;
    long dataLength = minPercent >= 0.99 ? self.levelData.length : minPercent*self.levelData.length;
    
    dataLength = dataLength > self.levelData.length ? self.levelData.length : dataLength;
    
    for (long i=0; i < dataLength; i++)
    {
        [self evaluateRule: bytes[i]];
        if (self.operation.isCancelled)
        {
            break;
        }
    }
    
//    [self drawPath];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(void) evaluateRule:(char)rule
{
    //
    SEL cachedSelector = _selectorsStruct.selector[rule];
    if (!cachedSelector)
    {
        NSString* selectorString = [NSString stringWithUTF8String: _commandsStruct.command[rule]];
        SEL uncachedSelector = NSSelectorFromString(selectorString);
        
        if ([self respondsToSelector: uncachedSelector])
        {
            cachedSelector = uncachedSelector;
            _selectorsStruct.selector[rule] = cachedSelector;
        } else
        {
            NSLog(@"FractalScape error: missing command for key '%c'",rule);
            return;
        }
    }
    [self performSelector: cachedSelector];
}

#pragma mark helper methods

-(CGFloat) aspectRatio {
    return self.rawFractalPathBounds.size.height/self.rawFractalPathBounds.size.width;
}

-(CGSize) unitBox
{
    CGSize result = {1.0,1.0};
    CGFloat width = self.rawFractalPathBounds.size.width;
    CGFloat height = self.rawFractalPathBounds.size.height;
    
    if (width >= height)
    {
        // wider than tall width is 1.0
        result.height = height/width;
    } else
    {
        // taller than wide height is 1.0
        result.width = width/height;
    }
    return result;
}

-(void) updateBoundsWithPoint: (CGPoint) aPoint
{
    CGRect tempBounds = CGRectUnion(_rawFractalPathBounds, CGRectMake(aPoint.x, aPoint.y, 1.0, 1.0));
    _rawFractalPathBounds = CGRectEqualToRect(tempBounds, CGRectNull) ? CGRectZero : tempBounds;
}
/*!
 static inline without method dispatch saves 50ms out of 850ms.
 
 @param bounds old bounds
 @param aPoint point to add to bounds
 
 @return new potentially larger bounds
 */
static inline CGRect inlineUpdateBounds(CGRect bounds, CGPoint aPoint)
{
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
-(CGPathDrawingMode) getSegmentDrawingMode
{
    
    if (!_segmentStack[_segmentIndex].drawingModeUnchanged) {
        BOOL stroke = _segmentStack[_segmentIndex].stroke;
        BOOL fill = _segmentStack[_segmentIndex].fill;
        BOOL eoFill = _segmentStack[_segmentIndex].EOFill;
        
        CGPathDrawingMode strokeOrFill = kCGPathStroke;
        
        if (fill && stroke)
        {
            strokeOrFill = eoFill ? kCGPathEOFillStroke : kCGPathFillStroke;
        } else if (stroke && !fill)
        {
            strokeOrFill = kCGPathStroke;
        } else if (fill && !stroke)
        {
            strokeOrFill = eoFill ? kCGPathEOFill : kCGPathFill;
        }
        
        _segmentStack[_segmentIndex].mode = strokeOrFill;
    }
    return _segmentStack[_segmentIndex].mode;
}

-(CGColorRef) currentLineColor
{
    NSInteger count = _segmentStack[_segmentIndex].lineColorsCount;
    if (count == 0) {
        return _segmentStack[_segmentIndex].defaultLineColor;
    }
    
    NSInteger moddedIndex =  _segmentStack[_segmentIndex].lineColorIndex % count; //(NSUInteger)fabs(fmod((CGFloat)index, count));
    
    CGColorRef newColor = _segmentStack[_segmentIndex].lineColors[moddedIndex];
    
    if (newColor == NULL) {
        newColor = _segmentStack[_segmentIndex].defaultLineColor;
    }
    
    return newColor;
}
-(CGColorRef) currentFillColor
{
    NSInteger count = _segmentStack[_segmentIndex].fillColorsCount;
    if (count == 0) {
        return _segmentStack[_segmentIndex].defaultFillColor;
    }
    
    NSInteger moddedIndex =  _segmentStack[_segmentIndex].fillColorIndex % count; //(NSUInteger)fabs(fmod((CGFloat)index, count));
    
    CGColorRef newColor = _segmentStack[_segmentIndex].fillColors[moddedIndex];
    
    if (newColor == NULL) {
        newColor = _segmentStack[_segmentIndex].defaultFillColor;
    }
    
    return newColor;
}

-(void) setCGGraphicsStateFromCurrentSegment {
    CGContextSetLineJoin(_segmentStack[_segmentIndex].context, _segmentStack[_segmentIndex].lineJoin);
    CGContextSetLineCap(_segmentStack[_segmentIndex].context, _segmentStack[_segmentIndex].lineCap);
    CGContextSetLineWidth(_segmentStack[_segmentIndex].context, _segmentStack[_segmentIndex].lineWidth * _segmentStack[_segmentIndex].scale);
    CGContextSetFillColorWithColor(_segmentStack[_segmentIndex].context, [self currentFillColor]);
    CGContextSetStrokeColorWithColor(_segmentStack[_segmentIndex].context, [self currentLineColor]);
}

-(NSInteger) segmentPointCount
{
    return _segmentStack[_segmentIndex].pointIndex + 1;
}

-(void) segmentAddLineToPoint: (CGPoint) aUserPoint
{
    CGPoint transformedPoint = CGPointApplyAffineTransform(aUserPoint, _segmentStack[_segmentIndex].transform);
    
    if (!_segmentStack[_segmentIndex].noDrawPath)
    {
        if (_segmentStack[_segmentIndex].path == NULL)
        {
            // the first point in a continuous path
            _segmentStack[_segmentIndex].path = CGPathCreateMutable();
        }
        
        BOOL emptyPath = CGPathIsEmpty(_segmentStack[_segmentIndex].path);
        
        if (emptyPath || CGPointEqualToPoint(CGPathGetCurrentPoint(_segmentStack[_segmentIndex].path), CGPointZero))
        {
            CGPoint transformedSPoint = CGPointApplyAffineTransform(CGPointMake(0.0, 0.0), _segmentStack[_segmentIndex].transform);
            CGPathMoveToPoint(_segmentStack[_segmentIndex].path, NULL, transformedSPoint.x, transformedSPoint.y);
        }
        
        CGPathAddLineToPoint(_segmentStack[_segmentIndex].path, NULL, transformedPoint.x, transformedPoint.y);
    }
    
    
    _rawFractalPathBounds = inlineUpdateBounds(_rawFractalPathBounds, transformedPoint);
}

#pragma mark - Private Draw Methods
-(void) drawPath {
    [self drawPathClosed: NO];
}

-(void) drawPathClosed: (BOOL)closed
{
    
        if (!_segmentStack[_segmentIndex].noDrawPath)
        {
            [self setCGGraphicsStateFromCurrentSegment];
            
            if (closed || _segmentStack[_segmentIndex].fill)
            {
                [self closePath];
            }
            
            CGContextAddPath(_segmentStack[_segmentIndex].context, _segmentStack[_segmentIndex].path);
            CGPathRelease(_segmentStack[_segmentIndex].path);
            _segmentStack[_segmentIndex].path = NULL;
            
            CGContextDrawPath(_segmentStack[_segmentIndex].context, [self getSegmentDrawingMode]);
        }
}
-(void) closePath
{
    BOOL emptyPath = CGPathIsEmpty(_segmentStack[_segmentIndex].path);
    if (!emptyPath) CGPathCloseSubpath(_segmentStack[_segmentIndex].path);
}
-(void) drawCurve
{
    
}
-(void) drawCircleRadius: (CGFloat) radius {
//    [self setCGGraphicsStateFromCurrentSegment];
    CGRect transformedRect = CGRectApplyAffineTransform(CGRectMake(0.0, -radius, radius*2.0, radius*2.0), _segmentStack[_segmentIndex].transform);
    CGPathAddEllipseInRect(_segmentStack[_segmentIndex].path, NULL, transformedRect);
//    CGContextAddEllipseInRect(_segmentStack[_segmentIndex].context, transformedRect);
//    CGContextDrawPath(_segmentStack[_segmentIndex].context, [self getSegmentDrawingMode]);
//    [self segmentAddPoint: CGPointMake(radius*2.0, 0.0)];
    CGAffineTransform newTransform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, radius*2, 0.0);
    _segmentStack[_segmentIndex].transform = newTransform;
}
// unused
-(void) drawSquareWidth: (CGFloat) width {
//    [self setCGGraphicsStateFromCurrentSegment];
    CGRect transformedRect = CGRectApplyAffineTransform(CGRectMake(0.0, -width/2.0, width, width), _segmentStack[_segmentIndex].transform);
    CGPathAddRect(_segmentStack[_segmentIndex].path, NULL, transformedRect);
//    CGContextAddRect(_segmentStack[_segmentIndex].context, transformedRect);
    CGAffineTransform newTransform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, width, 0.0);
    _segmentStack[_segmentIndex].transform = newTransform;
}

-(void) pushCurrentPath {
    if (_segmentIndex+1 == kLSMaxSegmentStackSize) {
        NSLog(@"FractalScape:Warning push limit of %ld reached", (long)kLSMaxSegmentStackSize);
    }
    _segmentIndex = _segmentIndex+1 < kLSMaxSegmentStackSize ? ++_segmentIndex : _segmentIndex;
    NSAssert(_segmentIndex >= 0 && _segmentIndex < kLSMaxSegmentStackSize, @"_segmentIndex out of range!");
    _segmentStack[_segmentIndex] = _segmentStack[_segmentIndex-1];
    _segmentStack[_segmentIndex].path = CGPathCreateMutable();
}
-(void) popCurrentPath {
    if (_segmentStack[_segmentIndex].path != NULL) {
        CGPathRelease(_segmentStack[_segmentIndex].path);
        _segmentStack[_segmentIndex].path = NULL;
    }
    _segmentIndex = _segmentIndex > 0 ? --_segmentIndex : _segmentIndex;
    NSAssert(_segmentIndex >= 0 && _segmentIndex < kLSMaxSegmentStackSize, @"_segmentIndex out of range!");
}

#pragma mark - Public Rule Draw Methods

-(void) commandDoNothing
{
}
-(void) commandDrawLine
{
    CGFloat tx = _segmentStack[_segmentIndex].lineLength;
    [self segmentAddLineToPoint: CGPointMake(tx, 0.0)];
    
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
#pragma message "TODO: how to implement variable line length? or just a second line command? Already have line increment/decrement."
-(void) commandDrawLineVarLength
{
    
    CGFloat tx = _segmentStack[_segmentIndex].lineLength;
    [self segmentAddLineToPoint: CGPointMake(tx, 0.0)];
    
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

-(void) commandMoveByLine
{
    CGFloat tx = _segmentStack[_segmentIndex].lineLength;
    CGPoint transformedPoint = CGPointApplyAffineTransform(CGPointMake(tx, 0.0), _segmentStack[_segmentIndex].transform);
#pragma message "TODO: not sure this move is necessary."
    CGPathMoveToPoint(_segmentStack[_segmentIndex].path, NULL, transformedPoint.x, transformedPoint.y);

    CGAffineTransform newTransform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, tx, 0.0);
    _segmentStack[_segmentIndex].transform = newTransform;

////   CGContextRef aCGContext = _segmentStack[_segmentIndex].context;
//    CGFloat tx = _segmentStack[_segmentIndex].lineLength;
//    CGContextMoveToPoint(aCGContext, tx, 0.0);
//    CGContextTranslateCTM(aCGContext, tx, 0.0);
}

-(void) commandRotateCC
{
    CGFloat theta = _segmentStack[_segmentIndex].turningAngle;
    CGAffineTransform newTransform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, theta);
    _segmentStack[_segmentIndex].transform = newTransform;

    //    CGContextRotateCTM(aCGContext, theta);
}

-(void) commandRotateC
{
    CGFloat theta = _segmentStack[_segmentIndex].turningAngle;
    CGAffineTransform newTransform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, -theta);
    _segmentStack[_segmentIndex].transform = newTransform;
}

-(void) commandReverseDirection
{
    CGAffineTransform newTransform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, M_PI);
    _segmentStack[_segmentIndex].transform = newTransform;
}

-(void) commandDrawDot
{
    [self drawCircleRadius: _segmentStack[_segmentIndex].lineWidth];
}
-(void) commandDrawDotFilledNoStroke
{
    [self commandStrokeOff];
    [self commandFillOn];
    [self commandDrawDot];
}

-(void) commandOpenPolygon
{
//    [self drawPath]; // draw before saving state
//    [self pushCurrentPath];
//    [self commandStrokeOff];
//    [self commandFillOn];
    [self commandStartCurve];
}

-(void) commandClosePolygon
{
//    [self drawPathClosed: YES];
//    [self popCurrentPath];
    [self commandEndCurve];
}

#pragma message "TODO: remove length scaling in favor of just manipulating the aspect ration with width"
-(void) commandUpscaleLineLength
{
    if (_segmentStack[_segmentIndex].lineChangeFactor > 0) {
        _segmentStack[_segmentIndex].lineLength += _segmentStack[_segmentIndex].lineLength * _segmentStack[_segmentIndex].lineChangeFactor;
    }
}

-(void) commandDownscaleLineLength
{
    if (_segmentStack[_segmentIndex].lineChangeFactor > 0) {
        _segmentStack[_segmentIndex].lineLength -= _segmentStack[_segmentIndex].lineLength * _segmentStack[_segmentIndex].lineChangeFactor;
    }
}

-(void) commandSwapRotation
{
    char turnLeft = '+'; // need to not hard code this.
    char turnRight = '-'; // same as above
    
    char* currentLeftCommand = _commandsStruct.command[turnLeft];
    char* currentRightCommand = _commandsStruct.command[turnRight];
    SEL currentLeftSelector = _selectorsStruct.selector[turnLeft];
    SEL currentRightSelector = _selectorsStruct.selector[turnRight];
    
    strcpy(_commandsStruct.command[turnLeft], currentRightCommand);
    strcpy(_commandsStruct.command[turnRight], currentLeftCommand);
    
    _selectorsStruct.selector[turnLeft] = currentRightSelector;
    _selectorsStruct.selector[turnRight] = currentLeftSelector;
}

-(void) commandDecrementAngle
{
    if (_segmentStack[_segmentIndex].turningAngleIncrement > 0) {
        _segmentStack[_segmentIndex].turningAngle -= _segmentStack[_segmentIndex].turningAngle * _segmentStack[_segmentIndex].turningAngleIncrement;
    }
}

-(void) commandIncrementAngle
{
    if (_segmentStack[_segmentIndex].turningAngleIncrement > 0) {
        _segmentStack[_segmentIndex].turningAngle += _segmentStack[_segmentIndex].turningAngle * _segmentStack[_segmentIndex].turningAngleIncrement;
    }
}
-(void) commandRandomizeOff
{
    _segmentStack[_segmentIndex].randomize = NO;
}
-(void) commandRandomizeOn
{
    _segmentStack[_segmentIndex].randomize = YES;
}
-(void) commandStartCurve
{
    _segmentStack[_segmentIndex].inCurve = YES;
}
-(void) commandEndCurve
{
    [self drawCurve];
    _segmentStack[_segmentIndex].inCurve = NO;
}
-(void) commandDrawPath
{
    [self drawPath];
}
-(void) commandClosePath
{
    [self closePath];
}
-(void) commandPush
{
    //    [self drawPath];
    [self pushCurrentPath];
}

#pragma mark - block [] level drawing commands. IE. they do not force a draw
#pragma mark Path Properties
/*!
 Forcing the following draw commands to drawPath after setting would mess with fills.
 If the user wants a filled rectangle but they are dragging the fill or stroke or any of the following
 through the block, it would split the drawing operation into two separate draws eliminating the desired fill.
 */

-(void) commandPop
{
    [self popCurrentPath];
}

-(void) commandStrokeOff
{
    _segmentStack[_segmentIndex].stroke = NO;
}

-(void) commandStrokeOn
{
    _segmentStack[_segmentIndex].stroke = YES;
}
-(void) commandFillOff
{
//    [self drawPath];
    _segmentStack[_segmentIndex].fill = NO;
}
-(void) commandFillOn
{
//    [self drawPath];
    _segmentStack[_segmentIndex].fill = YES;
}
-(void) commandNextColor
{
    //    [self startNewSegment];
    _segmentStack[_segmentIndex].lineColorIndex = ++_segmentStack[_segmentIndex].lineColorIndex;
}
-(void) commandPreviousColor
{
    //    [self startNewSegment];
    _segmentStack[_segmentIndex].lineColorIndex = --_segmentStack[_segmentIndex].lineColorIndex;
}
-(void) commandNextFillColor
{
    //    [self startNewSegment];
    _segmentStack[_segmentIndex].fillColorIndex = ++_segmentStack[_segmentIndex].fillColorIndex;
}
-(void) commandPreviousFillColor
{
    //    [self startNewSegment];
    _segmentStack[_segmentIndex].fillColorIndex = --_segmentStack[_segmentIndex].fillColorIndex;
}
-(void) commandLineCapButt
{
    _segmentStack[_segmentIndex].lineCap = kCGLineCapButt;
}
-(void) commandLineCapRound
{
    _segmentStack[_segmentIndex].lineCap = kCGLineCapRound;
}
-(void) commandLineCapSquare
{
    _segmentStack[_segmentIndex].lineCap = kCGLineCapSquare;
}
-(void) commandLineJoinMiter
{
    _segmentStack[_segmentIndex].lineJoin = kCGLineJoinMiter;
}
-(void) commandLineJoinRound
{
    _segmentStack[_segmentIndex].lineJoin = kCGLineJoinRound;
}
-(void) commandLineJoinBevel
{
    _segmentStack[_segmentIndex].lineJoin = kCGLineJoinBevel;
}
/*!
 Assume lineWidthIncrement is a percentage like 10% means add 10% or subtract 10%
 */
-(void) commandIncrementLineWidth
{
    if (_segmentStack[_segmentIndex].lineChangeFactor > 0) {
        _segmentStack[_segmentIndex].lineWidth += _segmentStack[_segmentIndex].lineWidth * _segmentStack[_segmentIndex].lineChangeFactor;
    }
}

-(void) commandDecrementLineWidth
{
    if (_segmentStack[_segmentIndex].lineChangeFactor > 0) {
        _segmentStack[_segmentIndex].lineWidth -= _segmentStack[_segmentIndex].lineWidth * _segmentStack[_segmentIndex].lineChangeFactor;
    }
}
@end


