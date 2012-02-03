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
+ (NSArray *)keysToBeCopied;

-(UIColor*) lineColorAsUI;
-(UIColor*) fillColorAsUI;

-(double) lineLengthAsDouble;
-(void) setLineLengthAsDouble: (double) newLength;

-(double) turningAngleAsDouble;
-(double) turningAngleAsDegree;
-(void) setTurningAngleAsDouble: (double) newAngle;
-(void) setTurningAngleAsDegrees: (double) newAngle;
@end
