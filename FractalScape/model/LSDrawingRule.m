//
//  LSDrawingRule.m
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "LSDrawingRule.h"
#import "LSDrawingRuleType.h"
#import "LSFractal.h"
#import "LSReplacementRule.h"


@implementation LSDrawingRule

+(NSString*) defaultIdentifierString {
    static NSString* LSDrawingRuleDefaultIdentifierString = @"kBIconRulePlaceEmpty";
    return LSDrawingRuleDefaultIdentifierString;
}

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"displayIndex",
                          @"drawingMethodString",
                          @"iconIdentifierString",
                          @"productionString",
                          @"descriptor",
                          @"typeIdentifier",
                          nil];
    });
    return keysToBeCopied;
}

+(NSSortDescriptor*)sortDescriptor
{
    NSSortDescriptor* indexDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"displayIndex" ascending: YES];
    return  indexDescriptor;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _descriptor = @"Default do nothing rule to be replaced by dragging a new rule.";
        _iconIdentifierString = [LSDrawingRule defaultIdentifierString];
        _drawingMethodString = @"commandDoNothing";
        _productionString = @"Z";
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        for ( NSString* aKey in [[self class] keysToBeCopied]) {
            id object = [aDecoder decodeObjectForKey: aKey];
            if (object) {
                [self setValue: object forKey: aKey];
            }
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
}

+(LSDrawingRule*) newLSDrawingRuleFromPListDictionary:(NSDictionary *)ruleDict {
    
    LSDrawingRule *newObject = [[self class] new];
    
    if (newObject) {
        for (id propertyKey in ruleDict) {
            [newObject setValue: ruleDict[propertyKey] forKey: propertyKey];
        }
    }
    return newObject;
}

- (id) debugQuickLookObject
{
    return [self debugDescription];
}

-(NSString*)debugDescription
{
    NSString* ddesc = [NSString stringWithFormat: @"Production String: %@, Command: %@",_productionString, _drawingMethodString];
    return ddesc;
}

-(NSDictionary*)asPListDictionary
{
    NSMutableDictionary* plistDict = [NSMutableDictionary new];
    for (NSString* aKey in [[self class] keysToBeCopied]) {
        id object = [self valueForKey: aKey];
        if (object) {
            [plistDict setObject: object forKey: aKey];
        }
    }
    if (plistDict.count == 0) {
        plistDict = nil;
    }
    return plistDict;
}

-(BOOL) isDefaultObject {
    return ([self.iconIdentifierString compare: [LSDrawingRule defaultIdentifierString]] == NSOrderedSame);
}

-(id) copyWithZone:(NSZone *)zone {
    LSDrawingRule *copy = [[[self class]allocWithZone: zone] init];
    
    if (copy) {
        for ( NSString* aKey in [LSDrawingRule keysToBeCopied]) {
            id object = [self valueForKey: aKey];
            if (object) {
                [copy setValue: object forKey: aKey];
            }
         }
        
    }
    return copy;
}
-(BOOL) isSimilar:(id)object {
    BOOL result = NO;
    
    if ([object isMemberOfClass: [self class]]) {
        LSDrawingRule* objectAsRule = (LSDrawingRule*) object;
        
        result = [self.descriptor isEqualToString: objectAsRule.descriptor];
        result = result && [self.iconIdentifierString isEqualToString: objectAsRule.iconIdentifierString];
        result = result && [self.drawingMethodString isEqualToString: objectAsRule.drawingMethodString];
        result = result && [self.productionString isEqualToString: objectAsRule.productionString];
    }
    
    return result;
}

-(UIImage*) asImage {
    UIImage* cellImage = [UIImage imageNamed: self.iconIdentifierString];
    //    UIImage* resizingImage = [cellImage resizableImageWithCapInsets: UIEdgeInsetsZero resizingMode: UIImageResizingModeStretch];
    return cellImage;
}


@end