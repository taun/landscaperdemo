//
//  LSFractal+addons.m
//  FractalScape
//
//  Created by Taun Chapman on 02/01/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "LSFractal+addons.h"
#import "LSReplacementRule+addons.h"
#import "LSDrawingRuleType+addons.h"
#import "LSDrawingRule+addons.h"
#import "MBColor+addons.h"
#import "NSManagedObject+Shortcuts.h"

@implementation LSFractal (addons)

+ (NSString *)entityName {
    return @"LSFractal";
}

+(NSArray*) allFractalsInContext: (NSManagedObjectContext *)context {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [LSFractal entityDescriptionForContext: context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    return fetchedObjects;
}
+(LSFractal*) findFractalWithName:(NSString *)fractalName inContext: (NSManagedObjectContext*) context{

    LSFractal* node = nil;
    
    NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    
    NSDictionary *substitutionDictionary =
    [NSDictionary dictionaryWithObjectsAndKeys: fractalName, @"LSFRACTALNAME", nil];
    
    NSFetchRequest *fetchRequest =
    [model fetchRequestFromTemplateWithName:@"LSFractalWithName"
                      substitutionVariables:substitutionDictionary];
    
    NSArray *fetchedObjects;
    fetchedObjects = [context executeFetchRequest:fetchRequest error: nil];
    
    // ToDo deal with error
    // There should always be only one. Don't know what error to post if > 1
    if ( ([fetchedObjects count] >= 1) ) {
        node = [fetchedObjects objectAtIndex: 0];
    }
    
    return node;
}

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSSet alloc] initWithObjects:
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
                          @"lineJoin",
                          @"lineCap",
                          @"name",
                          @"randomness",
                          nil];
    }
    return keysToBeCopied;
}

+(NSSet*) labelProperties {
    static NSSet* labelProperties = nil;
    if (labelProperties == nil) {
        labelProperties = [[NSSet alloc] initWithObjects:
                                    @"name",
                                    @"descriptor", 
                                    nil];
    }
    return labelProperties;
}

+(NSSet*) productionRuleProperties {
    static NSSet* productionRuleProperties = nil;
    if (productionRuleProperties == nil) {
        productionRuleProperties = [[NSSet alloc] initWithObjects:
                                    @"startingRules",
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
                                @"lineColors",
                                @"lineJoin",
                                @"lineCap",
                                @"stroke",
                                @"fill",
                                @"eoFill",
                                @"fillColors",
                                @"turningAngle",
                                @"baseAngle",
                                @"randomness",
                                nil];
    }
    return appearanceProperties;
}


-(id) mutableCopy {
    LSFractal *fractalCopy = (LSFractal*)[LSFractal insertNewObjectIntoContext: self.managedObjectContext];
    
    if (fractalCopy) {
        for ( NSString* aKey in [LSFractal keysToBeCopied]) {
            id value = [self valueForKey: aKey];
            [fractalCopy setValue: value forKey: aKey];
        }
        
        NSMutableOrderedSet* startingRules = [fractalCopy mutableOrderedSetValueForKey: @"startingRules"];
        for (LSDrawingRule* rule in self.startingRules) {
            [startingRules addObject: [rule mutableCopy]];
        }
                
        NSMutableOrderedSet* replacementRules = [fractalCopy mutableOrderedSetValueForKey: @"replacementRules"];
        for (LSReplacementRule* rule in self.replacementRules) {
            [replacementRules addObject: [rule mutableCopy]];
        }
        
        NSMutableSet* lineColorsMutableSet = [fractalCopy mutableSetValueForKey: @"lineColors"];
        for (MBColor* object in self.lineColors) {
            [lineColorsMutableSet addObject: [object mutableCopy]];
        }
        
        NSMutableSet* fillColorsMutableSet = [fractalCopy mutableSetValueForKey: @"fillColors"];
        for (MBColor* object in self.fillColors) {
            [fillColorsMutableSet addObject: [object mutableCopy]];
        }
       
        
#pragma message "TODO: turn following code into generic NSString number append category"
        NSString* oldName = [self valueForKey: @"name"];
        NSArray* substrings = [oldName componentsSeparatedByString: @" "];
        NSString* lastComponent = [substrings lastObject];
        NSInteger lastCopyInteger = [lastComponent integerValue]; // 0 if not a number so never use 0
        NSMutableArray* newComponents = [substrings mutableCopy];
        if (!lastCopyInteger) {
            // equal 0 so last compoenent was not a number
            [newComponents addObject: @" 1"];
        } else {
            //increment
            [newComponents removeLastObject];
            NSString* newCopyNumber = [NSString stringWithFormat: @" %ld", (long)++lastCopyInteger];
            [newComponents addObject: newCopyNumber];
        }
    
        NSString* newName = [newComponents componentsJoinedByString: @" "];
        [fractalCopy setValue: newName forKey: @"name"];
        [fractalCopy setValue: @NO forKey: @"isImmutable"];
        [fractalCopy setValue: @NO forKey: @"isReadOnly"];
    }
    return fractalCopy;
}

-(NSArray*)allCategories {
    NSString* fetchPropertyName = @"category";
    
    NSEntityDescription *entity = [LSFractal entityDescriptionForContext: self.managedObjectContext];

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity: entity];
    [request setResultType:NSDictionaryResultType];
    [request setReturnsDistinctResults:YES];
    [request setPropertiesToFetch:@[fetchPropertyName]];
    
    // Execute the fetch.
    NSError *error;
    NSArray *objects = [self.managedObjectContext executeFetchRequest: request error: &error];
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity: objects.count];
    if (objects == nil) {
        // Handle the error.
    } else if(objects.count > 0) {
        for (NSDictionary* categoryDict in objects) {
            NSString* categoryString = categoryDict[fetchPropertyName];
            [categories addObject: categoryString];
        }
        [categories sortUsingSelector: @selector(caseInsensitiveCompare:)];
    }
    return [categories copy];
}

-(NSString*) startingRulesString {
    NSMutableString* rulesString = [[NSMutableString alloc]initWithCapacity: self.startingRules.count];
    for (LSDrawingRule* rule in self.startingRules) {
        [rulesString appendString: rule.productionString];
    }
    return rulesString;
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

@end
