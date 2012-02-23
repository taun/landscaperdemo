//
//  LSFractalGenerator.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/19/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "LSFractalGenerator.h"
#import "LSFractal+addons.h"
#import "MBColor+addons.h"
#import "MBFractalSegment.h"
#import "LSReplacementRule.h"
#import "LSDrawingRuleType.h"
#import "LSDrawingRule.h"

#import <QuartzCore/QuartzCore.h>

#define MAXPRODUCTLENGTH 2000

@interface LSFractalGenerator () {
    double _maxLineWidth;
}
@property (nonatomic,strong) NSMutableString*       production;
@property (nonatomic,assign) BOOL                   productNeedsGenerating;
@property (nonatomic,assign) BOOL                   pathNeedsGenerating;

@property (nonatomic,strong) NSMutableArray*        finishedSegments;
@property (nonatomic,strong) NSMutableArray*        segmentStack;

@property (nonatomic,assign) CGRect                 bounds;
@property (nonatomic,strong) NSMutableDictionary*  cachedDrawingRules;

@property (nonatomic,strong) MBFractalSegment*      currentSegment;

-(void) addSegment: (MBFractalSegment*) segment;
-(void) pushSegment;
-(void) popSegment;
-(void) finalizeSegments;

-(void) dispatchDrawingSelectorFromString:(NSString*)selector;
-(void) evaluateRule: (NSString*) rule;

-(void) generateProduct;
-(void) generatePaths;

#pragma mark - Default Drawing Rule Methods
-(void) drawLine;
-(void) moveByLine;
-(void) rotateCC;
-(void) rotateC;
-(void) reverseDirection;
-(void) push;
-(void) pop;
-(void) incrementLineWidth;
-(void) decrementLineWidth;
-(void) drawDot;
-(void) openPolygon;
-(void) closePolygon;
-(void) upscaleLineLength;
-(void) downscaleLineLength;
-(void) swapRotation;
-(void) decrementAngle;
-(void) incrementAngle;

@end


@implementation LSFractalGenerator 

@synthesize fractal = _fractal;
@synthesize forceLevel = _forceLevel;
@synthesize production = _production, productNeedsGenerating = _productNeedsGenerating;
@synthesize pathNeedsGenerating = _pathNeedsGenerating;
@synthesize finishedSegments = _segments;
@synthesize segmentStack = _segmentStack, bounds = _bounds;

@synthesize currentSegment = _currentSegment;
@synthesize cachedDrawingRules = _cachedDrawingRules;

- (id)init {
    self = [super init];
    if (self) {
        _productNeedsGenerating = YES;
        _pathNeedsGenerating = YES;
        _forceLevel = -1.0;
    }
    return self;
}

- (void) dealloc {
    self.fractal = nil;
}

