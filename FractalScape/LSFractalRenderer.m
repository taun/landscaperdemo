//
//  LSFractalRenderer.m
//  FractalScape
//
//  Created by Taun Chapman on 01/05/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;
@import QuartzCore;
@import CoreGraphics;

#import "LSFractalRenderer.h"
#import "MDBFractalDocument.h"
#import "LSFractal.h"
#import "MBColor.h"
#import "LSReplacementRule.h"
#import "LSDrawingRuleType.h"
#import "LSDrawingRule.h"
#import "MDBFractalObjectList.h"

//#define LSDEBUGPERFORMANCE
//#define LSDEBUGPOSITION

ColorHSLA   ColorConvertRGBAToHSLA(ColorRGBA);
ColorRGBA   ColorConvertHSLAToRGBA(ColorHSLA);


struct MBCommandsStruct {
    char        command[kLSMaxRules][kLSMaxCommandLength];
};
typedef struct MBCommandsStruct MBCommandsStruct;

struct MBCommandSelectorsStruct {
    SEL        selector[kLSMaxRules];
};
typedef struct MBCommandSelectorsStruct MBCommandSelectorsStruct;


@interface LSFractalRenderer () {
    CGFloat                 _maxLineWidth;
    MBSegmentStruct         _segmentStack[kLSMaxSegmentStackSize];
    NSInteger               _segmentIndex;
    MBSegmentRef            _currentSegment;
    MBCommandsStruct        _commandsStruct;
    MBCommandSelectorsStruct _selectorsStruct;
}

@property (nonatomic,strong) NSArray                *lineColors;
@property (nonatomic,strong) NSArray                *fillColors;
@property (nonatomic,assign) MBSegmentStruct        baseSegment;
@property (nonatomic,assign,readwrite) CGRect       rawFractalPathBounds;
@property (nonatomic,assign) BOOL                   controlPointOn;
@property (nonatomic,assign) CGPoint                controlPointNode;
@property (nonatomic,assign) CGPoint                previousNode;
/*!
 Use to know how many level have been plumbed.
 */
@property (nonatomic,assign) NSInteger              peakRecursion;
/*!
 Use to normalize hue rotation setting to hue rotation on the screen. Allows the user to say 
 "regardless of rules and iterations, they want one full hue rotation. Otherwise the hue shift changes
 for every level and rule change and has massive hue rotation at high levels but no rotation at low levels.
 */
@property (nonatomic,assign) NSInteger              peakHueRotations;

@end

#pragma mark - Implementation

@implementation LSFractalRenderer

@synthesize pixelScale = _pixelScale;

+(instancetype) newRendererForFractal:(LSFractal *)aFractal withSourceRules: (LSDrawingRuleType*)sourceRules
{
    LSFractalRenderer* newGenerator = [[LSFractalRenderer alloc] initWithFractal: aFractal withSourceRules: sourceRules];
    return newGenerator;
}

-(instancetype) initWithFractal: (LSFractal*) aFractal withSourceRules: (LSDrawingRuleType*)sourceRules
{
    self = [super init];
    if (self) {
        _scale = 1.0;
        _autoscale = YES;
        _showOrigin = YES;
        _translateX = 0.0;
        _translateY = 0.0;
        _rawFractalPathBounds =  CGRectZero;
        _defaultLineColor = [MBColor newMBColorWithUIColor: [UIColor blueColor]];
        _defaultFillColor = [MBColor newMBColorWithUIColor: [UIColor whiteColor]];
        _controlPointOn = NO;
        _segmentIndex = 0;
        _margin = 0;
        _backgroundColor = [UIColor clearColor];
        
        [self nullOutBaseSegment];
        [self setValuesForFractal: aFractal];
        [self cacheDrawingRules: sourceRules];
    }
    return self;
}

- (instancetype)init {
    self = [self initWithFractal: nil withSourceRules: nil];
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
    [self setBaseSegmentForFractal: aFractal];
}

