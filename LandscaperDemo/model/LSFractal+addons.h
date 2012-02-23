//
//  LSFractal+addons.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/01/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "LSFractal.h"

@interface LSFractal (addons)

/*!
 for cut and paste functionality
 */
+(NSSet*)keysToBeCopied;
+(NSSet*) lableProperties;
+(NSSet*) productionRuleProperties;
+(NSSet*) appearanceProperties;


-(UIColor*) lineColorAsUI;
-(UIColor*) fillColorAsUI;

-(double) lineLengthAsDouble;
-(void) setLineLengthAsDouble: (double) newLength;

-(double) turningAngleAsDouble;
-(NSNumber*) turningAngleAsDegree;
-(void) setTurningAngleAsDouble: (double) newAngle;
-(void) setTurningAngleAsDegrees: (NSNumber*) newAngle;

-(NSNumber*) baseAngleAsDegree;
-(void) setBaseAngleAsDegrees: (NSNumber*) newAngle;
@end
