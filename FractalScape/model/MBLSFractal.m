//
//  MBLSFractal.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBLSFractal.h"
#import "MBFractalSegment.h"
#include <math.h>

#define MAXDATA int 1000000

@interface MBLSFractal () {
    double _maxLineWidth;
}

#pragma mark - Model
@property (nonatomic,strong,readwrite) NSMutableString*           production;
@property (nonatomic,strong,readwrite) NSMutableDictionary*       replacementRules;
@property (nonatomic,strong,readwrite) NSMutableDictionary*       drawingRules;
@property (nonatomic,assign,readwrite) CGRect                     bounds;

@property (nonatomic,readwrite,atomic,strong) MBFractalSegment*   currentSegment;

-(void) addSegment: (MBFractalSegment*) segment;
-(void) dispatchDrawingSelectorFromString:(NSString*)selector;
-(void) evaluateRule: (NSString*) rule;

@end



@implementation MBLSFractal

@synthesize levels = _levels, axiom = _axiom, productNeedsGenerating = _productNeedsGenerating, pathNeedsGenerating = _pathNeedsGenerating;

@synthesize replacementRules = _replacementRules;
@synthesize production = _production;
@synthesize drawingRules = _drawingRules;
@synthesize finishedSegments = _segments;
@synthesize segmentStack = _segmentStack;
@synthesize bounds = _bounds;

@synthesize currentSegment = _currentSegment;

+(NSMutableDictionary*) defaultDrawingRules {
    NSMutableDictionary* defaultRules = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         @"drawLine", @"F",
                                         @"moveByLine", @"f",
                                         @"rotateCC", @"+",
                                         @"rotateC", @"-",
                                         @"reverseDirection", @"|",
                                         @"push", @"[",
                                         @"pop", @"]",
                                         @"incrementLineWidth", @"#",
                                         @"decrementLineWidth", @"!",
                                         @"drawDot", @"@",
                                         @"openPolygon", @"{",
                                         @"closePolygon", @"}",
                                         @"upscaleLineLength", @">",
                                         @"downscaleLineLength", @"<",
                                         @"swapRotation", @"&",
                                         @"decrementAngle", @"(",
                                         @"incrementAngle", @")",
                                         nil];

    return defaultRules;
}


-(NSString*) debugDescription {
    NSString* generatePath = self.pathNeedsGenerating ? @"YES" : @"NO";
    NSString* generateProduct = self.productNeedsGenerating ? @"YES" : @"NO";
    
    return [NSString stringWithFormat: @"Axiom: \"%@\", Levels: %u, Generate Product?: %@, Generate Path?: %@ ",
            self.axiom, self.levels, generateProduct, generatePath];
}

#pragma mark - lazy init getters

-(NSMutableArray*) segmentStack {
    if (_segmentStack == nil) _segmentStack = [[NSMutableArray alloc] initWithCapacity: 1];

    return _segmentStack;
}

-(MBFractalSegment*) currentSegment {
    if (_currentSegment == nil) {
        _currentSegment = [[MBFractalSegment alloc] init];
    }
    return _currentSegment;
}

-(NSMutableDictionary*) replacementRules {
    if (_replacementRules == nil) {
        _replacementRules = [[NSMutableDictionary alloc] initWithCapacity: 20];
    }
    return _replacementRules;
}

-(NSMutableDictionary*) drawingRules {
    if (_drawingRules == nil) {
        _drawingRules = [[NSMutableDictionary alloc] initWithCapacity: 20];
    }
    return _drawingRules;
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
    
    for (MBFractalSegment* segment in self.segmentStack) {
        [self addSegment: segment];
        [self.segmentStack removeObject: segment];
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

-(NSUInteger) levels {
    return _levels;
}

-(void) setLevels:(NSUInteger)levels {
    _levels = levels;
    self.productNeedsGenerating = YES;
}

-(NSString*) axiom {
    return _axiom;
}

-(void) setAxiom:(NSString *)axiom {
    _axiom = [axiom copy];
    self.productNeedsGenerating = YES;
}

-(BOOL) productNeedsGenerating {
    return _productNeedsGenerating;
}

-(void) setProductNeedsGenerating:(BOOL)productNeedsGenerating {
    _productNeedsGenerating = productNeedsGenerating;
    if (productNeedsGenerating) {
        // path needs to be regenerated whenever the product changes
        self.pathNeedsGenerating = YES;
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


-(CGRect) bounds {
    // adjust for the lineWidth
    double margin = _maxLineWidth*2.0+1.0;
    CGRect result = CGRectInset(_bounds, -margin, -margin);
    return result;
}

-(void) setBounds:(CGRect)bounds {
    _bounds = bounds;
}


#pragma mark - definition setup 

-(void) addProductionRuleReplaceString: (NSString*) original withString: (NSString*) replacement {    
    [self.replacementRules setObject: replacement forKey: original];
    self.productNeedsGenerating = YES;
}

-(void) resetRules {
    self.replacementRules = nil;
    self.productNeedsGenerating = YES;
}


-(void) addDrawingRuleString:(NSString*)character executesSelector:(NSString*)selector {
    [self.drawingRules setObject: selector forKey: character];
    self.productNeedsGenerating = YES;
}


#pragma mark - Product Generation

//TODO convert this to GCD, one dispatch per axiom character? Then reassemble?
-(void) generateProduct {
    //estimate the length
    NSUInteger productionLength = [self.axiom length] * self.levels;

    
    NSMutableString* sourceData = [[NSMutableString alloc] initWithCapacity: productionLength];
    [sourceData appendString: self.axiom];
    
    NSMutableString* destinationData = [[NSMutableString alloc] initWithCapacity: productionLength];
    NSMutableString* tempData = nil;
        
    for (int i = 0; i < self.levels ; i++) {
        NSUInteger sourceLength = sourceData.length;
        
        NSString* key;
        NSString* replacement;
        
        for (int y=0; y < sourceLength; y++) {
            //
            key = [sourceData substringWithRange: NSMakeRange(y, 1)];
            replacement = [self.replacementRules objectForKey: key];
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
    destinationData = nil;
    tempData = nil;
    self.productNeedsGenerating = NO;
    self.pathNeedsGenerating = YES;
}


#pragma mark - path generation

-(void) generatePaths {
    if (self.pathNeedsGenerating) {
        
        CGPathMoveToPoint(self.currentSegment.path, NULL, 0.0f, 0.0f);
        
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
    if ([self.drawingRules count]==0) {
        // use the default rules
        [self.drawingRules addEntriesFromDictionary: [[self class] defaultDrawingRules]];
    }
    
    id selectorId = [self.drawingRules objectForKey: rule];
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
    id tempMinusRule = [self.drawingRules objectForKey: @"-"];
    [self.drawingRules setObject: [self.drawingRules objectForKey: @"+"] forKey: @"-"];
    [self.drawingRules setObject: tempMinusRule forKey: @"+"];
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

@end
