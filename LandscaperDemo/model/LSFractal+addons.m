//
//  LSFractal+addons.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/01/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "LSFractal+addons.h"
#import "MBColor+addons.h"
#include <math.h>

static inline double radians (double degrees) {return degrees * M_PI/180.0;}
static inline double degrees (double radians) {return radians * 180.0/M_PI;}

@implementation LSFractal (addons)

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"axiom",
                          @"category",
                          @"descriptor",
                          @"fill",
                          @"isImmutable",
                          @"isReadOnly",
                          @"level",
                          @"lineLength",
                          @"lineLengthScaleFactor",
                          @"lineWidth",
                          @"lineWidthIncrement",
                          @"stroke",
                          @"turningAngle",
                          @"turningAngleIncrement",
                          @"drawingRulesType",
                          @"fillColor",
                          @"lineColor",
                          @"replacementRules",
                          @"name",
                          nil];
    }
    return keysToBeCopied;
}

+(NSSet*) lableProperties {
    static NSSet* lableProperties = nil;
    if (lableProperties == nil) {
        lableProperties = [[NSSet alloc] initWithObjects:
                                    @"name",
                                    @"descriptor", 
                                    nil];
    }
    return lableProperties;
}

+(NSSet*) productionRuleProperties {
    static NSSet* productionRuleProperties = nil;
    if (productionRuleProperties == nil) {
        productionRuleProperties = [[NSSet alloc] initWithObjects:
                                    @"axiom",
                                    @"replacementRules", 
                                    @"level",
                                    nil];
    }
    return productionRuleProperties;
}

+(NSSet*) appearanceProperties {
    static NSSet* appearanceProperties = nil;
    if (appearanceProperties == nil) {
        appearanceProperties = [[NSSet alloc] initWithObjects:
                                @"lineLength",
                                @"lineWidth",
                                @"lineColor",
                                @"stroke",
                                @"fill",
                                @"fillColor",
                                @"turningAngle",
                                nil];
    }
    return appearanceProperties;
}


-(id) mutableCopy {
    NSManagedObject *fractalCopy = [NSEntityDescription
                              insertNewObjectForEntityForName:@"LSFractal"
                              inManagedObjectContext: self.managedObjectContext];
    
    if (fractalCopy) {
        for ( NSString* aKey in [LSFractal keysToBeCopied]) {
            id value = [self valueForKey: aKey];
            [fractalCopy setValue: value forKey: aKey];
        }
    }
    return fractalCopy;
}

-(UIColor*) lineColorAsUI {
    UIColor* result = nil;
    if (self.lineColor == nil) {
        result = [MBColor defaultUIColor];
    } else {
        result = [self.lineColor asUIColor];
    }
    return result;
}

-(UIColor*) fillColorAsUI {
    UIColor* result = nil;
    if (self.fillColor == nil) {
        result = [MBColor defaultUIColor];
    } else {
        result = [self.fillColor asUIColor];
    }
    return result;
}

-(double) lineLengthAsDouble {
    return [self.lineLength doubleValue];
}

-(void) setLineLengthAsDouble:(double)newLength {
    self.lineLength = [NSNumber numberWithDouble: newLength];
}

-(double) turningAngleAsDouble {
    return [self.turningAngle doubleValue];
}

-(NSNumber*) turningAngleAsDegree {
    return [NSNumber numberWithDouble: degrees([self.turningAngle doubleValue])];
}

-(void) setTurningAngleAsDouble:(double)newAngle {
    self.turningAngle = [NSNumber numberWithDouble: newAngle];
}

-(void) setTurningAngleAsDegrees:(NSNumber*)newAngle {
    double inRadians = radians([newAngle doubleValue]);
    self.turningAngle = [NSNumber numberWithDouble: inRadians];
}
@end
