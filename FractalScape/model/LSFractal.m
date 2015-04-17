//
//  LSFractal.m
//  FractalScape
//
//  Created by Taun Chapman on 02/05/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "LSFractal.h"
#import "LSDrawingRule.h"
#import "LSDrawingRuleType.h"
#import "LSReplacementRule.h"
#import "MBColor.h"
#import "MBImageFilter.h"

#import "NSString+MDBConvenience.h"

#include <math.h>

#define kLSMaxLevel0CacheSize 100
#define kLSMaxLevel1CacheSize 100
#define kLSMaxLevel2CacheSize 500
#define kLSMaxLevelNCacheSize 1000000
#define kLSLevelCacheIncrement 1000000

struct MBReplacementRulesStruct {
    char        replacementCString[kLSMaxRules][kLSMaxReplacementRules];
};
typedef struct MBReplacementRulesStruct MBReplacementRulesStruct;

@interface LSFractal ()

@property(nonatomic,strong,readonly) NSDictionary*       propertyRangesDictionary;
@property(nonatomic,assign,readwrite) BOOL      isRenderable;

+(NSDictionary*)propertyRangesDictionary;

@end


@implementation LSFractal

+(NSInteger)version
{
    return 1;
}

+(BOOL)automaticallyNotifiesObserversOfrulesUnchanged
{
    return NO;
}
+(BOOL)automaticallyNotifiesObserversOflevelUnchanged
{
    return NO;
}

+(NSString*) startingRulesKey
{
    static NSString*  startingRulesKeyString = @"startingRules";
    return startingRulesKeyString;
}
+(NSString*) replacementRulesKey
{
    static NSString*  replacementRulesKeyString = @"replacementRules";
    return replacementRulesKeyString;
}
+(NSString*) lineColorsKey
{
    static NSString*  fractalLineColorsString = @"lineColors";
    return fractalLineColorsString;
}
+(NSString*) fillColorsKey
{
    static NSString*  fractalFillColorsString = @"fillColors";
    return fractalFillColorsString;
}
+ (NSSet *)keysToBeCopied
{
    static NSSet *keysToBeCopied = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
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
                          @"name",
                          @"randomness",
                          @"backgroundColor",
                          @"autoExpand",
                          @"advancedMode",
                          @"applyFilters",
                          nil];
    });
    return keysToBeCopied;
}

+(NSSet*) labelProperties
{
    static NSSet* labelProperties = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        labelProperties = [[NSSet alloc] initWithObjects:
                           @"name",
                           @"descriptor",
                           nil];
    });
    return labelProperties;
}

+(NSSet*) productionRuleProperties
{
    static NSSet* productionRuleProperties = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        productionRuleProperties = [[NSSet alloc] initWithObjects:
                                    [LSFractal startingRulesKey],
                                    [LSFractal replacementRulesKey],
                                    @"level",
                                    nil];
    });
    return productionRuleProperties;
}

+(NSSet*) appearanceProperties
{
    static NSSet* appearanceProperties = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
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
                                @"advancedMode",
                                nil];
    });
    return appearanceProperties;
}

+(NSSet*) redrawProperties
{
    static NSSet* redrawProperties = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        redrawProperties = [[NSSet alloc] initWithObjects:
                            @"eoFill",
                            @"lineColors",
                            @"fillColors",
                            @"backgroundColor",
                            @"autoExpand",
                            @"applyFilters",
                            nil];
    });
    return redrawProperties;
}

+(NSDictionary*) propertyRangesDictionary
{
    static NSDictionary* propertyRangesDictionary = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
    propertyRangesDictionary = @{@"randomness": @{@"min":@0.0, @"max":@1.0},
                                 @"baseAngle": @{@"min":@(-180.0), @"max":@(180.0)},
                                 @"turningAngle": @{@"min":@(0.0), @"max":@(180.0)},
                                 @"turningAngleIncrement": @{@"min":@0.0, @"max":@1.0},
                                 @"lineWidth": @{@"min":@0.5, @"max":@60.0},
                                 @"lineChangeFactor": @{@"min":@0.0, @"max":@1.0}
                                 };
    });
    
    return propertyRangesDictionary;
}

