//
//  LSDrawingRuleType.m
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "LSDrawingRuleType.h"
#import "LSDrawingRule.h"
#import "LSFractal.h"


@interface LSDrawingRuleType ()
@property (nonatomic,readwrite,strong) NSArray*     rulesAsSortedArray;
@property (nonatomic,assign) BOOL                   rulesChanged;
@end

@implementation LSDrawingRuleType

@synthesize rulesAsSortedArray = _rulesAsSortedArray;

-(NSInteger)version
{
    return 1;
}
+(instancetype)newLSDrawingRuleTypeFromDefaultPListDictionary
{
    NSString* plistFileName = @"LSDrawingRulesDefaultTypeList";
    
    id plistObject = [plistFileName fromPListFileNameToObject];
    
    if (![plistObject isKindOfClass: [NSDictionary class]] || ([plistObject count] < 2))
    {
        NSLog(@"Error plistObject should be an dictionary with size > 1. is: %@", plistObject);
        return nil;
    }
    
    return [[self class] newLSDrawingRuleTypeFromPListDictionary: plistObject];
}

+(instancetype)newLSDrawingRuleTypeFromPListDictionary:(NSDictionary *)plistDict
{
    LSDrawingRuleType* newDrawingRuleType;
    
    NSDictionary* plistRuleType = plistDict[@"ruleType"];
    
    if (plistRuleType)
    {
        newDrawingRuleType = [LSDrawingRuleType new];
        for (id propertyKey in plistRuleType) {
            [newDrawingRuleType setValue: plistRuleType[propertyKey] forKey: propertyKey];
        }
        
        NSArray* plistRulesArray = plistDict[@"rulesArray"];
        
        NSInteger addRulesCount = [newDrawingRuleType loadRulesFromPListRulesArray: plistRulesArray];
        
        NSLog(@"Added %ld rules.", (long)addRulesCount);
    }
    return newDrawingRuleType;
}

-(NSInteger)loadRulesFromPListRulesArray: (NSArray*)rulesArray {
    NSInteger addedRulesCount = 0;
    
    if (rulesArray) {
        
        NSMutableDictionary* currentDefaultRules;
        if (self.rules) {
            currentDefaultRules = [self.rules mutableCopy];
        }
        else
        {
            currentDefaultRules = [[NSMutableDictionary alloc]initWithCapacity: rulesArray.count];
        }

        // COuld convert set to dictionary and ise a lookup to detect existence but not worth it for a few rules.
        
        //Sort rules before adding so orderedSet is created in desired order.
        //Will not work as desired if rules using same indexes already exist in LSDrawingRuleType.
        //        NSSortDescriptor* ruleIndexSorting = [NSSortDescriptor sortDescriptorWithKey: @"displayIndex" ascending: YES];
        //        NSSortDescriptor* ruleAlphaSorting = [NSSortDescriptor sortDescriptorWithKey: @"iconIdentifierString" ascending: YES];
        //        NSArray* sortedRules = [rulesArray sortedArrayUsingDescriptors: @[ruleIndexSorting,ruleAlphaSorting]];
        
        NSInteger ruleIndex = self.rules.count;
        
        for (NSDictionary* rule in rulesArray) {
            NSString* productionString = rule[@"productionString"];
            
            LSDrawingRule* existingRule = currentDefaultRules[productionString];
            
            if (!existingRule) {
                LSDrawingRule *newDrawingRule = [LSDrawingRule new];
                newDrawingRule.productionString = rule[@"productionString"];
                newDrawingRule.drawingMethodString = rule[@"drawingMethodString"];
                newDrawingRule.iconIdentifierString = rule[@"iconIdentifierString"];
                newDrawingRule.descriptor = rule[@"descriptor"];
                newDrawingRule.displayIndex = ruleIndex;
                [currentDefaultRules setObject: newDrawingRule forKey: productionString]; // this should also take care of relationship?
                addedRulesCount += 1;
            }
            ruleIndex++;
        }
        
        self.rules = currentDefaultRules;
    }
    return addedRulesCount;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _identifier = [aDecoder decodeObjectForKey: @"identifier"];
        _name = [aDecoder decodeObjectForKey: @"name"];
        _descriptor = [aDecoder decodeObjectForKey: @"descriptor"];
        _rules = [aDecoder decodeObjectForKey: @"rules"];
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject: self.identifier forKey: @"identifier"];
    [aCoder encodeObject: self.name forKey: @"name"];
    [aCoder encodeObject: self.descriptor forKey: @"descriptor"];
    [aCoder encodeObject: self.rules forKey: @"rules"];
}

-(LSDrawingRule*)ruleForIdentifierString: (NSString*)ruleIdentifierString
{
    LSDrawingRule* rule;
    
    NSString* key = [ruleIdentifierString substringWithRange: NSMakeRange(0, 1)];
    
    rule = [self.rules[key] copy];
    
    return rule;
}

-(NSArray*) rulesArrayFromRuleString: (NSString*) ruleString {
    NSInteger sourceLength = ruleString.length;
    
    NSDictionary* rulesDict = [self.rules copy];
    
    NSMutableArray* rulesArray = [[NSMutableArray alloc] initWithCapacity: sourceLength];
    
    for (int y=0; y < sourceLength; y++) {
        //
        NSString* key = [ruleString substringWithRange: NSMakeRange(y, 1)];
        
        LSDrawingRule* rule = rulesDict[key];
        
        if (rule) {
            [rulesArray addObject: [rule copy]];
        }
        
    }
    return [rulesArray copy];
}


-(void) setRules:(NSDictionary *)rules
{
    if (_rules != rules) {
        _rules = rules;
        self.rulesChanged = YES;
    }
}
-(NSArray*) rulesAsSortedArray
{
    if (_rulesAsSortedArray || self.rulesChanged)
    {
        NSArray* newArray = [self.rules allValues];
        _rulesAsSortedArray = [newArray sortedArrayUsingDescriptors: @[[LSDrawingRule sortDescriptor]]];
    }
    return _rulesAsSortedArray;
}
@end