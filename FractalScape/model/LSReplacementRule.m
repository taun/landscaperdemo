//
//  LSReplacementRule.m
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "LSReplacementRule.h"
#import "LSDrawingRule.h"
#import "LSFractal.h"
#import "MDBFractalObjectList.h"

@implementation LSReplacementRule

+(NSString*) rulesKey {
    static NSString* rulesKeyString = @"rules";
    return rulesKeyString;
}
+(NSString*) contextRuleKey {
    static NSString* contextRuleKeyString = @"contextRule";
    return contextRuleKeyString;
}
+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          [[self class] contextRuleKey],
                          nil];
    }
    return keysToBeCopied;
}

+(instancetype)newLSReplacementRuleFromPListDictionary:(NSDictionary *)rRuleDict
{
    LSReplacementRule* newObject = [[self class] new];
    
    NSDictionary* contextRuleDict = rRuleDict[[LSReplacementRule contextRuleKey]];
    if (contextRuleDict)
    {
        LSDrawingRule* contextRule = [LSDrawingRule newLSDrawingRuleFromPListDictionary: contextRuleDict];
        newObject.contextRule = contextRule;
        
        if (contextRule)
        {
            NSArray* rulesArray = rRuleDict[[LSReplacementRule rulesKey]];
            if (rulesArray)
            {
                NSMutableArray* newRules = [NSMutableArray new];
                for (NSDictionary*ruleDict in rulesArray)
                {
                    LSDrawingRule* rule = [LSDrawingRule newLSDrawingRuleFromPListDictionary: ruleDict];
                    if (rule) {
                        [newRules addObject: rule];
                    }
                }
                newObject.rules = newRules;
            }
        }
    }
    
    return newObject;
}

-(NSDictionary*)asPListDictionary
{
    NSMutableDictionary* plistDict = [NSMutableDictionary new];
    
    NSDictionary* contextRuleDict = self.contextRule.asPListDictionary;
    if (contextRuleDict) {
        plistDict[[LSReplacementRule contextRuleKey]] = contextRuleDict;
        
        NSMutableArray* rulesArray = [NSMutableArray new];
        for (LSDrawingRule* rule in self.rules) {
            NSDictionary* ruleDict = rule.asPListDictionary;
            if (ruleDict) {
                [rulesArray addObject: ruleDict];
            }
        }
        plistDict[[LSReplacementRule rulesKey]] = rulesArray;
    }
    if (plistDict.count==0) {
        plistDict = nil;
    }
    return plistDict;
}

-(id)copyWithZone:(NSZone *)zone
{
    LSReplacementRule *copy = [[[self class] allocWithZone: zone] init];
    
    if (copy) {
        for ( NSString* aKey in [LSReplacementRule keysToBeCopied]) {
            id object = [self valueForKey: aKey];
            if (object)
            {
                [copy setValue: object forKey: aKey];
            }
        }
    }
    
    //contextRule
    //rules
    
    MDBFractalObjectList* rules = [MDBFractalObjectList new];
    for (LSDrawingRule* rule in self.rules)
    {
        [rules addObject: [rule copy]];
    }
    copy.rules = rules;
    
    return copy;
}
- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _contextRule = [LSDrawingRule new];
        _rules = [MDBFractalObjectList new];
        [_rules addObject: [LSDrawingRule new]];
    }
    return self;
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        for ( NSString* aKey in [[self class] keysToBeCopied])
        {
            if ([aDecoder containsValueForKey: aKey])
            {
                id object = [aDecoder decodeObjectForKey: aKey];
                [self setValue: object forKey: aKey];
            }
        }
        if ([aDecoder containsValueForKey: @"rules"]) {
            _rules = [aDecoder decodeObjectForKey: @"rules"];
        }
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder
{
    for ( NSString* aKey in [[self class] keysToBeCopied]) {
        id propertyValue = [self valueForKey: aKey];
        if (propertyValue) {
            [aCoder encodeObject: propertyValue forKey: aKey];
        }
    }
    if (_rules) {
        [aCoder encodeObject: _rules forKey: @"rules"];
    }
}

- (id) debugQuickLookObject
{
    return [self debugDescription];
}

-(NSString*)debugDescription
{
    NSString* ddesc = [NSString stringWithFormat: @"Context: %@\nRules: %@",[_contextRule debugDescription], _rules];
    return ddesc;
}

-(NSString*) rulesString {
    NSMutableString* rulesString = [[NSMutableString alloc]initWithCapacity: self.rules.count];
    for (LSDrawingRule* rule in self.rules) {
        [rulesString appendString: rule.productionString];
    }
    return rulesString;
}

@end