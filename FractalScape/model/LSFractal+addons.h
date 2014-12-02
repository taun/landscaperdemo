//
//  LSFractal+addons.h
//  FractalScape
//
//  Created by Taun Chapman on 02/01/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "LSFractal.h"

#include <math.h>

static inline double radians (double degrees) {return degrees * M_PI/180.0;}
static inline double degrees (double radians) {return radians * 180.0/M_PI;}

@interface LSFractal (addons)

+(NSArray*) allFractalsInContext: (NSManagedObjectContext *)context;
+(LSFractal*) findFractalWithName:(NSString *)fractalIdentifier inContext: (NSManagedObjectContext*) context;

/*!
 A set of fractal property paths which effect the label views of the fractal. To be observed by presenters of the labels
 
 @return a set of strings corresponding to fractal property key paths effecting the labels.
 */
+(NSSet*) labelProperties;
/*!
 A set of fractal property paths which effect the production of the final fractal generation. Such as rules, replacementRules, ...
 
 @return a set of strings corresponding to fractal production generation key paths effecting the graphic views.
 */
+(NSSet*) productionRuleProperties;
/*!
 A set of fractal property paths which effect the appearance of the final fractal generation. Such as color, stroke, ...
 
 @return a set of strings corresponding to fractal drawing key paths effecting the graphic views.
 */
+(NSSet*) appearanceProperties;
/*!
 A set of fractal property paths which only effect drawing of the line segments. Menaing neither the production nor the segment deneration are effect.
 
 @return a set of property path strings.
 */
+(NSSet*) redrawProperties;

-(NSArray*) allCategories;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString           *startingRulesString;

@property (NS_NONATOMIC_IOSONLY) double                             lineLengthAsDouble;

@property (NS_NONATOMIC_IOSONLY) double                         turningAngleAsDouble;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSNumber      *turningAngleAsDegrees;

-(void) setTurningAngleAsDegrees: (NSNumber*) newAngle;

@property (NS_NONATOMIC_IOSONLY) double                            turningAngleIncrementAsDouble;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSNumber      *turningAngleIncrementAsDegrees;

-(void) setTurningAngleIncrementAsDegrees: (NSNumber*)          newAngle;

@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSNumber      *baseAngleAsDegrees;

-(void) setBaseAngleAsDegrees: (NSNumber*) newAngle;

@end