+(instancetype)newLSFractalFromPListDictionary:(NSDictionary *)fractalDictionary
{
    LSFractal* fractal;
    if ([fractalDictionary isKindOfClass: [NSDictionary class]])
    {
        // create the fractal
        
        // only create new fractal if one with identifier doesn't already exist
        fractal = [[self class] new];
        fractal.name = fractalDictionary[@"name"];
        
        // handle special cases
        NSMutableDictionary* mutableFractalDictionary = [fractalDictionary mutableCopy];
        
        NSArray* startingRulesArray = mutableFractalDictionary[[LSFractal startingRulesKey]];
        if (startingRulesArray != nil)
        {
            fractal.startingRules = [self newCollectionOfLSDrawingRulesFromPListArray: startingRulesArray];
            [mutableFractalDictionary removeObjectForKey: [LSFractal startingRulesKey]];
        }
        
        NSArray* replacementRulesArray = mutableFractalDictionary[[LSFractal replacementRulesKey]];
        if (replacementRulesArray && replacementRulesArray.count > 0)
        {
            fractal.replacementRules = [self newCollectionOfLSReplacementRulesFromPListArray: replacementRulesArray];
            [mutableFractalDictionary removeObjectForKey: [LSFractal replacementRulesKey]];
        }
        
        NSArray* lineColorsArray = mutableFractalDictionary[[LSFractal lineColorsKey]];
        if (lineColorsArray && lineColorsArray.count > 0)
        {
            fractal.lineColors = [self newCollectionOfMBColorsFromPListArray: lineColorsArray];
            [mutableFractalDictionary removeObjectForKey: [LSFractal lineColorsKey]];
        }
        
        NSArray* fillColorsArray = mutableFractalDictionary[[LSFractal fillColorsKey]];
        if (fillColorsArray && fillColorsArray.count > 0)
        {
            fractal.fillColors = [self newCollectionOfMBColorsFromPListArray: fillColorsArray];
            [mutableFractalDictionary removeObjectForKey: [LSFractal fillColorsKey]];
        }
        
        for (id propertyKey in mutableFractalDictionary)
        {
            id propertyValue = mutableFractalDictionary[propertyKey];
            // all but dictionaries should be key value
            [fractal setValue: propertyValue forKey: propertyKey];
        }
        
    }
    return fractal;
}
+(NSMutableArray*) newCollectionOfLSReplacementRulesFromPListArray: (NSArray*) plistArray
{
    NSMutableArray* replacementRules = [NSMutableArray new];
    
    for (NSDictionary* rRuleDict in plistArray) {
        //
        LSReplacementRule* newReplacementRule = [LSReplacementRule newLSReplacementRuleFromPListDictionary: rRuleDict];
        [replacementRules addObject: newReplacementRule];
    }
    return replacementRules;
}

+(MDBFractalObjectList*) newCollectionOfLSDrawingRulesFromPListArray: (NSArray*) plistArray
{
    MDBFractalObjectList* rulesArray = [MDBFractalObjectList new];
    for (NSDictionary* ruleDict in plistArray) {
        LSDrawingRule* newRule = [LSDrawingRule newLSDrawingRuleFromPListDictionary: ruleDict];
        [rulesArray addObject: newRule];
    }
    return rulesArray;
}

+(MDBFractalObjectList*) newCollectionOfMBColorsFromPListArray: (NSArray*) plistArray
{
    MDBFractalObjectList* mutableColors = [MDBFractalObjectList new];
    
    NSInteger colorIndex = 0;
    
    for (NSDictionary* colorDict in plistArray)
    {
        MBColor* newColor = [MBColor newMBColorFromPListDictionary: colorDict];
        // the order of colors in the PList array is the index order
        // if you want to change the color order, change it in the PList.
        newColor.index = colorIndex;
        colorIndex++;
        [mutableColors addObject: newColor];
    }
    return mutableColors;
}

-(CGFloat)minValueForProperty:(NSString *)propertyKey
{
    CGFloat value = 0.0;
    
    NSDictionary* propertyRange = [[self class] propertyRangesDictionary][propertyKey];
    if (propertyRange) {
        value = [propertyRange[@"min"] floatValue];
    }
    return value;
}
-(CGFloat)maxValueForProperty:(NSString *)propertyKey
{
    CGFloat value = MAXFLOAT;
    
    NSDictionary* propertyRange = [[self class] propertyRangesDictionary][propertyKey];
    if (propertyRange) {
        value = [propertyRange[@"max"] floatValue];
    }
    return value;
}

