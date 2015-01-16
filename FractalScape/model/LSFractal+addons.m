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

#define kLSMaxLevel0CacheSize 100
#define kLSMaxLevel1CacheSize 100
#define kLSMaxLevel2CacheSize 500
#define kLSMaxLevelNCacheSize 1000000
#define kLSLevelCacheIncrement 1000000

struct MBReplacementRulesStruct {
    char        replacementString[kLSMaxRules][kLSMaxReplacementRules];
};
typedef struct MBReplacementRulesStruct MBReplacementRulesStruct;


@implementation LSFractal (addons)

+ (NSString *)entityName {
    return @"LSFractal";
}
+(NSString*) startingRulesKey {
    static NSString*  startingRulesKeyString = @"startingRules";
    return startingRulesKeyString;
}
+(NSString*) replacementRulesKey {
    static NSString*  replacementRulesKeyString = @"replacementRules";
    return replacementRulesKeyString;
}
+(NSString*) lineColorsKey {
    static NSString*  fractalLineColorsString = @"lineColors";
    return fractalLineColorsString;
}
+(NSString*) fillColorsKey {
    static NSString*  fractalFillColorsString = @"fillColors";
    return fractalFillColorsString;
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
                          @"eoFill",
                          @"isImmutable",
                          @"isReadOnly",
                          @"level",
                          @"lineLength",
                          @"lineLengthScaleFactor",
                          @"lineWidth",
                          @"lineWidthIncrement",
                          @"lineChangeFactor",
                          @"turningAngle",
                          @"turningAngleIncrement",
                          @"baseAngle",
                          @"drawingRulesType",
                          @"name",
                          @"randomness",
                          @"backgroundColor",
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
                                    [LSFractal startingRulesKey],
                                    [LSFractal replacementRulesKey],
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
                                @"lineLengthScale",
                                @"lineWidth",
                                @"lineWidthIncrement",
                                @"lineChangeFactor",
                                @"turningAngle",
                                @"turningAngleIncrement",
                                @"baseAngle",
                                @"randomness",
                                nil];
    }
    return appearanceProperties;
}

+(NSSet*) redrawProperties {
    static NSSet* redrawProperties = nil;
    if (redrawProperties == nil) {
        redrawProperties = [[NSSet alloc] initWithObjects:
                            @"eoFill",
                            @"lineColors",
                            @"fillColors",
                            @"backgroundColor",
                                nil];
    }
    return redrawProperties;
}