#pragma mark - Fractal Property KVO
-(void) setFractal:(LSFractal *)fractal {
    if (_fractal != fractal) {
        
        NSSet* propertiesToObserve = [[LSFractal productionRuleProperties] setByAddingObjectsFromSet:[LSFractal appearanceProperties]];
        
        for (NSString* keyPath in propertiesToObserve) {
            [_fractal removeObserver: self forKeyPath: keyPath];
            [fractal addObserver: self forKeyPath:keyPath options: 0 context: NULL];
        }
        
        _fractal = fractal;
        [self productionRuleChanged];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([[LSFractal productionRuleProperties] containsObject: keyPath]) {
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
    NSString* boundsDescription = [(__bridge NSString*)boundsDict description];
    CFRelease(boundsDict);
    
    return [NSString stringWithFormat: @"<%@: fractal = %@; forceLevel = %g; bounds = %@; production = %@>",
            NSStringFromClass([self class]), 
            self.fractal, 
            self.forceLevel, 
            boundsDescription,
            self.production];
}

-(void) drawInBounds:(CGRect)bounds withContext:(CGContextRef)theContext flipped:(BOOL)isFlipped {
    
    if (self.productNeedsGenerating) {
        [self generateProduct];
    }
    if (self.pathNeedsGenerating) {
        [self generatePaths];
    }
    
    CGContextSaveGState(theContext);
    
    // outline the layer bounding box
    CGContextBeginPath(theContext);
    CGContextAddRect(theContext, bounds);
    CGContextSetLineWidth(theContext, 1.0);
    CGContextSetRGBStrokeColor(theContext, 0.5, 0.0, 0.0, 0.1);
    CGContextStrokePath(theContext);
    
    // move 0,0 down to the bottom left corner
    CGContextTranslateCTM(theContext, bounds.origin.x, bounds.origin.y + bounds.size.height);
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
    
    CGContextSaveGState(theContext);
    
    //    NSDictionary* lboundsDict = (__bridge NSDictionary*) CGRectCreateDictionaryRepresentation(bounds);
    //    NSLog(@"Layer Bounds = %@", lboundsDict);
    
    //    NSDictionary* boundsDict = (__bridge NSDictionary*) CGRectCreateDictionaryRepresentation(self.bounds);
    //    NSLog(@"Fractal Path Bounds = %@", boundsDict);
    
    //    NSLog(@"Layer anchor point: %g@%g", theLayer.anchorPoint.x, theLayer.anchorPoint.y);
    
    // Scaling
    double scaleWidth = bounds.size.width/self.bounds.size.width;
    double scaleHeight = bounds.size.height/self.bounds.size.height;
    double scale = MIN(scaleHeight, scaleWidth);
    
    //    double margin = -0.0/scale;
    
    //    CGContextScaleCTM(theContext, scale, scale);
    //    NSLog(@"Min Layer/Fractal Scale = %g", scale);
    
    
    //    CGRect fBounds = CGRectStandardize(CGRectInset(self.bounds, margin, margin) );
    
    // Translating
    double fCenterX = (self.bounds.origin.x + self.bounds.size.width/2.0);
    double fCenterY = (self.bounds.origin.y + self.bounds.size.height/2.0);
    
    double lCenterX = bounds.origin.x + bounds.size.width/2.0;
    double lCenterY = bounds.origin.y + bounds.size.height/2.0;
    
    double tx = lCenterX - (fCenterX*scale);
    double ty = lCenterY - (fCenterY*scale);
    
    CGContextTranslateCTM(theContext, tx, ty);
    
    CGContextScaleCTM(theContext, scale, scale);
    
    //    NSLog(@"Translation FCenter = %g@%g; LCenter = %g@%g; tx = %g; ty = %g",
    //          fCenterX, fCenterY, lCenterX, lCenterY, tx, ty);
    
    for (MBFractalSegment* segment in self.finishedSegments) {
        // stroke and or fill each segment
        CGContextBeginPath(theContext);
        
        
        //        NSDictionary* aboundsDict = (__bridge NSDictionary*) CGRectCreateDictionaryRepresentation(CGPathGetBoundingBox(segment.path));
        //        NSLog(@"Actual segment bounds = %@", aboundsDict);
        
        // Scale the lineWidth to compensate for the overall scaling
        //        CGContextSetLineWidth(ctx, segment.lineWidth);
        CGContextSetLineWidth(theContext, segment.lineWidth/scale);
        
        CGContextAddPath(theContext, segment.path);
        CGPathDrawingMode strokeOrFill = kCGPathStroke;
        if (segment.fill && segment.stroke) {
            strokeOrFill = kCGPathFillStroke;
            CGContextSetStrokeColorWithColor(theContext, segment.lineColor);
            CGContextSetFillColorWithColor(theContext, segment.fillColor);
        } else if (segment.stroke) {
            strokeOrFill = kCGPathStroke;
            CGContextSetStrokeColorWithColor(theContext, segment.lineColor);
        } else if (segment.fill) {
            strokeOrFill = kCGPathFill;
            CGContextSetFillColorWithColor(theContext, segment.fillColor);
        }
        CGContextDrawPath(theContext, strokeOrFill);
    }
    
    CGContextRestoreGState(theContext);
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
    [self drawInBounds: theLayer.bounds withContext: theContext flipped: [theLayer contentsAreFlipped]];
}

#pragma mark - lazy init getters

-(NSMutableArray*) segmentStack {
    if (_segmentStack == nil) _segmentStack = [[NSMutableArray alloc] initWithCapacity: 1];
    
    return _segmentStack;
}

//TODO: just reference the fractal in the segment?
-(MBFractalSegment*) currentSegment {
    if (_currentSegment == nil) {
        _currentSegment = [[MBFractalSegment alloc] init];
        
        // Copy the fractal core data values to the segment
        _currentSegment.lineColor = [self.fractal lineColorAsUI].CGColor;
        
        _currentSegment.fillColor = [self.fractal fillColorAsUI].CGColor;
        _currentSegment.fill = [self.fractal.fill boolValue];
        
        _currentSegment.lineLength = [self.fractal lineLengthAsDouble];
        _currentSegment.lineLengthScaleFactor = [self.fractal.lineLengthScaleFactor doubleValue];
        _currentSegment.lineWidth = [self.fractal.lineWidth doubleValue];
        _currentSegment.lineWidthIncrement = [self.fractal.lineWidthIncrement doubleValue];
        _currentSegment.stroke = [self.fractal.stroke boolValue];
        
        _currentSegment.turningAngle = [self.fractal turningAngleAsDouble];
        _currentSegment.turningAngleIncrement = [self.fractal.turningAngleIncrement doubleValue];
        
    }
    return _currentSegment;
}

-(NSMutableDictionary*) cachedDrawingRules {
    if (_cachedDrawingRules == nil) {
        NSSet* rules = self.fractal.drawingRulesType.rules;
        NSUInteger ruleCount = [rules count];
        NSMutableDictionary* tempDict = [[NSMutableDictionary alloc] initWithCapacity: ruleCount];
        
        for (LSDrawingRule* rule in rules) {
            [tempDict setObject: rule.drawingMethodString forKey: rule.productionString];
        }
        
        _cachedDrawingRules = tempDict;
    }
    return _cachedDrawingRules;
}

-(void) clearCache {
    self.cachedDrawingRules = nil;
}

-(CGRect) bounds {
    // adjust for the lineWidth
    double margin = _maxLineWidth*2.0+1.0;
    CGRect result = CGRectInset(_bounds, -margin, -margin);
    return result;
//    return _bounds;
}

-(void) setBounds:(CGRect)bounds {
    _bounds = bounds;
}

#pragma mark - segment getter setters

-(double) turningAngle {
    return self.currentSegment.turningAngle;
}

-(void) setTurningAngle:(double)turningAngle {
    self.currentSegment.turningAngle = turningAngle;
}

-(double) turningAngleIncrement {
    return self.currentSegment.turningAngleIncrement;
}

-(void) setTurningAngleIncrement:(double)turningAngleIncrement {
    self.currentSegment.turningAngleIncrement = turningAngleIncrement;
}

-(double) lineLength {
    return self.currentSegment.lineLength;
}

-(void) setLineLength:(double)lineLength {
    self.currentSegment.lineLength = lineLength;
}

-(double) lineLengthScaleFactor {
    return self.currentSegment.lineLength;
}

-(void) setLineLengthScaleFactor:(double)lineLengthScaleFactor {
    self.currentSegment.lineLengthScaleFactor = lineLengthScaleFactor;
}

-(double) lineWidth {
    return self.currentSegment.lineWidth;
}

-(void) setLineWidth:(double)lineWidth {
    self.currentSegment.lineWidth = lineWidth;
}

-(double) lineWidthIncrement {
    return self.currentSegment.lineWidthIncrement;
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

#pragma mark - segment methods

/*
 Should always be an initial current segment.
 Push the currentSegment
 Create a new currentSegment copying the old segments settings
 */
-(void) pushSegment {
    [self.segmentStack addObject: self.currentSegment];
    MBFractalSegment* newCurrentSegment = [self.currentSegment copySettings];
    
    self.currentSegment = newCurrentSegment;
}

/*
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

/*
 Move the currentSegment to the segments array.
 Check to see if there are any segments left on the stack and move them.
 */
-(void) finalizeSegments {
    [self addSegment: self.currentSegment];
    if (_segmentStack != nil) {
        for (MBFractalSegment* segment in self.segmentStack) {
            [self addSegment: segment];
            [self.segmentStack removeObject: segment];
        }
    }
}

-(void) addSegment: (MBFractalSegment*) segment {
    if (_segments == nil) {
        _segments = [[NSMutableArray alloc] initWithCapacity: 2];
        
        // intiallize the bounds to the first segment
        _bounds = CGPathGetBoundingBox(segment.path);
    } else {
        CGRect pathBounds = CGPathGetBoundingBox(segment.path);
        _bounds = CGRectUnion(_bounds, pathBounds);
    }
    _maxLineWidth = MAX(_maxLineWidth, segment.lineWidth);
    [_segments addObject: segment];
}


#pragma mark - Custom Getter Setters

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

-(void) setInitialTransform:(CGAffineTransform)transform {
    self.currentSegment.transform = transform;
}

//-(CGAffineTransform) currentTransform {
//    return _currentTransform;
//}
//
//-(void) setCurrentTransform:(CGAffineTransform)currentTransform {
//    
//}


#pragma mark - Product Generation

-(void) productionRuleChanged {
    self.productNeedsGenerating = YES;
}

//TODO convert this to GCD, one dispatch per axiom character? Then reassemble?
//TODO static var for max product length and way to flag max reached.
-(void) generateProduct {
    //estimate the length
    double localLevel = [self.fractal.level doubleValue];
    if (self.forceLevel >= 0) {
        localLevel = self.forceLevel;
    }
    NSUInteger productionLength = [self.fractal.axiom length] * localLevel;
    
    
    NSMutableString* sourceData = [[NSMutableString alloc] initWithCapacity: productionLength];
    [sourceData appendString: self.fractal.axiom];
    
    NSMutableString* destinationData = [[NSMutableString alloc] initWithCapacity: productionLength];
    NSMutableString* tempData = nil;
    
    // Create a local dictionary version of the replacement rules
    NSMutableDictionary* localReplacementRules = [[NSMutableDictionary alloc] initWithCapacity: [self.fractal.replacementRules count]];
    for (LSReplacementRule* rule in self.fractal.replacementRules) {
        [localReplacementRules setObject: rule.replacementString forKey: rule.contextString];
    }
    
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
            replacement = [localReplacementRules objectForKey: key];
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
    self.production = sourceData;
//    NSLog(@"Production result = %@", sourceData);
    destinationData = nil;
    tempData = nil;
    self.productNeedsGenerating = NO;
    self.pathNeedsGenerating = YES;
}


#pragma mark - path generation

-(void) appearanceChanged {
    self.pathNeedsGenerating = YES;
}

-(void) generatePaths {
    if (self.pathNeedsGenerating) {
        
        CGPathMoveToPoint(self.currentSegment.path, NULL, 0.0f, 0.0f);
        double startingRotation = [self.fractal.baseAngle doubleValue];
        
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
    id selectorId = [self.cachedDrawingRules objectForKey: rule];
    if ([selectorId isKindOfClass: [NSString class]]) {
        NSString* selectorString = (NSString*) selectorId;
        [self dispatchDrawingSelectorFromString: selectorString];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(void) dispatchDrawingSelectorFromString:(NSString*)selector {
    if ([self respondsToSelector:NSSelectorFromString(selector)]) {
        [self performSelector: NSSelectorFromString(selector)];
    }
}

#pragma clang diagnostic pop

-(void) drawCircle: (double) radius {
    CGAffineTransform local = self.currentSegment.transform;
    CGPathAddEllipseInRect(self.currentSegment.path, &local, CGRectMake(-radius, -radius, radius*2.0, radius*2.0));
    CGPathMoveToPoint(self.currentSegment.path, &local, 0, 0);
}

-(void) drawSquare: (double) width {
    CGAffineTransform local = self.currentSegment.transform;
    CGPathAddRect(self.currentSegment.path, &local, CGRectMake(-width/2.0, -width/2.0, width, width));
    CGPathMoveToPoint(self.currentSegment.path, &local, 0, 0);
}

#pragma mark - Public Rule Methods

//TODO remove arg and use segment properties

-(void) drawLine {
    double tx = self.lineLength;
    CGAffineTransform local = self.currentSegment.transform;
    CGPathAddLineToPoint(self.currentSegment.path, &local, tx, 0);
    self.currentSegment.transform = CGAffineTransformTranslate(self.currentSegment.transform, tx, 0.0f);
}

-(void) moveByLine {
    double tx = self.lineLength;
    CGAffineTransform local = self.currentSegment.transform;
    CGPathMoveToPoint(self.currentSegment.path, &local, tx, 0);
    self.currentSegment.transform = CGAffineTransformTranslate(self.currentSegment.transform, tx, 0.0f);
}

-(void) rotateCC {
    double theta = self.turningAngle;
    self.currentSegment.transform = CGAffineTransformRotate(self.currentSegment.transform, theta);
}

-(void) rotateC {
    double theta = self.turningAngle;
    self.currentSegment.transform = CGAffineTransformRotate(self.currentSegment.transform, -theta);
}

-(void) reverseDirection {
    self.currentSegment.transform = CGAffineTransformRotate(self.currentSegment.transform, M_PI);
}

-(void) push {
    [self pushSegment];
}

-(void) pop {
    [self popSegment];
}

-(void) incrementLineWidth {
    self.currentSegment.lineWidth += self.currentSegment.lineWidthIncrement;
}

-(void) decrementLineWidth {
    self.currentSegment.lineWidth -= self.currentSegment.lineWidthIncrement;
}

-(void) drawDot {
    [self drawCircle: self.currentSegment.lineWidth];
}

-(void) openPolygon {
    
}

-(void) closePolygon {
    
}

-(void) upscaleLineLength {
    self.currentSegment.lineLength *= self.currentSegment.lineLengthScaleFactor;
}

-(void) downscaleLineLength {
    self.currentSegment.lineLength /= self.currentSegment.lineLengthScaleFactor;
}

-(void) swapRotation {
    id tempMinusRule = [self.cachedDrawingRules objectForKey: @"-"];
    [self.cachedDrawingRules setObject: [self.cachedDrawingRules objectForKey: @"+"] forKey: @"-"];
    [self.cachedDrawingRules setObject: tempMinusRule forKey: @"+"];
}

-(void) decrementAngle {
    self.currentSegment.turningAngle -= self.currentSegment.turningAngleIncrement;
}

-(void) incrementAngle {
    self.currentSegment.turningAngle += self.currentSegment.turningAngleIncrement;
}

#pragma mark - helper methods

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
