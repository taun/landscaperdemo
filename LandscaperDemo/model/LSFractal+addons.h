//
//  LSFractal+addons.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/01/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "LSFractal.h"

#include <math.h>

static inline double radians (double degrees) {return degrees * M_PI/180.0;}
static inline double degrees (double radians) {return radians * 180.0/M_PI;}

@interface LSFractal (addons)

/*!
 for cut and paste functionality
 */
+(NSSet*) keysToBeCopied;
+(NSSet*) lableProperties;
+(NSSet*) productionRuleProperties;
+(NSSet*) appearanceProperties;

-(void) setLineColorFromIdentifier: (NSString*) colorIdentifier;
-(void) setFillColorFromIdentifier: (NSString*) colorIdentifier;

-(UIColor*) lineColorAsUI;
-(UIColor*) fillColorAsUI;

-(double) lineLengthAsDouble;
-(void) setLineLengthAsDouble: (double) newLength;

-(double) turningAngleAsDouble;
-(NSNumber*) turningAngleAsDegree;
-(void) setTurningAngleAsDouble: (double) newAngle;
-(void) setTurningAngleAsDegrees: (NSNumber*) newAngle;

-(double) turningAngleIncrementAsDouble;
-(NSNumber*) turningAngleIncrementAsDegree;
-(void) setTurningAngleIncrementAsDouble: (double) newAngle;
-(void) setTurningAngleIncrementAsDegrees: (NSNumber*) newAngle;

-(NSNumber*) baseAngleAsDegree;
-(void) setBaseAngleAsDegrees: (NSNumber*) newAngle;

-(NSArray*) newSortedReplacementRulesArray;
@end