-(id) mutableCopy {
    LSFractal *fractalCopy = (LSFractal*)[LSFractal insertNewObjectIntoContext: self.managedObjectContext];
    
    if (fractalCopy) {
        for ( NSString* aKey in [LSFractal keysToBeCopied]) {
            id value = [self valueForKey: aKey];
            [fractalCopy setValue: value forKey: aKey];
        }
        
        NSMutableOrderedSet* startingRules = [fractalCopy mutableOrderedSetValueForKey: [LSFractal startingRulesKey]];
        for (LSDrawingRule* rule in self.startingRules) {
            [startingRules addObject: [rule mutableCopy]];
        }
                
        NSMutableOrderedSet* replacementRules = [fractalCopy mutableOrderedSetValueForKey: [LSFractal replacementRulesKey]];
        for (LSReplacementRule* rule in self.replacementRules) {
            [replacementRules addObject: [rule mutableCopy]];
        }
        
        NSMutableOrderedSet* lineColorsMutableSet = [fractalCopy mutableOrderedSetValueForKey: [LSFractal lineColorsKey]];
        for (MBColor* object in self.lineColors) {
            [lineColorsMutableSet addObject: [object mutableCopy]];
        }
        
        NSMutableOrderedSet* fillColorsMutableSet = [fractalCopy mutableOrderedSetValueForKey: [LSFractal fillColorsKey]];
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

- (void)setLevel:(NSNumber*)newLevel {
    [self willChangeValueForKey:@"level"];
    [self setPrimitiveValue: newLevel forKey: @"level"];
    self.levelUnchanged = NO;
    [self didChangeValueForKey:@"level"];
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
-(NSNumber*) turningAngleAsDegrees {
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
-(NSNumber*) turningAngleIncrementAsDegrees {
    return @(degrees([self.turningAngleIncrement doubleValue]));
}
-(void) setTurningAngleIncrementAsDouble:(double)newAngle {
    self.turningAngleIncrement = @(newAngle);
}
-(void) setTurningAngleIncrementAsDegrees:(NSNumber*)newAngle {
    double inRadians = radians([newAngle doubleValue]);
    self.turningAngleIncrement = @(inRadians);
}
-(NSNumber*) baseAngleAsDegrees {
    return @(degrees([self.baseAngle doubleValue]));
}
-(void) setBaseAngleAsDegrees:(NSNumber*)newAngle {
    double inRadians = radians([newAngle doubleValue]);
    self.baseAngle = @(inRadians);
}
-(NSDictionary*) replacementRulesDictionary {
    NSMutableDictionary* tempDictionary = [[NSMutableDictionary alloc] initWithCapacity: self.replacementRules.count];
    NSOrderedSet* replacementRules =  self.replacementRules;
    for (LSReplacementRule* replacementRule in replacementRules) {
        [tempDictionary setObject: replacementRule forKey: replacementRule.contextRule.productionString];
    }
    return [tempDictionary copy];
}
-(void) recurseRules: (NSOrderedSet*)rules replacementRules: (NSDictionary*)replacementRulesDict currentLevel: (NSUInteger)currentLevel desiredLevel: (NSUInteger) desiredLevel ruleArray: (NSPointerArray*)leafRulesArray leafRuleIndex: (NSUInteger*) leafIndexPtr {
    for (LSDrawingRule* rule in rules) {
        LSReplacementRule* replacementRule = replacementRulesDict[rule.productionString];
        if (currentLevel == desiredLevel || !replacementRule) {
            // if we are at the right level OR there is NO replacement rule, add the leaf
            NSUInteger arraySize = leafRulesArray.count;
            if (*leafIndexPtr+1 >= arraySize) {
                NSUInteger newArraySize = arraySize + kLSLevelCacheIncrement;
                [leafRulesArray setCount: newArraySize];
            }
            [leafRulesArray replacePointerAtIndex: (*leafIndexPtr)++ withPointer: (__bridge void *)(rule.drawingMethodString)];
        } else if (currentLevel < desiredLevel && replacementRule) {
            // if we are not at the right level AND there IS a replacement rule, recurse
            [self recurseRules: replacementRule.rules replacementRules: replacementRulesDict currentLevel: currentLevel+1 desiredLevel: desiredLevel ruleArray: leafRulesArray leafRuleIndex: leafIndexPtr];
        }
    }
}

-(NSData*) level0Rules {
    if (!(self.levelUnchanged && self.rulesUnchanged)) {
        [self cacheLevelNRulesStrings];
    }
    
    return self.level0RulesCache;
}
-(NSData*) level1Rules {
    if (!(self.levelUnchanged && self.rulesUnchanged)) {
        [self cacheLevelNRulesStrings];
    }
    
    return self.level1RulesCache;
}
-(NSData*) level2Rules {
    if (!(self.levelUnchanged && self.rulesUnchanged)) {
        [self cacheLevelNRulesStrings];
    }
    
    return self.level2RulesCache;
}
-(NSData*) levelNRules {
    if (!(self.levelUnchanged && self.rulesUnchanged)) {
            //
        [self cacheLevelNRulesStrings];
    }
    
    NSUInteger levelN = [self.level unsignedIntegerValue];
    
    if (levelN == 0) {
        return self.level0RulesCache;
    } else if (levelN == 1) {
        return self.level1RulesCache;
    } else if (levelN == 2) {
        return self.level2RulesCache;
    } else {
        return self.levelNRulesCache;
    }
}
-(void) initialiseRuleCaches {
    if (!self.level1RulesCache) {
        self.level1RulesCache = [NSMutableData dataWithCapacity: 100];
    } else {
        self.level1RulesCache.length = 0;
    }
    if (!self.level2RulesCache) {
        self.level2RulesCache = [NSMutableData dataWithCapacity: kLSMaxLevel2CacheSize];
    } else {
        self.level2RulesCache.length = 0;
    }

    if (!self.levelNRulesCache) {
        self.levelNRulesCache = [NSMutableData dataWithCapacity: kLSMaxLevelNCacheSize];
    } else {
        self.levelNRulesCache.length = 0;
    }


}
-(void) cacheLevelNRulesStrings {
    //estimate the length
    if (!(self.levelUnchanged && self.rulesUnchanged)) {
        
        [self initialiseRuleCaches];
        MBReplacementRulesStruct replacementRulesCache;
        for (int i =0; i < kLSMaxRules; i++) {
            replacementRulesCache.replacementString[i][0] = 0;
        }
        
        NSMutableData* destinationData = [NSMutableData dataWithLength: self.levelNRulesCache.length];
        
        CGFloat localLevel;
        
        localLevel = [self.level floatValue];
        localLevel = localLevel < 2 ? 2 : localLevel;
        
        self.level0RulesCache = [self.startingRulesString dataUsingEncoding: NSUTF8StringEncoding];
        
        
        // Create a local dictionary version of the replacement rules
        for (LSReplacementRule* replacementRule in self.replacementRules) {
            NSData* ruleData = [replacementRule.contextRule.productionString dataUsingEncoding: NSUTF8StringEncoding];
            char* ruleBytes = (char*)ruleData.bytes;
            NSData* replacementData = [replacementRule.rulesString dataUsingEncoding: NSUTF8StringEncoding];
            char* replacementCString = (char*)replacementData.bytes;
            strncpy(replacementRulesCache.replacementString[ruleBytes[0]], replacementCString, replacementData.length);
            replacementRulesCache.replacementString[ruleBytes[0]][replacementData.length] = 0;
        }

        [self generateNextLevelWithSource: self.level0RulesCache destination: self.level1RulesCache replacementsCache: replacementRulesCache];
        [self generateNextLevelWithSource: self.level1RulesCache destination: self.level2RulesCache replacementsCache: replacementRulesCache];
        
        // initialise buffer
        [self.levelNRulesCache appendBytes: self.level2RulesCache.bytes length: self.level2RulesCache.length];
        
        for (int i = 2; i < localLevel ; i++) {
            [self generateNextLevelWithSource: self.levelNRulesCache destination: destinationData replacementsCache: replacementRulesCache];
            // swap buffers before next interation
            NSMutableData* newDestination = self.levelNRulesCache;
            self.levelNRulesCache = destinationData;
            destinationData = newDestination;
            destinationData.length = 0;
        }
        
        
        destinationData = nil;
        
        self.levelUnchanged = YES;
        self.rulesUnchanged = YES;
    }
}

-(void) generateNextLevelWithSource: (NSData*) sourceData destination: (NSMutableData*) destinationData replacementsCache: (MBReplacementRulesStruct) replacementRulesStruct {
    
    char* sourceBytes = (char*)sourceData.bytes;
    
    for (long i=0; i < sourceData.length; i++) {
        UInt8 rule = sourceBytes[i];

        if (rule > 250) {
            break;
        }
        
        if (i < kLSMaxLevelNCacheSize-1) {
            
            char interString[kLSMaxReplacementRules];
            
            strcpy(interString, replacementRulesStruct.replacementString[rule]);
            if (strlen(interString) == 0) {
                interString[0] = rule;
                interString[1] = 0;
            }
            
            [destinationData appendBytes: interString length: strlen(interString)];
        }
    }
//    UInt8 terminator[1] = "";
//    [destinationData appendBytes: terminator length: 1];
}

@end