#pragma mark - Initialization
#pragma message "TODO have applyFilters depend on whether the imageFilters.isEmpty removing logic from the editor"
- (instancetype)init
{
    self = [super init];
    if (self) {
        _name = @"New Fractal";
        _descriptor = @"...";
        _level = 2;
        _baseAngle = 0.0;
        _lineLength = 10.0;
        _lineWidth = 2.0;
        _lineChangeFactor = 0.0;
        _turningAngle = 0.0;
        _turningAngleIncrement = 0.0;
        _randomness = 0.0;
        _applyFilters = NO;
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        
        int version = (int)[aDecoder decodeIntegerForKey: @"version"];
        
        switch (version) {
            case 1:
                [self decodeVersion1WithCoder: aDecoder];
                break;
                
            default:
                NSLog(@"Error: Wrong version. is: %i; should be: 1", version);
                break;
        }
        
    }
//    NSLog(@"Loaded Fractal: %@",self.name);
    return self;
}

- (id) debugQuickLookObject
{
    return [self debugDescription];
}

-(NSString*)debugDescription
{
//    NSString* ddesc = [NSString stringWithFormat: @"Name: %@\nDescription: %@\nLevels: %lu\nStarting Rules: %@\nReplacement Rules: %@",_name,_descriptor,_level,[self startingRulesAsString],[self replacementRulesAsPListArray]];
    NSString* ddesc = [NSString stringWithFormat: @"%@",[self asPListDictionary]];
    return ddesc;
}
-(void) decodeVersion1WithCoder: (NSCoder*)aDecoder
{
    for ( NSString* aKey in [[self class] keysToBeCopied]) {
        id object = [aDecoder decodeObjectForKey: aKey];
        if (object) {
            [self setValue: object forKey: aKey];
        }
    }
    _startingRules = [aDecoder decodeObjectForKey: @"startingRules"];
    _replacementRules = [aDecoder decodeObjectForKey: @"replacementRules"];
    _lineColors = [aDecoder decodeObjectForKey: @"lineColors"];
    _fillColors = [aDecoder decodeObjectForKey: @"fillColors"];
    _imageFilters = [aDecoder decodeObjectForKey: @"imageFilters"];
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    for ( NSString* aKey in [[self class] keysToBeCopied]) {
        id propertyValue = [self valueForKey: aKey];
        if (propertyValue) {
            [aCoder encodeObject: propertyValue forKey: aKey];
        }
    }
    [aCoder encodeInteger: [[self class]version] forKey: @"version"];
    [aCoder encodeObject: self.startingRules forKey: @"startingRules"];
    [aCoder encodeObject: self.replacementRules forKey: @"replacementRules"];
    [aCoder encodeObject: self.lineColors forKey: @"lineColors"];
    [aCoder encodeObject: self.fillColors forKey: @"fillColors"];
    [aCoder encodeObject: self.imageFilters forKey: @"imageFilters"];
}

/*!
 Want all of the rules and colors to be copies without reference to the original fractal.
 
 @return a new fractal.
 */
-(id) copyWithZone:(NSZone *)zone
{
    LSFractal *fractalCopy = [[[self class] allocWithZone: zone] init];
    
    if (fractalCopy) {
        for ( NSString* aKey in [LSFractal keysToBeCopied])
        {
            id object = [self valueForKey: aKey];
            if (object)
            {
                [fractalCopy setValue: object forKey: aKey];
            }
        }
        
        fractalCopy.startingRules = [_startingRules copy];
        
        // deep copy, just copying the array creates references to the same rule object. We want unique rule objects?
        NSMutableArray* replacementRules = [NSMutableArray arrayWithCapacity: self.replacementRules.count];
        for (LSReplacementRule* rule in self.replacementRules) {
            [replacementRules addObject: [rule copy]];
        }
        fractalCopy.replacementRules = replacementRules;
        
        fractalCopy.lineColors = [_lineColors copy];
        
        fractalCopy.fillColors = [_fillColors copy];

        fractalCopy.imageFilters = [_imageFilters copy];

        NSString* oldName = self.name;
        NSString* newName = [NSString mdbStringByAppendingOrIncrementingCount: oldName];
        fractalCopy.name = newName;
        fractalCopy.isImmutable = NO;
        fractalCopy.isReadOnly = NO;
    }
    return fractalCopy;
}

