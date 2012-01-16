//
//  MBIFSFractal.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class MBFractalSegment;

@interface MBIFSFractal : NSObject 


@property (assign) NSUInteger                       levels;
@property (copy) NSString*                          axiom;
@property (strong,readonly) NSMutableString*        production;
@property (strong,readonly) NSMutableDictionary*    replacementRules;
@property (strong,readonly) NSMutableDictionary*    drawingRules;
@property (assign) BOOL                             productNeedsGenerating;
@property (assign) BOOL                             pathNeedsGenerating;

@property (strong,readonly) NSMutableArray*         segments;
@property (strong,readwrite) NSMutableArray*        segmentStack;
@property (assign,readonly) CGRect                  bounds;

@property (nonatomic,assign) double                 lineWidth;
@property (nonatomic,assign) CGColorRef             lineColor;
@property (nonatomic,assign) CGColorRef             fillColor;
@property (nonatomic, readwrite) BOOL               fill;
@property (nonatomic, readwrite) BOOL               stroke;

/*!
 Height/Width aspect ratio.
 */
-(double) aspectRatio;

/*!
 Returns the width an height of maximum close fitting dimension of the fractal which will fit in a 1x1 box.
 */
-(CGSize) unitBox;

-(void) addProductionRuleReplaceString: (NSString*) original withString: (NSString*) replacement;
-(void) addDrawingRuleString:(NSString*)character executesSelector:(NSString*)selector withArgument:(id)arg;
-(void) resetRules;
-(void) generateProduct;
-(void) generatePaths;

-(void) drawLine: (id) arg;
-(void) rotate: (id) arg;

-(void) finalizeSegments;

-(void) pushSegment;
-(void) popSegment;

@end
