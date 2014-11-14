//
//  LSFractalGenerator.h
//  FractalScape
//
//  Created by Taun Chapman on 01/19/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 1   L-System fractal drawing rules from http://paulbourke.net/fractals/fracintro/
 2   F :  Move forward by line length drawing a line
 3   f :  Move forward by line length without drawing a line
 4   + :  Turn left by turning angle
 5   - :  Turn right by turning angle
 6   | :  Reverse direction (turn by 180)
 7   [ :  Push current drawing state onto stack
 8   ] :  Pop current drawing state off stack
 9   # :  Increment the line width by line width increment
10   ! :  Decrement the line width by line width
11   O :  Draw a dot with line width radius - fill depends on fractal fill setting
12   @ :  Draw a filled dot no stroke with line width radius - independent of fractal fill setting
13   { :  Open a polygon
14   } :  Close a polygon and fill with fill color
15   > :  Multiply the line length by the line length scale factor
16   < :  Divide the line length by the line length scale factor
17   & :  Swap the meaning of + and -
18   ( :  Decrement turning angle by turning angle increment
19   ) :  Increment turning angle by turning angle increment
     
    Added adhoc rules for more flexibility:
20   s :  turn context stroke off - overrides global per context. push [s ...] context first
21   S :  turn context stroke on
22   l :  turn context fill off
23   L :  turn context fill on
24   r :  randomize context on
25   R :  randomize context off
     
26   A :  Noop placeholder
27   B :  Noop placeholder
28   C :  Noop placeholder
29   D :  Noop placeholder
30   E :  Noop placeholder

31   a :  next line color - circular n.max++ -> n.min
32   b :  previous line color
33   c :  next fill color
34   d :  previous fill color
 
 
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

@class LSFractal;

/*!
 Takes an LSFractal definition given to it from core data and generates the production string and core graphics path.
 
 Need an LSFractal controller which intermediates between view and model.
 Gets context from view and segments from LSFractalGenerator?
 
 Internally, the generator uses a private queue for the fractal context.
 This should avoid problems where generator operations are performed on separate threads by callers.
 */
@interface LSFractalGenerator : NSObject

@property (nonatomic, strong) LSFractal*            fractal;

/*!
 Overrides the fractal level in order to allow multiple views of the same fractal with different generation levels.
 */
@property (nonatomic, assign) double                forceLevel;

@property (nonatomic,assign,readonly) CGRect        bounds;

@property (nonatomic, assign) BOOL                  autoscale;
@property (nonatomic, assign) double                scale;
@property (nonatomic, assign) CGPoint               translate;
//@property (nonatomic, unsafe_unretained) CGPathRef  path;
@property (nonatomic,unsafe_unretained) CGPathRef   fractalCGPathRef;

@property (NS_NONATOMIC_IOSONLY, readonly) double randomScalar;
/*
 The drawing rules are cached from the managed object. This is because the rules are returned as a set and we need to convert them to a dictionary. We only want to do this once unless the rules are changed. Need to observer the rules and if there is a change, clear the cache.
 */
-(void) clearCache;

-(void) productionRuleChanged;

-(void) geometryChanged;

/*!
 Height/Width aspect ratio.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) double aspectRatio;

/*!
 Returns the width and height of maximum close fitting dimension of the fractal which will fit in a 1x1 box.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) CGSize unitBox;

///*!
// Use to flip or rotate the fractal before generating the path.
// */
//-(void) setInitialTransform: (CGAffineTransform) transform;

-(void) drawInBounds: (CGRect) layerBounds withContext: (CGContextRef) theContext flipped: (BOOL) isFlipped;

-(UIImage*)generateImageSize: (CGSize)size withBackground: (UIColor*)uiColor;

-(BOOL)hasImageSize: (CGSize) size;

#pragma mark - layer delegate
- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext;

//-(void) charge;

#pragma mark Default Drawing Rule Methods
-(void) commandDoNothing;
-(void) commandDrawLine;
-(void) commandMoveByLine;
-(void) commandRotateCC;
-(void) commandRotateC;
-(void) commandReverseDirection;
-(void) commandPush;
-(void) commandPop;
-(void) commandIncrementLineWidth;
-(void) commandDecrementLineWidth;
-(void) commandDrawDot;
-(void) commandDrawDotFilledNoStroke;
-(void) commandOpenPolygon;
-(void) commandClosePolygon;
-(void) commandUpscaleLineLength;
-(void) commandDownscaleLineLength;
-(void) commandSwapRotation;
-(void) commandDecrementAngle;
-(void) commandIncrementAngle;
-(void) commandStrokeOff;
-(void) commandStrokeOn;
-(void) commandFillOn;
-(void) commandFillOff;
-(void) commandRandomizeOn;
-(void) commandRandomizeOff;
-(void) commandNextColor;
-(void) commandPreviousColor;
-(void) commandNextFillColor;
-(void) commandPreviousFillColor;

@end