-(BOOL)isRenderable
{
    BOOL renderable = YES;
    
    if (!_startingRules) return NO;
    
    if (_startingRules.count == 0) return NO;
    
    if ([(LSDrawingRule*)[_startingRules firstObject] isDefaultObject]) return NO;
    
    
    return renderable;
}

#pragma mark - Lazy Getter/Setters

-(MDBFractalObjectList*)startingRules
{
    if (!_startingRules) {
        _startingRules = [MDBFractalObjectList new];
        [_startingRules addObject: [LSDrawingRule new]];
    }
    return _startingRules;
}

-(NSMutableArray*)replacementRules
{
    if (!_replacementRules) {
        _replacementRules = [NSMutableArray new];
        [_replacementRules addObject: [LSReplacementRule new]];
    }
    return _replacementRules;
}

-(MBColor*)backgroundColor
{
    if (!_backgroundColor) {
        _backgroundColor = [MBColor newMBColorWithUIColor: [UIColor clearColor]];
    }
    return _backgroundColor;
}
-(MDBFractalObjectList*)lineColors
{
    if (!_lineColors) {
        _lineColors = [MDBFractalObjectList new];
        [_lineColors addObject: [MBColor new]];
    }
    return _lineColors;
}

-(MDBFractalObjectList*)fillColors
{
    if (!_fillColors) {
        _fillColors = [MDBFractalObjectList new];
        [_fillColors addObject: [MBColor new]];
    }
    return _fillColors;
}

-(MDBFractalObjectList*)imageFilters
{
    if (!_imageFilters) {
        _imageFilters = [MDBFractalObjectList new];
        [_imageFilters addObject: [MBImageFilter new]];
    }
    return _imageFilters;
}

- (void)setLevel:(NSInteger)newLevel {
    
    [self willChangeValueForKey:@"level"];
    _level = newLevel;
    self.levelUnchanged = NO;
    [self didChangeValueForKey:@"level"];
}

#pragma mark - Property Transforms

-(NSString*) startingRulesAsString {
    NSMutableString* rulesString = [[NSMutableString alloc]initWithCapacity: self.startingRules.count];
    for (LSDrawingRule* rule in self.startingRules) {
        [rulesString appendString: rule.productionString];
    }
    return rulesString;
}


-(NSArray*)startingRulesAsPListArray
{
    return [self arrayOfPlistedObjectsFromCollection: self.startingRules];
}

-(NSArray*)replacementRulesAsPListArray
{
    return [self arrayOfPlistedObjectsFromCollection: self.replacementRules];
}

-(NSArray*)lineColorAsPListArray
{
    return [self arrayOfPlistedObjectsFromCollection: self.lineColors];
}
-(NSArray*)fillColorAsPListArray
{
    return [self arrayOfPlistedObjectsFromCollection: self.fillColors];
}

-(NSArray*)arrayOfPlistedObjectsFromCollection: (id)aCollection
{
    NSMutableArray* plistObjects;
    
    if ([aCollection count] > 0)
    {
        plistObjects = [NSMutableArray new];
        
        for (id object in aCollection) {
            id newPlist = [object asPListDictionary];
            if (newPlist) {
                [plistObjects addObject: newPlist];
            }
        }
    }
    
    return plistObjects;
}

-(NSDictionary*)asPListDictionary
{
    NSMutableDictionary* fractalDict = [NSMutableDictionary new];
    
    for (NSString* key in [LSFractal keysToBeCopied])
    {
        id object = [self valueForKey: key];
        if (object)
        {
            [fractalDict setObject: object forKey: key];
        }
    }
    NSArray* newPlist;
    if ((newPlist = self.startingRulesAsPListArray)) {
        fractalDict[[LSFractal startingRulesKey]] = newPlist;
    }
    if ((newPlist = self.replacementRulesAsPListArray)) {
        fractalDict[[LSFractal replacementRulesKey]] = newPlist;
    }
    if ((newPlist = self.lineColorAsPListArray)) {
        fractalDict[[LSFractal lineColorsKey]] = newPlist;
    }
    if ((newPlist = self.fillColorAsPListArray)) {
        fractalDict[[LSFractal fillColorsKey]] = newPlist;
    }
    
    return fractalDict;
}