-(void) cacheDrawingRules: (LSDrawingRuleType*)sourceDrawingRules
{
    NSArray* rules = sourceDrawingRules.rulesAsSortedArray;
    
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
}
-(void) setBaseSegmentForFractal: (LSFractal*)aFractal
{
    [self releaseSegmentCGReferences];
    
    self.lineColors = [aFractal.lineColors allObjectsDeepCopy];
    self.fillColors = [aFractal.fillColors allObjectsDeepCopy];
    
    if (self.lineColors.count == 0)
    {
        _baseSegment.currentLineColor = [self.defaultLineColor asColorRgbaOrColorRefStruct];
    }
    else
    {
        _baseSegment.currentLineColor = [self.lineColors[0] asColorRgbaOrColorRefStruct];
    }
    if (self.fillColors.count == 0)
    {
        _baseSegment.currentFillColor = [self.defaultFillColor asColorRgbaOrColorRefStruct];
    }
    else
    {
        _baseSegment.currentFillColor = [self.fillColors[0] asColorRgbaOrColorRefStruct];
    }
        

    _baseSegment.lineColorIndex = 0;
    _baseSegment.fillColorIndex = 0;

    _baseSegment.advancedMode = aFractal.advancedMode;
    
    _baseSegment.lineLength = aFractal.lineLength;
    _baseSegment.lineLengthScaleFactor = aFractal.lineLengthScaleFactor;
    
    _baseSegment.lineWidth = aFractal.lineWidth;
    _baseSegment.lineWidthIncrement = aFractal.lineWidthIncrement;
    
    _baseSegment.turningAngle = aFractal.turningAngle;
    _baseSegment.turningAngleIncrement = aFractal.turningAngleIncrement;
    
    _baseSegment.randomness = aFractal.randomness;
    _baseSegment.lineChangeFactor = aFractal.lineChangeFactor;
    _baseSegment.lineHueRotationPercent = aFractal.lineHueRotationPercent;
    _baseSegment.fillHueRotationPercent = aFractal.fillHueRotationPercent;
    
    _baseSegment.lineCap = kCGLineCapRound;
    _baseSegment.lineJoin = kCGLineJoinRound;
    
    _baseSegment.stroke = YES;
    _baseSegment.fill = NO;
    _baseSegment.EOFill = aFractal.eoFill ? aFractal.eoFill : NO;
    
    _baseSegment.drawingModeUnchanged = NO;
    
    _baseSegment.transform = CGAffineTransformRotate(CGAffineTransformIdentity, 0.0);//-[aFractal.baseAngle floatValue]);
    _baseSegment.scale = 1.0;
    
    _baseSegment.points[0] = CGPointMake(0.0, 0.0);
    _baseSegment.pointIndex = -1;
    
    _baseSegment.baseAngle = aFractal.baseAngle;
}
-(void) releaseSegmentCGReferences {
    // all other segments are just copied references with no retains.
    CGPathRef pathRef = _baseSegment.path;
    if (pathRef != NULL) CGPathRelease(pathRef);
    _baseSegment.path = NULL;
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
    UIImageView* strongImageView = self.imageView;
    NSBlockOperation* strongOperation = self.operation;
    
    if (!strongImageView || (strongOperation && strongOperation.isCancelled) || percent <= 0.0)
    {
        return;
    }
    
    CGSize size = strongImageView.bounds.size;
    
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
        UIColor* thumbNailBackground = self.backgroundColor.UIColor;
        [thumbNailBackground setFill]; // needed rather than an if then for CGColor vs CGPattern
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
    
    self.peakHueRotations = 0;
    self.peakRecursion = 0;
    
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
        CGFloat scaleWidth = 1.0;
        CGFloat scaleHeight = 1.0;
        
        if (self.rawFractalPathBounds.size.width > 0.0 && self.rawFractalPathBounds.size.height > 0.0)
        {
            scaleWidth = (size.width-2.0*self.margin)/self.rawFractalPathBounds.size.width;
            scaleHeight = (size.height-2.0*self.margin)/self.rawFractalPathBounds.size.height;
        }
        
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
    /*
     If the scale is less then 1.0, then the screen lineWidth = scale * lineWidth.
     For scale < 1.0 and lineWidth = 1.0, this result in a lineWidth less than 1.
     We want a minimum lineWidth which would result in 1.0 on screen.
     For scale = 0.25, lineWidth = 1.0, screenLine = 0.25*1.0 = 0.25
     need initial lineWidth to be lineWidth/scale for scale < 1.0
     */
//    CGFloat minWidth = 0.25;
//    if (_scale > 0.0 && _scale*_baseSegment.lineWidth < minWidth) {
//        _segmentStack[_segmentIndex].lineWidth = minWidth*_baseSegment.lineWidth/_scale;
//    }
//    else{
//       _segmentStack[_segmentIndex].lineWidth =  _baseSegment.lineWidth;
//    }
//    CGFloat actualWidth = _scale * _segmentStack[_segmentIndex].lineWidth;
    _segmentStack[_segmentIndex].noDrawPath = NO;
    _segmentStack[_segmentIndex].transform = CGAffineTransformScale(_segmentStack[_segmentIndex].transform, 1.0, yOrientation);
    _segmentStack[_segmentIndex].transform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, _translateX, _translateY);
    _segmentStack[_segmentIndex].transform = CGAffineTransformScale(_segmentStack[_segmentIndex].transform, _scale, _scale);
    _segmentStack[_segmentIndex].transform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, _segmentStack[_segmentIndex].baseAngle);
    _segmentStack[_segmentIndex].scale = _scale;
    
    CGAffineTransform fractalOriginTransform = _segmentStack[_segmentIndex].transform;


    [self createFractalInContext: aCGContext percent: percent];

    if (self.showOrigin)
    {
        // put origin markers on top of fractal so draw after fractal
        CGContextSaveGState(aCGContext);
        {
//            UIColor* shadowColor = [UIColor colorWithWhite: 1.0 alpha: 0.85];
//            CGContextSetShadowWithColor(aCGContext, CGSizeMake(1.0, 1.0), 0.0, [shadowColor CGColor]);
            CGContextSetAlpha(aCGContext, 0.6);
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
    
    if (percent < 100.0) {
        _baseSegment.randomize = NO;
        _baseSegment.randomness = 0.0;
    }

    for (long i=0; i < dataLength; i++)
    {
        [self evaluateRule: bytes[i]];
        if (self.operation.isCancelled)
        {
            break;
        }
    }
    
    if (percent < 100.0 || !_baseSegment.advancedMode) {
        [self drawPathClosed: NO];
    }
    
    // release paths leftover from an operation cancel
    for (int i = 0; i< kLSMaxSegmentStackSize; i++) {
        CGPathRef oldPath = _segmentStack[i].path;
        if (oldPath != NULL) {
            CGPathRelease(oldPath);
            _segmentStack[i].path = NULL;
        }
    }
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

/*!
 Randomize a scalar value to it's value plus or minus a randomness percent of its value.
 If randomness = 20%, the return value would be plus or minus 20%
 
 @param apply      whether to randomize
 @param scalar     the scalar to be randomized
 @param randomness the degree of randomness
 
 @return a potentially randomized scalar.
 */
static inline  CGFloat randomScalar(bool apply, CGFloat scalar, CGFloat randomness)
{
    CGFloat rscalar;
    if (apply) {
        /*!
         drand48() returns value from 0.0 to 1.0
         want 0.5 to leave scalar unchanged and 1.0 to be scalar*(1+randomness)
         scalar*(1+(drand48()-0.5)*randomness)
         scalar+scalar*randomness*(drand48()-0.5)
        */
        rscalar = scalar+scalar*randomness*(drand48()-0.5);
    } else {
        rscalar =  scalar;
    }
    return rscalar;
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

#pragma message "TODO fill out below and use with hue rotation routines to change correct color."

-(void) setCGGraphicsStateFromCurrentSegment {
    CGContextSetLineJoin(_segmentStack[_segmentIndex].context, _segmentStack[_segmentIndex].lineJoin);
    CGContextSetLineCap(_segmentStack[_segmentIndex].context, _segmentStack[_segmentIndex].lineCap);
    CGContextSetLineWidth(_segmentStack[_segmentIndex].context, _segmentStack[_segmentIndex].lineWidth * _segmentStack[_segmentIndex].scale);

    ColorRgbaOrColorRef colorRGBorRef = _segmentStack[_segmentIndex].currentFillColor;
    if (colorRGBorRef.isColorRef)
    {
        CGContextSetFillColorWithColor(_segmentStack[_segmentIndex].context, colorRGBorRef.colorRef);
    }
    else
    {
        ColorRGBA rgba = colorRGBorRef.rgba;
        CGContextSetRGBFillColor(_segmentStack[_segmentIndex].context, rgba.r, rgba.g, rgba.b, rgba.a);
    }
    
    colorRGBorRef = _segmentStack[_segmentIndex].currentLineColor;
    if (colorRGBorRef.isColorRef) {
        CGContextSetStrokeColorWithColor(_segmentStack[_segmentIndex].context, colorRGBorRef.colorRef);
    }
    else
    {
        ColorRGBA rgba = colorRGBorRef.rgba;
        CGContextSetRGBStrokeColor(_segmentStack[_segmentIndex].context, rgba.r, rgba.g, rgba.b, rgba.a);
    }
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
        
        if (emptyPath)
        {
            CGPoint transformedSPoint = CGPointApplyAffineTransform(CGPointMake(0.0, 0.0), _segmentStack[_segmentIndex].transform);
            CGPathMoveToPoint(_segmentStack[_segmentIndex].path, NULL, transformedSPoint.x, transformedSPoint.y);
        }
        
        if (!_segmentStack[_segmentIndex].inCurve)
        {
            CGPathAddLineToPoint(_segmentStack[_segmentIndex].path, NULL, transformedPoint.x, transformedPoint.y);
        }
        else
        {
            // handle adding points for the curve
            [self addCurvePoint: aUserPoint];
        }
    }
    
    _rawFractalPathBounds = inlineUpdateBounds(_rawFractalPathBounds, transformedPoint);
}
-(void) addCurvePoint: (CGPoint)aUserPoint
{
    if (_segmentStack[_segmentIndex].pointIndex+1 >= kLSMaxSegmentPointsSize) {
        // save last two endpoints
        CGPoint p0 = _segmentStack[_segmentIndex].points[_segmentStack[_segmentIndex].pointIndex-1];
        CGPoint p1 = _segmentStack[_segmentIndex].points[_segmentStack[_segmentIndex].pointIndex];
        [self drawFinishedCurve: NO];
        // put last two endpoints back. p1 will be the new control point
        _segmentStack[_segmentIndex].points[0] = p0;
        _segmentStack[_segmentIndex].points[1] = p1;
        _segmentStack[_segmentIndex].pointIndex = 1;
    }
    else if (_segmentStack[_segmentIndex].pointIndex < 0)
    {
        // no start point so add default (0,0)
        CGPoint transformedSPoint = CGPointApplyAffineTransform(CGPointMake(0.0, 0.0), _segmentStack[_segmentIndex].transform);
        _segmentStack[_segmentIndex].pointIndex += 1;
        _segmentStack[_segmentIndex].points[_segmentStack[_segmentIndex].pointIndex] = transformedSPoint;
    }
    
    CGPoint transformedPoint = CGPointApplyAffineTransform(aUserPoint, _segmentStack[_segmentIndex].transform);
    if (_segmentStack[_segmentIndex].pointIndex+1 < kLSMaxSegmentPointsSize)
    {
        _segmentStack[_segmentIndex].pointIndex += 1;
    }
    else{
        NSLog(@"FractalScape:Warning reached end of segment point buffer %ld",(long)kLSMaxSegmentPointsSize);
    }
    _segmentStack[_segmentIndex].points[_segmentStack[_segmentIndex].pointIndex] = transformedPoint;
}
/*!
 Called at the end of the commandStartCurve, commandEndCurve sequence.
 Rotates and moves within the sequence are treating as per normal.
 commandDrawLine adds the line point to the points array which has a klsMaxSegmentPoints limit.
 At the end of the sequence, the curve is drawn where each point is considered an arc control point.
 
 Current implementation would be messed up by circles, move, and other non-line commands.
 */
-(void) drawFinishedCurve: (BOOL)finish
{
    if (!_segmentStack[_segmentIndex].noDrawPath && _segmentStack[_segmentIndex].pointIndex > 1)
    {
        NSInteger count = _segmentStack[_segmentIndex].pointIndex + 1;
        
        MBCGQuadCurvedPathWithPoints(_segmentStack[_segmentIndex].path,_segmentStack[_segmentIndex].points, count, finish);
        // reset points array
        _segmentStack[_segmentIndex].pointIndex = -1;
    }
}
void MBCGQuadCurvedPathWithPoints(CGMutablePathRef path, CGPoint* points, NSInteger count, bool finish);
/*!
 Code from
 
 http://stackoverflow.com/questions/8702696/drawing-smooth-curves-methods-needed user1244109 :
 
     UIBezierPath *path = [UIBezierPath bezierPath];
     
     NSValue *value = points[0];
     CGPoint p1 = [value CGPointValue];
     [path moveToPoint:p1];
     
     if (points.count == 2) {
     value = points[1];
     CGPoint p2 = [value CGPointValue];
     [path addLineToPoint:p2];
     return path;
     }
     
     for (NSUInteger i = 1; i < points.count; i++) {
     value = points[i];
     CGPoint p2 = [value CGPointValue];
     
     CGPoint midPoint = midPointForPoints(p1, p2);
     [path addQuadCurveToPoint:midPoint controlPoint:controlPointForPoints(midPoint, p1)];
     [path addQuadCurveToPoint:p2 controlPoint:controlPointForPoints(midPoint, p2)];
     
     p1 = p2;
     }
     return path;

 
 @param path   path to modify
 @param points array of points
 @param count  count of points
 */
void MBCGQuadCurvedPathWithPoints(CGMutablePathRef path, CGPoint* points, NSInteger count, bool finish)
{
    if (CGPathIsEmpty(path)) {
        CGPoint p0 = midPointForPoints(points[0], points[1]);
        CGPathMoveToPoint(path, NULL, p0.x, p0.y);
    }
    CGPoint p1 = points[1]; // p0 should be same as current path point
    
    if (count == 2)
    {
        CGPathAddLineToPoint(path, NULL, p1.x, p1.y);
        return;
    }
    
    //
    CGPoint midPointP12 = CGPointZero;
    CGPoint p2 = CGPointZero;
    
    for (NSUInteger i = 2; i < count; i++)
    {
        p2 = points[i];
        
        midPointP12 = midPointForPoints(p1, p2);
        if (finish && i+1==count)
        {
            // take the last curve to the end.
            CGPathAddQuadCurveToPoint(path, NULL, p1.x, p1.y, p2.x, p2.y);
        }
        else
        {
            CGPathAddQuadCurveToPoint(path, NULL, p1.x, p1.y, midPointP12.x, midPointP12.y);
        }
        
        p1 = p2;
    }
    
    return;
}

static inline CGPoint midPointForPoints(CGPoint p1, CGPoint p2)
{
    return CGPointMake((p1.x + p2.x) / 2.0, (p1.y + p2.y) / 2.0);
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
        
        if (_segmentStack[_segmentIndex].inCurve) {
            [self drawFinishedCurve: YES];
        }
        
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
-(void) drawCircleRadius: (CGFloat) radius
{
//    CGPoint lowerCorner = CGPointApplyAffineTransform(CGPointMake(-radius, -radius), _segmentStack[_segmentIndex].transform);
//    CGPoint upperCorner = CGPointApplyAffineTransform(CGPointMake(2.0*radius, 2.0*radius), _segmentStack[_segmentIndex].transform);
//    
//    CGRect transformedRect = CGRectApplyAffineTransform(CGRectMake(-radius, -radius, radius*2.0, radius*2.0), _segmentStack[_segmentIndex].transform);
    
    if (!_segmentStack[_segmentIndex].noDrawPath)
    {
        
        BOOL emptyPath = CGPathIsEmpty(_segmentStack[_segmentIndex].path);
        
        if (emptyPath)
        {
            CGPoint transformedSPoint = CGPointApplyAffineTransform(CGPointMake(0.0, 0.0), _segmentStack[_segmentIndex].transform);
            CGPathMoveToPoint(_segmentStack[_segmentIndex].path, NULL, transformedSPoint.x, transformedSPoint.y);
        }
        
        CGRect circleRect = CGRectMake(-radius, -radius, radius*2.0, radius*2.0);
        CGPathAddEllipseInRect(_segmentStack[_segmentIndex].path, &_segmentStack[_segmentIndex].transform, circleRect);
        CGAffineTransform newTransform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, 0.0, 0.0); // not used for circle
        _segmentStack[_segmentIndex].transform = newTransform;
    }
    CGPoint transformedPoint0 = CGPointApplyAffineTransform(CGPointMake(-radius, -radius), _segmentStack[_segmentIndex].transform);
    CGPoint transformedPoint1 = CGPointApplyAffineTransform(CGPointMake(radius, radius), _segmentStack[_segmentIndex].transform);
    
    _rawFractalPathBounds = inlineUpdateBounds(_rawFractalPathBounds, transformedPoint0);
    _rawFractalPathBounds = inlineUpdateBounds(_rawFractalPathBounds, transformedPoint1);
}
// unused - if used, needs noDrawPath code
-(void) drawSquareWidth: (CGFloat) width {
    CGRect transformedRect = CGRectApplyAffineTransform(CGRectMake(0.0, -width/2.0, width, width), _segmentStack[_segmentIndex].transform);
    CGPathAddRect(_segmentStack[_segmentIndex].path, NULL, transformedRect);
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
    _segmentStack[_segmentIndex].inCurve = NO; // reset to no curve. can always re-add curve rule but can't remove curve rule.
}
-(void) popCurrentPath
{
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
    CGFloat tx = randomScalar(_segmentStack[_segmentIndex].randomize, _segmentStack[_segmentIndex].lineLength, _segmentStack[_segmentIndex].randomness);

    [self segmentAddLineToPoint: CGPointMake(tx, 0.0)];
    
    CGAffineTransform newTransform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, tx, 0.0);
    _segmentStack[_segmentIndex].transform = newTransform;
}
#pragma message "TODO: how to implement variable line length? or just a second line command? Already have line increment/decrement."
-(void) commandDrawLineVarLength
{
    CGFloat tx = randomScalar(_segmentStack[_segmentIndex].randomize, _segmentStack[_segmentIndex].lineLength, _segmentStack[_segmentIndex].randomness);
    
    [self segmentAddLineToPoint: CGPointMake(tx, 0.0)];
    
    CGAffineTransform newTransform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, tx, 0.0);
    _segmentStack[_segmentIndex].transform = newTransform;
}

