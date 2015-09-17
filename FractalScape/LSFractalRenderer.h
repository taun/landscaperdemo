//
//  LSFractalRenderer.h
//  FractalScape
//
//  Created by Taun Chapman on 01/05/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//


@import Foundation;

#import "MBFractalSegment.h"

@class LSFractal;
@class LSDrawingRuleType;
@class MBColor;

/*!
 1   L-System fractal drawing rules from http://paulbourke.net/fractals/fracintro/
 2   F :  Move forward by line length drawing a line
 3   G :  Move forward by line length without drawing a line
     H :  Move forward by line length drawing a line. Shorten line by line length scale each generation.
 4   + :  Turn left by turning angle
 5   - :  Turn right by turning angle
 6   | :  Reverse direction (turn by 180)
 7   [ :  Push current drawing state onto stack
 8   ] :  Pop current drawing state off stack
 9   # :  Increment the line width by line width increment
 10   ! :  Decrement the line width by line width
 11   O :  Draw a dot with line width radius - fill depends on fractal fill setting
 12   @ :  Draw a filled dot no stroke with line width radius - independent of fractal fill setting
X 13   { :  Open a polygon -> change to start curve
X 14   } :  Close a polygon and fill with fill color - > change to end curve
 15   > :  Multiply the line length by the line length scale factor
 16   < :  Divide the line length by the line length scale factor
 17   & :  Swap the meaning of + and -
 18   ( :  Decrement turning angle by turning angle increment
 19   ) :  Increment turning angle by turning angle increment
 . ;  Insert a curve point node
 , ;  Insert a curve CC
 ` ;  Insert a curve C
 
X :   draw applying current settings
X ;   close path
 
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
 Z :  Noop placeholder - for internal default rule when there is no rule
 
 31   a :  next line color - circular n.max++ -> n.min
 32   b :  previous line color
 33   c :  next fill color
 34   d :  previous fill color
 34   e :  lineCapButt
 34   f :  lineCapRound
 34   g :  lineCapSquare
 34   h :  lineJoinMitre
 34   i :  lineJoinRound
 34   j :  lineJoinBevel
 35   k :  RotateLineHue
 36   m :  RotateLineBrightness
 37   n :  RotateLineSaturation
 38   o :  RotateFillHue
 39   p :  RotateFillBrightness
 40   q :  RotateFillSaturation
 
 Added:
    : drawPath
    ; closePath
 
 Changed:
    { was polygon, now start curve
    } was polygon, now end curve
 
 Swapped
    ^ from # increment line width
    ` from ! decrement line width
 
    ! from : drawPath
    . from ; closePath
 
 
 Removed 
    . insert curve point node
    , Insert a curve CC
    ` Insert a curve C

 
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
 a -> FFFFFv[+++h][---q]Gb
 b -> FFFFFv[+++h][---q]Gc
 c -> FFFFFv[+++Ga]Gd
 d -> FFFFFv[+++h][---q]Ge
 e -> FFFFFv[+++h][---q]Gg
 g -> FFFFFv[---Ga]Ga
 h -> iGFF
 i -> GFFF[--m]j
 j -> GFFF[--n]k
 k -> GFFF[--o]l
 l -> GFFF[--p]
 m -> GFn
 n -> GFo
 o -> GFp
 p -> GF
 q -> rGF
 r -> GFFF[++m]s
 s -> GFFF[++n]t
 t -> GFFF[++o]u
 u -> GFFF[++p]
 v -> Fv
 angle = 12
 
 
 */

/*!
 Given a levelData and property data from a fractal, this class will draw the image in either a given context 
 or create it's own bitmap image save in the image property.
 
 The generator is designed to be used in an operation block therefore it does not keep any reference to the 
 fractal object. All data needs to be given to the generator before it is dispatched to generate the image.
 If the imageView property is set, the generator will set the imageView.image to the generated image on the 
 main thread. 
 
 The same generator can not be used in multiple concurrent operations.
 A separate fractalGenerator should be used for each image size and level.
 */
@interface LSFractalRenderer : NSObject

+(instancetype) newRendererForFractal: (LSFractal*)aFractal withSourceRules: (LSDrawingRuleType*)sourceRules;
-(instancetype) initWithFractal: (LSFractal*) aFractal withSourceRules: (LSDrawingRuleType*)sourceRules;
/*!
 For convenience during debugging multiple threads/operations.
 */
@property (nonatomic,strong) NSString               *name;
/*!
 Points to inset the image within the bounds.
 */
@property (nonatomic,assign) CGFloat                margin;
/*!
 Whether the image should be flipped vertically.
 */
