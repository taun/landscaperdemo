//
//  MBLSFractal.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class MBFractalSegment;

/*!
 L-System fractal drawing rules from http://paulbourke.net/fractals/fracintro/
     F: Move forward by line length drawing a line
     f: Move forward by line length without drawing a line
     +: Turn left by turning angle
     -: Turn right by turning angle
     |: Reverse direction (turn by 180)
     [: Push current drawing state onto stack
     ]: Pop current drawing state off stack
     #: Increment the line width by line width increment
     !: Decrement the line width by line width
     @: Draw a dot with line width radius
     {: Open a polygon
     }: Close a polygon and fill with fill color
     >: Multiply the line length by the line length scale factor
     <: Divide the line length by the line length scale factor
     &: Swap the meaning of + and -
     (: Decrement turning angle by turning angle increment
     ): Increment turning angle by turning angle increment
 
 Variables
     LineLength
     turningAngle
     turningAngleIncrement
     lineWidth
     lineWidthIncrement
     fillColor
     lineLengthScaleFactor
 
 Rings: axiom = F+F+F+F
        F -> FF+F+F+F+F+F-F
        angle = 90
 
 Von Koch Snowflake
         axiom = F++F++F
         F -> F-F++F-F
         angle = 60
 
 Von Koch Island
         axiom = F+F+F+F
         F -> F+F-F-FFF+F+F-F
         angle = 90
 
 Pentaplexity
         axiom = F++F++F++F++F
         F -> F++F++F|F-F++F
         angle = 36
 
Leaf
 axiom = a
 F -> >F<
 a -> F[+x]Fb
 b -> F[-y]Fa
 x -> a
 y -> b
 angle = 45
 length factor = 1.36
 
Bush1
 axiom = Y
 X -> X[-FFF][+FFF]FX
 Y -> YFX[+Y][-Y]
 angle = 25.7

Bush2
 axiom = F
 F -> FF+[+F-F-F]-[-F+F+F]
 angle = 22.5
 
Bush3
 axiom = F
 F -> F[+FF][-FF]F[-F][+F]F
 angle = 35
 
Bush4
 axiom = X
 F -> FF
 X -> F[+X]F[-X]+X
 angle = 20
 
Bush5
 axiom = VZFFF
 V -> [+++W][---W]YV
 W -> +X[-W]Z
 X -> -W[+X]Z
 Y -> YZ
 Z -> [-FFF][+FFF]F
 angle = 20
 
Algae
 axiom = aF
 a -> FFFFFv[+++h][---q]fb
 b -> FFFFFv[+++h][---q]fc
 c -> FFFFFv[+++fa]fd
 d -> FFFFFv[+++h][---q]fe
 e -> FFFFFv[+++h][---q]fg
 g -> FFFFFv[---fa]fa
 h -> ifFF
 i -> fFFF[--m]j
 j -> fFFF[--n]k
 k -> fFFF[--o]l
 l -> fFFF[--p]
 m -> fFn
 n -> fFo
 o -> fFp
 p -> fF
 q -> rfF
 r -> fFFF[++m]s
 s -> fFFF[++n]t
 t -> fFFF[++o]u
 u -> fFFF[++p]
 v -> Fv
 angle = 12
 

 */

@interface MBLSFractal : NSObject 


@property (nonatomic,assign) NSUInteger                       levels;
@property (nonatomic,copy) NSString*                          axiom;
@property (nonatomic,strong,readonly) NSMutableString*        production;
@property (nonatomic,strong,readonly) NSMutableDictionary*    replacementRules;
@property (nonatomic,strong,readonly) NSMutableDictionary*    drawingRules;
@property (nonatomic,assign) BOOL                             productNeedsGenerating;
@property (nonatomic,assign) BOOL                             pathNeedsGenerating;

@property (nonatomic,strong,readonly) NSMutableArray*         finishedSegments;
@property (nonatomic,strong,readwrite) NSMutableArray*        segmentStack;
@property (nonatomic,assign,readonly) CGRect                  bounds;

// TODO copy new properties to segment class
// TODO add array dictionary of fill and stroke colors to be accessed as segments are pushed access will not go past end and will just use last item.
@property (nonatomic,assign) double                 turningAngle;
@property (nonatomic,assign) double                 turningAngleIncrement;
@property (nonatomic,assign) double                 lineLength;
@property (nonatomic,assign) double                 lineWidth;
@property (nonatomic,assign) double                 lineWidthIncrement;
@property (nonatomic,assign) double                 lineLengthScaleFactor;
@property (nonatomic,assign) CGColorRef             lineColor;
@property (nonatomic, readwrite) BOOL               stroke;
@property (nonatomic,assign) CGColorRef             fillColor;
@property (nonatomic, readwrite) BOOL               fill;

+(NSMutableDictionary*) defaultDrawingRules;

-(void) finalizeSegments;

-(void) pushSegment;
-(void) popSegment;

/*!
 Height/Width aspect ratio.
 */
-(double) aspectRatio;

/*!
 Returns the width an height of maximum close fitting dimension of the fractal which will fit in a 1x1 box.
 */
-(CGSize) unitBox;

-(void) setInitialTransform: (CGAffineTransform) transform;

-(void) addProductionRuleReplaceString: (NSString*) original withString: (NSString*) replacement;
-(void) addDrawingRuleString:(NSString*)character executesSelector:(NSString*)selector;
-(void) resetRules;
-(void) generateProduct;
-(void) generatePaths;

#pragma mark - Public Rule Methods
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