-(void) commandMoveByLine
{
    CGFloat tx = randomScalar(_segmentStack[_segmentIndex].randomize, _segmentStack[_segmentIndex].lineLength, _segmentStack[_segmentIndex].randomness);

    CGPoint transformedPoint = CGPointApplyAffineTransform(CGPointMake(tx, 0.0), _segmentStack[_segmentIndex].transform);
#pragma message "TODO: not sure this move is necessary."
    CGPathMoveToPoint(_segmentStack[_segmentIndex].path, NULL, transformedPoint.x, transformedPoint.y);

    CGAffineTransform newTransform = CGAffineTransformTranslate(_segmentStack[_segmentIndex].transform, tx, 0.0);
    _segmentStack[_segmentIndex].transform = newTransform;
}

-(void) commandRotateCC
{
    CGFloat theta = randomScalar(_segmentStack[_segmentIndex].randomize, _segmentStack[_segmentIndex].turningAngle, _segmentStack[_segmentIndex].randomness);

    CGAffineTransform newTransform = CGAffineTransformRotate(_segmentStack[_segmentIndex].transform, theta);
    _segmentStack[_segmentIndex].transform = newTransform;
}

-(void) commandRotateC
{
    CGFloat theta = randomScalar(_segmentStack[_segmentIndex].randomize, _segmentStack[_segmentIndex].turningAngle, _segmentStack[_segmentIndex].randomness);
    
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
    if (!_segmentStack[_segmentIndex].advancedMode) [self pushCurrentPath];
    [self drawCircleRadius: randomScalar(_segmentStack[_segmentIndex].randomize, _segmentStack[_segmentIndex].lineWidth*2, _segmentStack[_segmentIndex].randomness)];
    _segmentStack[_segmentIndex].stroke = YES; // ignore advancedMode
    _segmentStack[_segmentIndex].fill = NO; // ignore advancedMode
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    if (!_segmentStack[_segmentIndex].advancedMode) [self popCurrentPath];
}
-(void) commandDrawDotFilledNoStroke
{
    if (!_segmentStack[_segmentIndex].advancedMode) [self pushCurrentPath];
    [self drawCircleRadius: randomScalar(_segmentStack[_segmentIndex].randomize, _segmentStack[_segmentIndex].lineWidth*2, _segmentStack[_segmentIndex].randomness)];
    _segmentStack[_segmentIndex].stroke = NO; // ignore advancedMode
    _segmentStack[_segmentIndex].fill = YES; // ignore advancedMode
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    if (!_segmentStack[_segmentIndex].advancedMode) [self popCurrentPath];
}

