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
 for cut and paste functionality
 */
+(NSSet*) keysToBeCopied;
+(NSSet*) labelProperties;
+(NSSet*) productionRuleProperties;
+(NSSet*) appearanceProperties;

-(void) setLineColorFromIdentifier: (NSString*) colorIdentifier;
-(void) setFillColorFromIdentifier: (NSString*) colorIdentifier;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) UIColor *lineColorAsUI;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) UIColor *fillColorAsUI;

@property (NS_NONATOMIC_IOSONLY) double lineLengthAsDouble;

@property (NS_NONATOMIC_IOSONLY) double turningAngleAsDouble;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSNumber *turningAngleAsDegree;
-(void) setTurningAngleAsDegrees: (NSNumber*) newAngle;

@property (NS_NONATOMIC_IOSONLY) double turningAngleIncrementAsDouble;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSNumber *turningAngleIncrementAsDegree;
-(void) setTurningAngleIncrementAsDegrees: (NSNumber*) newAngle;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSNumber *baseAngleAsDegree;
-(void) setBaseAngleAsDegrees: (NSNumber*) newAngle;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *newSortedReplacementRulesArray;
@end