-(NSDictionary*) replacementRulesDictionary {
    NSMutableDictionary* tempDictionary = [[NSMutableDictionary alloc] initWithCapacity: self.replacementRules.count];
    NSMutableArray* replacementRules =  self.replacementRules;
    for (LSReplacementRule* replacementRule in replacementRules) {
        [tempDictionary setObject: replacementRule forKey: replacementRule.contextRule.productionString];
    }
    return [tempDictionary copy];
}
-(void) generateLevelData {
    if (!(self.levelUnchanged && self.rulesUnchanged)) {
        [self cacheLevelNRulesStrings];
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
    
    NSInteger levelN = self.level;
    
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

#pragma message "TODO add set of placeholder rules and remove them before returning the NSData. Saves time during rendering evaluation."
-(void) cacheLevelNRulesStrings {
    // if level or rules changed, reproduce cache
    if (!(self.levelUnchanged && self.rulesUnchanged)) {
        
        NSMutableData* level1RulesCache = [NSMutableData dataWithCapacity: 100];
        NSMutableData* level2RulesCache = [NSMutableData dataWithCapacity: kLSMaxLevel2CacheSize];
        NSMutableData* levelNRulesCache = [NSMutableData dataWithCapacity: kLSMaxLevelNCacheSize];
        
        MBReplacementRulesStruct replacementRulesCache;
        for (int i =0; i < kLSMaxRules; i++) {
            replacementRulesCache.replacementCString[i][0] = 0;
        }
        
        NSMutableData* destinationData = [NSMutableData dataWithLength: levelNRulesCache.length];
        
        CGFloat localLevel;
        
        localLevel = (CGFloat)self.level;
        localLevel = localLevel < 2.0 ? 2.0 : localLevel;
        
        self.level0RulesCache = [self.startingRulesAsString dataUsingEncoding: NSUTF8StringEncoding];
        
        
        // Create a local dictionary version of the replacement rules
        for (LSReplacementRule* replacementRule in self.replacementRules) {
            const char* ruleBytes = replacementRule.contextRule.productionString.UTF8String;
            
            const char* replacementCString = replacementRule.rulesString.UTF8String;
            
            if (ruleBytes != NULL && replacementCString != NULL && strlen(replacementCString) > 0) {
                strcpy(replacementRulesCache.replacementCString[ruleBytes[0]], replacementCString);
            }
        }
        
        [self generateNextLevelWithSource: self.level0RulesCache destination: level1RulesCache replacementsCache: replacementRulesCache];
        self.level1RulesCache = level1RulesCache;
        
        [self generateNextLevelWithSource: level1RulesCache destination: level2RulesCache replacementsCache: replacementRulesCache];
        self.level2RulesCache = level2RulesCache;
        
        // initialise buffer
        levelNRulesCache.length = 0;
        [levelNRulesCache appendBytes: level2RulesCache.bytes length: level2RulesCache.length];
        
        CGFloat growthRate = 0.0;
        
        for (unsigned long i = 2; i < localLevel ; i++) {
            [self generateNextLevelWithSource: levelNRulesCache destination: destinationData replacementsCache: replacementRulesCache];
            // swap buffers before next interation
            growthRate = (CGFloat)destinationData.length / (CGFloat)levelNRulesCache.length;
            
            NSMutableData* newDestination = levelNRulesCache;
            levelNRulesCache = destinationData;
            destinationData = newDestination;
        }
        
        self.levelNRulesCache = levelNRulesCache;
        self.levelGrowthRate = growthRate;
        
        
        destinationData = nil;
        self.levelUnchanged = YES;
        self.rulesUnchanged = YES;
    }
}

-(void) generateNextLevelWithSource: (NSData*) sourceData destination: (NSMutableData*) destinationData replacementsCache: (MBReplacementRulesStruct) replacementRulesStruct {
    
    char* sourceBytes = (char*)sourceData.bytes;
    destinationData.length = 0;
    
    for (long i=0; i < sourceData.length; i++) {
        UInt8 rule = sourceBytes[i];
        
        if (rule > 250) {
            break;
        }
        
        if (i < kLSMaxLevelNCacheSize-1) {
            
            char interCString[kLSMaxReplacementRules];
            
            strcpy(interCString, replacementRulesStruct.replacementCString[rule]);
            if (strlen(interCString) == 0) {
                interCString[0] = rule;
                interCString[1] = 0;
            }
            
            [destinationData appendBytes: interCString length: strlen(interCString)]; // don't include null terminator
        }
    }
    //    UInt8 terminator[1] = "";
    //    [destinationData appendBytes: terminator length: 1];
}

@end