@property (nonatomic,assign) BOOL                   flipY;
@property (nonatomic,assign) CGFloat                pixelScale;
@property (nonatomic,copy) MBColor                  *defaultLineColor;
@property (nonatomic,copy) MBColor                  *defaultFillColor;
@property (nonatomic,copy) MBColor                  *backgroundColor;
@property (atomic,weak) UIImageView                 *mainThreadImageView;
@property (nonatomic,assign,readonly) CGRect        rawFractalPathBounds;
@property (nonatomic,copy) NSData                   *levelData;
@property (nonatomic,assign) CGFloat                renderTime;
@property (atomic,strong) UIImage                   *image;
@property (atomic,assign) CGImageRef                imageRef;
@property (nonatomic,assign) BOOL                   autoscale;
@property (nonatomic,assign) BOOL                   autoExpand;
@property (nonatomic,assign) BOOL                   showOrigin;
@property (nonatomic,assign) BOOL                   applyFilters;
@property (nonatomic,assign) CGFloat                scale;
@property (nonatomic,assign) CGFloat                translateX;
@property (nonatomic,assign) CGFloat                translateY;
@property (nonatomic,weak) NSBlockOperation         *operation;

@property (atomic, readonly) NSMutableData   *contextNSData;

//@property (nonatomic, unsafe_unretained) CGPathRef  path;
@property (NS_NONATOMIC_IOSONLY, readonly) CGFloat randomScalar;
/*!
 Height/Width aspect ratio.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) CGFloat aspectRatio;

/*!
 Returns the width and height of maximum close fitting dimension of the fractal which will fit in a 1x1 box.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) CGSize unitBox;

-(void) setValuesForFractal:(LSFractal *)aFractal;

-(void) generateImage;
-(void) generateImagePercentStart: (CGFloat)start stop: (CGFloat)stop;
-(void) drawInContext: (CGContextRef) aCGContext size: (CGSize)size;
-(void) drawInContext: (CGContextRef) aCGContext size: (CGSize)size percentStart: (CGFloat)start stop: (CGFloat)stop;

//-(void) charge;
/*!
 There are 2 basic categories of command.
 Those that change a path property and those that don't. Commands which change a path property can only be assured 
 of action if the current path is drawn before setting the property. This is because path properties only take effect
 when the path is drawn. If we change a property twice but do not draw the path in between changes, the first change
 is lost. For example, stroke color is a path property. All of the path has the same color. That color is whichever color property
 is current at the time the path is drawn. Therefore, to change the color of the path, it needs to be stroked with the first color
 then a new path defined for the second color. 
 
 This has certain side effects on other rules and properties. For example:
 
    Can not have a fill in a shape which has changing stroke colors. Changing the stroke results in two separate paths which then can't be filled?
 
 */
#pragma mark - Drawing Rule Methods
#pragma mark Non path properties
-(void) commandDoNothing;
-(void) commandDrawLine;
-(void) commandDrawLineVarLength;
-(void) commandMoveByLine;
-(void) commandRotateCC;
-(void) commandRotateC;
-(void) commandReverseDirection;
-(void) commandDrawDot;
-(void) commandDrawDotFilledNoStroke;
-(void) commandOpenPolygon;
-(void) commandClosePolygon;
-(void) commandUpscaleLineLength;
-(void) commandDownscaleLineLength;
-(void) commandSwapRotation;
-(void) commandDecrementAngle;
-(void) commandIncrementAngle;
-(void) commandRandomizeOn;
-(void) commandRandomizeOff;
-(void) commandStartCurve;
-(void) commandEndCurve;
-(void) commandDrawPath;
-(void) commandClosePath;
-(void) commandPush;
#pragma mark Path Properties
-(void) commandPop;
-(void) commandStrokeOff;
-(void) commandStrokeOn;
-(void) commandLineJoinMiter;
-(void) commandLineJoinRound;
-(void) commandLineJoinBevel;
-(void) commandLineCapButt;
-(void) commandLineCapRound;
-(void) commandLineCapSquare;
-(void) commandIncrementLineWidth;
-(void) commandDecrementLineWidth;
-(void) commandFillOn;
-(void) commandFillOff;
-(void) commandNextColor;
-(void) commandPreviousColor;
-(void) commandNextFillColor;
-(void) commandPreviousFillColor;
-(void) commandRotateLineHue;
-(void) commandRotateLineBrightness;
-(void) commandRotateLineSaturation;
-(void) commandRotateFillHue;
-(void) commandRotateFillBrightness;
-(void) commandRotateFillSaturation;

@end


