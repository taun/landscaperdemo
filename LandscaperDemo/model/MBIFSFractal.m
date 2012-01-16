//
//  MBIFSFractal.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBIFSFractal.h"
#import "MBFractalSegment.h"
#include <math.h>

#define MAXDATA int 1000000

//TODO: Make CGContext and Path properties
//TODO: Try drawing circle on stored path then check bounds and change CTM Scale before stroke

/*!
 At some point want to separate this into two separate classes.
 1. Fractal model which generates the string and has the rules for 
 turtle drawing. Maps a rule to a method of the view.
 Example: rule: F -> selector: "drawLineLength: x"
                + -> "rotateAngle: theta"
 
 Model properties includes a stack of:
  Segment - struct or object?
    CGMutablePath
    Color for path 
    Linewidth for path
    ?
 Model will update boundingBox property while creating paths for max box.
 Delete production when path is complete (saves memory and only needs to be
 regenerated if the axiom or rules change).
 
 2. The view takes the model and generates a view based on the 
 production string and the drawing map. Basically iterates through
 the production calling the mapped selector on the view.
 
 View will set transfomation matrix to best fit fractal then iterate through segments 
 */
@interface MBIFSFractal () {
    double _maxLineWidth;
}

#pragma mark - Model
@property (strong,readwrite) NSMutableString*           production;
@property (strong,readwrite) NSMutableDictionary*       replacementRules;
@property (strong,readwrite) NSMutableDictionary*       drawingRules;
@property (assign,readwrite) CGRect                     bounds;

@property (readwrite,atomic,strong) MBFractalSegment*   currentSegment;

-(void) addSegment: (MBFractalSegment*) segment;
-(void) dispatchDrawingSelectorFromString:(NSString*)selector withArg:(id)arg;
-(void) evaluateRule: (NSString*) rule;

@end



@implementation MBIFSFractal

@synthesize levels = _levels, axiom = _axiom, productNeedsGenerating = _productNeedsGenerating, pathNeedsGenerating = _pathNeedsGenerating;

@synthesize replacementRules = _replacementRules;
@synthesize production = _production;
@synthesize drawingRules = _drawingRules;
@synthesize segments = _segments;
@synthesize segmentStack = _segmentStack;
@synthesize bounds = _bounds;

@synthesize currentSegment = _currentSegment;

@synthesize lineWidth = _lineWidth;
@synthesize lineColor = _lineColor;
@synthesize fillColor = _fillColor;
@synthesize fill=_fill, stroke=_stroke;

- (id)init {
    self = [super init];
    if (self) {
        _productNeedsGenerating = NO;
        _pathNeedsGenerating = NO;
        
        MBFractalSegment* newSegment = [[MBFractalSegment alloc] init];

        _segmentStack = [[NSMutableArray alloc] initWithCapacity: 1];
        
        _currentSegment = newSegment;
                
    }
    return self;
}



#pragma mark - segment getter setters

-(CGColorRef) lineColor {
    return self.currentSegment.lineColor;
}

-(void) setLineColor:(CGColorRef)lineColor {
    self.currentSegment.lineColor = lineColor;
}

-(CGColorRef) fillColor {
    return self.currentSegment.fillColor;
}

-(void) setFillColor:(CGColorRef)fillColor {
    self.currentSegment.fillColor = fillColor;
}

-(double) lineWidth {
    return self.currentSegment.lineWidth;
}

-(void) setLineWidth:(double)lineWidth {
    self.currentSegment.lineWidth = lineWidth;
}

-(BOOL) stroke {
    return self.currentSegment.stroke;
}

-(void) setStroke:(BOOL)stroke {
    self.currentSegment.stroke = stroke;
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
    if ([self.segments count]>0) {
        MBFractalSegment* olderCurrentSegment = [self.segments lastObject];
        [self.segments removeLastObject];
        
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
    if (self.replacementRules == nil) {
        NSMutableDictionary* newRules = [[NSMutableDictionary alloc] initWithCapacity: 20];
        [self setReplacementRules: newRules];
    }
    
    [self.replacementRules setObject: replacement forKey: original];
    self.productNeedsGenerating = YES;
}

-(void) resetRules {
    self.replacementRules = nil;
    self.productNeedsGenerating = YES;
}

-(void) addDrawingRuleString:(NSString*)character executesSelector:(NSString*)selector withArgument:(id)arg {
    if (self.drawingRules == nil) {
        self.drawingRules = [[NSMutableDictionary alloc] initWithCapacity: 4];
    }
    NSArray* drawingArgs = [[NSArray alloc] initWithObjects: selector, arg, nil];
    [self.drawingRules setObject: drawingArgs forKey: character];
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
    NSArray* drawingResponse = [self.drawingRules objectForKey: rule];
    if ([drawingResponse isKindOfClass: [NSArray class]]) {
        NSString* selector = [drawingResponse objectAtIndex: 0];
        id arg = [drawingResponse objectAtIndex: 1];
        [self dispatchDrawingSelectorFromString: selector withArg: arg];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

-(void) dispatchDrawingSelectorFromString:(NSString*)selector withArg:(id)arg {
    if ([self respondsToSelector:NSSelectorFromString(selector)]) {
        [self performSelector: NSSelectorFromString(selector) withObject: arg];
    }
}

#pragma clang diagnostic pop

-(void) drawLine: (id) arg {
    if ([arg isKindOfClass: [NSNumber class]]) {
        double tx = [(NSNumber*)arg doubleValue];
        CGAffineTransform local = self.currentSegment.transform;
        CGPathAddLineToPoint(self.currentSegment.path, &local, tx, 0);
        self.currentSegment.transform = CGAffineTransformTranslate(self.currentSegment.transform, tx, 0.0f);
    }
}

-(void) rotate: (id) arg {
    if ([arg isKindOfClass: [NSNumber class]]) {
        double theta = [(NSNumber*)arg doubleValue];
        self.currentSegment.transform = CGAffineTransformRotate(self.currentSegment.transform, theta);
    }
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
