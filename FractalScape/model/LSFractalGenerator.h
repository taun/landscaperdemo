//
//  LSFractalGenerator.h
//  FractalScape
//
//  Created by Taun Chapman on 01/19/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

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
 
Added adhoc rules for more flexibility:
  s: turn context stroke off - overrides global per context. push [s ...] context first
  S: turn context stroke on
  l: turn context fill off
  L: turn context fill on
  r: randomize context on
  R: randomize context off
 
 
 
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

@property (nonatomic, strong) LSFractal*        fractal;

/*!
 Overrides the fractal level in order to allow multiple views of the same fractal with different generation levels.
 */
@property (nonatomic, assign) double            forceLevel;

@property (nonatomic,assign,readonly) CGRect    bounds;

@property (nonatomic, assign) BOOL              autoscale;
@property (nonatomic, assign) double            scale;
@property (nonatomic, assign) CGPoint           translate;

+(double)randomDoubleBetween:(double)smallNumber and:(double)bigNumber;
@property (NS_NONATOMIC_IOSONLY, readonly) double randomScalar;
/*
 The drawing rules are cached from the managed object. This is because the rules are returned as a set and we need to convert them to a dictionary. We only want to do this once unless the rules are changed. Need to observer the rules and if there is a change, clear the cache.
 */
-(void) clearCache;

-(void) productionRuleChanged;

-(void) appearanceChanged;

/*!
 Height/Width aspect ratio.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) double aspectRatio;

/*!
 Returns the width and height of maximum close fitting dimension of the fractal which will fit in a 1x1 box.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) CGSize unitBox;

/*!
 Use to flip or rotate the fractal before generating the path.
 */
-(void) setInitialTransform: (CGAffineTransform) transform;

-(void) drawInBounds: (CGRect) layerBounds withContext: (CGContextRef) theContext flipped: (BOOL) isFlipped;

-(UIImage*)generateImageSize: (CGSize)size withBackground: (UIColor*)uiColor;

-(BOOL)hasImageSize: (CGSize) size;

#pragma mark - layer delegate
- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)theContext;

//-(void) charge;
@end