-(void) commandOpenPolygon
{
    [self commandStartCurve];
}

-(void) commandClosePolygon
{
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
/*!
 We want commandLineWidthIncrement and commandLineWidthDecrement to be symmetric.
 Meaning we want an decrement to cancel in increment leaving the lineWidth as it was. 
 This allows an increment before a rule to be followed by a decrement after a rule leaving the lineWidth untouched.
 
 Assume lineWidthIncrement is a percentage like 10% means add 10% or subtract 10%
 lw = lw + lw * i% = lw * (1 * i%)
 
 lw = 10
 i% = 0.5
 
 lw+ = 10.0 * 1.5 = 15.0
 
 lw1 = (lw0 * (1 + %))
 lw0 = (lw1 * x) = (lw0 * (1 + %)) * x
 
 x = 1/(1 + %)
 
 lw- = lw/(1 + %)
 
 */
-(void) commandIncrementLineWidth
{
    if (_segmentStack[_segmentIndex].lineChangeFactor > 0) {
        if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
       _segmentStack[_segmentIndex].lineWidth = _segmentStack[_segmentIndex].lineWidth * (1.0 + _segmentStack[_segmentIndex].lineChangeFactor);
    }
}

/*!
 Assume lineWidthIncrement is a percentage like 10% means add 10% or subtract 10%
 lw- = lw - lw * i% = lw * (1 - i%)
 */
-(void) commandDecrementLineWidth
{
    if (_segmentStack[_segmentIndex].lineChangeFactor > 0)
    {
        if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath]; // line widths only take effect when drawing the path.
        _segmentStack[_segmentIndex].lineWidth = _segmentStack[_segmentIndex].lineWidth / (1.0 + _segmentStack[_segmentIndex].lineChangeFactor);
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
/*!
 Use same reversible logic as commandLineWidthIncrement
 */
-(void) commandIncrementAngle
{
    if (_segmentStack[_segmentIndex].turningAngleIncrement > 0) {
        _segmentStack[_segmentIndex].turningAngle = _segmentStack[_segmentIndex].turningAngle * (1.0 + _segmentStack[_segmentIndex].turningAngleIncrement);
    }
}

-(void) commandDecrementAngle
{
    if (_segmentStack[_segmentIndex].turningAngleIncrement > 0) {
        _segmentStack[_segmentIndex].turningAngle = _segmentStack[_segmentIndex].turningAngle / (1.0 + _segmentStack[_segmentIndex].turningAngleIncrement);
    }
}

-(void) commandRandomizeOff
{
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    
    _segmentStack[_segmentIndex].randomize = NO;
}
-(void) commandRandomizeOn
{
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    
    _segmentStack[_segmentIndex].randomize = YES;
}
-(void) commandStartCurve
{
    _segmentStack[_segmentIndex].inCurve = YES;
}
-(void) commandEndCurve
{
    [self drawFinishedCurve: YES];
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
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    
    [self popCurrentPath];
}

-(void) commandStrokeOff
{
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    _segmentStack[_segmentIndex].stroke = NO;
}

-(void) commandStrokeOn
{
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    _segmentStack[_segmentIndex].stroke = YES;
}
-(void) commandFillOff
{
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    _segmentStack[_segmentIndex].fill = NO;
}
-(void) commandFillOn
{
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    _segmentStack[_segmentIndex].fill = YES;
}
-(void) commandNextColor
{
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    
    NSInteger count = self.lineColors.count;
    
    if (count > 1)
    {
        NSInteger currentIndex = _segmentStack[_segmentIndex].lineColorIndex + 1;
        
        _segmentStack[_segmentIndex].lineColorIndex = currentIndex >= count ? 0 : currentIndex;
        
        _segmentStack[_segmentIndex].currentLineColor = [self.lineColors[_segmentStack[_segmentIndex].lineColorIndex] asColorRgbaOrColorRefStruct];
    }
}
-(void) commandPreviousColor
{
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    
    NSInteger count = self.lineColors.count;
    
    if (count > 1)
    {
        NSInteger currentIndex = _segmentStack[_segmentIndex].lineColorIndex - 1;
        
        _segmentStack[_segmentIndex].lineColorIndex = currentIndex < 0 ? count : currentIndex;
        
        _segmentStack[_segmentIndex].currentLineColor = [self.lineColors[_segmentStack[_segmentIndex].lineColorIndex] asColorRgbaOrColorRefStruct];
    }
}
-(void) commandNextFillColor
{
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    
    NSInteger count = self.fillColors.count;
    
    if (count > 1)
    {
        NSInteger currentIndex = _segmentStack[_segmentIndex].fillColorIndex + 1;
        
        _segmentStack[_segmentIndex].fillColorIndex = currentIndex >= count ? 0 : currentIndex;
        
        _segmentStack[_segmentIndex].currentFillColor = [self.fillColors[_segmentStack[_segmentIndex].fillColorIndex] asColorRgbaOrColorRefStruct];
    }
}
-(void) commandPreviousFillColor
{
    if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];
    
    NSInteger count = self.fillColors.count;
    
    if (count > 1)
    {
        NSInteger currentIndex = _segmentStack[_segmentIndex].fillColorIndex - 1;
        
        _segmentStack[_segmentIndex].fillColorIndex = currentIndex < 0 ? count : currentIndex;
        
        _segmentStack[_segmentIndex].currentFillColor = [self.fillColors[_segmentStack[_segmentIndex].fillColorIndex] asColorRgbaOrColorRefStruct];
    }
}
-(void)commandRotateLineHue
{
    if (_segmentStack[_segmentIndex].lineHueRotationPercent != 0)
    {
        ColorRgbaOrColorRef currentColor = _segmentStack[_segmentIndex].currentLineColor;
        
        if (!currentColor.isColorRef)
        {
            if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];

            ColorRGBA rgba = currentColor.rgba;
            
            ColorHSLA hlsa = ColorConvertRGBAToHSLA(rgba);
            CGFloat randomizedDelta = randomScalar(_segmentStack[_segmentIndex].randomize, _segmentStack[_segmentIndex].lineHueRotationPercent, _segmentStack[_segmentIndex].randomness);
            CGFloat rotationDelta = 0.36 * randomizedDelta;
            hlsa.h = hlsa.h + rotationDelta; // in degrees
            
            ColorRGBA newRgba = ColorConvertHSLAToRGBA(hlsa);
            currentColor.rgba = newRgba;
            _segmentStack[_segmentIndex].currentLineColor = currentColor;
        }
    }
}
-(void) commandRotateLineBrightness
{
    
}
-(void) commandRotateLineSaturation
{
    
}
-(void) commandRotateFillHue
{
    if (_segmentStack[_segmentIndex].fillHueRotationPercent != 0)
    {
        ColorRgbaOrColorRef currentColor = _segmentStack[_segmentIndex].currentFillColor;
        
        if (!currentColor.isColorRef)
        {
            if (!_segmentStack[_segmentIndex].advancedMode) [self drawPath];

            ColorRGBA rgba = currentColor.rgba;
            
            ColorHSLA hlsa = ColorConvertRGBAToHSLA(rgba);
            CGFloat rotationDelta = 3.6 * _segmentStack[_segmentIndex].fillHueRotationPercent;
            hlsa.h = hlsa.h + rotationDelta; // in degrees
            
            ColorRGBA newRgba = ColorConvertHSLAToRGBA(hlsa);
            currentColor.rgba = newRgba;
            _segmentStack[_segmentIndex].currentFillColor = currentColor;
        }
    }
}
-(void) commandRotateFillBrightness
{
    
}
-(void) commandRotateFillSaturation
{
    
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
@end


