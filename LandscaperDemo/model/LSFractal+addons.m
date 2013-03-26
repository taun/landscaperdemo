//
//  LSFractal+addons.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/01/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "LSFractal+addons.h"
#import "MBColor+addons.h"

@implementation LSFractal (addons)

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"axiom",
                          @"category",
                          @"descriptor",
                          @"fill",
                          @"eoFill",
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
                          @"baseAngle",
                          @"drawingRulesType",
                          @"fillColor",
                          @"lineColor",
                          @"lineJoin",
                          @"lineCap",
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
                                    @"replacementString",
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
                                @"lineJoin",
                                @"lineCap",
                                @"stroke",
                                @"fill",
                                @"eoFill",
                                @"fillColor",
                                @"turningAngle",
                                @"baseAngle",
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
        NSString* newName = [NSString stringWithFormat:@"%@ copy",[self valueForKey: @"name"]];
        [fractalCopy setValue: newName forKey: @"name"];
        [fractalCopy setValue: @NO forKey: @"isImmutable"];
        [fractalCopy setValue: @NO forKey: @"isReadOnly"];
    }
    return fractalCopy;
}

-(void) setLineColorFromIdentifier:(NSString *)colorIdentifier {
    MBColor* mbColor = [MBColor findMBColorWithIdentifier: colorIdentifier inContext: self.managedObjectContext];
    self.lineColor = mbColor;
}
-(void) setFillColorFromIdentifier:(NSString *)colorIdentifier {
    MBColor* mbColor = [MBColor findMBColorWithIdentifier: colorIdentifier inContext: self.managedObjectContext];
    self.fillColor = mbColor;
}

-(UIColor*) lineColorAsUI {
    UIColor* result = nil;
    if (self.lineColor == nil) {
        result = [MBColor newDefaultUIColor];
    } else {
        result = [self.lineColor asUIColor];
    }
    return result;
}

-(UIColor*) fillColorAsUI {
    UIColor* result = nil;
    if (self.fillColor == nil) {
        result = [MBColor newDefaultUIColor];
    } else {
        result = [self.fillColor asUIColor];
    }
    return result;
}
-(double) lineLengthAsDouble {
    return [self.lineLength doubleValue];
}
-(void) setLineLengthAsDouble:(double)newLength {
    self.lineLength = @(newLength);
}
-(double) turningAngleAsDouble {
    return [self.turningAngle doubleValue];
}
-(NSNumber*) turningAngleAsDegree {
    return @(degrees([self.turningAngle doubleValue]));
}
-(void) setTurningAngleAsDouble:(double)newAngle {
    self.turningAngle = @(newAngle);
}
-(void) setTurningAngleAsDegrees:(NSNumber*)newAngle {
    double inRadians = radians([newAngle doubleValue]);
    self.turningAngle = @(inRadians);
}
-(double) turningAngleIncrementAsDouble {
    return [self.turningAngleIncrement doubleValue];
}
-(NSNumber*) turningAngleIncrementAsDegree {
    return @(degrees([self.turningAngleIncrement doubleValue]));
}
-(void) setTurningAngleIncrementAsDouble:(double)newAngle {
    self.turningAngleIncrement = @(newAngle);
}
-(void) setTurningAngleIncrementAsDegrees:(NSNumber*)newAngle {
    double inRadians = radians([newAngle doubleValue]);
    self.turningAngleIncrement = @(inRadians);
}
-(NSNumber*) baseAngleAsDegree {
    return @(degrees([self.baseAngle doubleValue]));
}
-(void) setBaseAngleAsDegrees:(NSNumber*)newAngle {
    double inRadians = radians([newAngle doubleValue]);
    self.baseAngle = @(inRadians);
}
-(NSArray*) newSortedReplacementRulesArray {
    NSSortDescriptor* sort = [[NSSortDescriptor alloc] initWithKey: @"contextString" ascending: YES];
    NSArray* descriptors = @[sort];
    NSArray* sortedRules = [self.replacementRules sortedArrayUsingDescriptors: descriptors];
    return sortedRules;
}
@end
