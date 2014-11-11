//
//  LSDrawingRuleType+addons.m
//  FractalScape
//
//  Created by Taun Chapman on 04/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "LSDrawingRuleType+addons.h"
#import "LSDrawingRule+addons.h"
#import "NSManagedObject+Shortcuts.h"

@implementation LSDrawingRuleType (addons)

+ (NSString *)entityName {
    return @"LSDrawingRuleType";
}

+(NSArray*) allRuleTypesInContext: (NSManagedObjectContext *)context {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [LSDrawingRuleType entityDescriptionForContext: context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    return fetchedObjects;
}
+(LSDrawingRuleType*) findRuleTypeWithIdentifier:(NSString *)identifier inContext: (NSManagedObjectContext*) context {
    LSDrawingRuleType* node = nil;
    
    NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    
    NSDictionary *substitutionDictionary =
    [NSDictionary dictionaryWithObjectsAndKeys: identifier, @"TYPEIDENTIFIER", nil];
    
    NSFetchRequest *fetchRequest =
    [model fetchRequestFromTemplateWithName:@"LSDrawingRuleTypeWithIdentifier"
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

-(NSDictionary*) rulesDictionary {
    NSOrderedSet* rules = self.rules;
    
    NSMutableDictionary* rulesDict = [[NSMutableDictionary alloc] initWithCapacity: rules.count];
    for (LSDrawingRule* rule in rules) {
        //
        rulesDict[rule.productionString] = rule;
    }
    return [rulesDict copy];
}
-(NSArray*) rulesArrayFromRuleString: (NSString*) ruleString {
    NSInteger sourceLength = ruleString.length;
    
    NSDictionary* rulesDict = self.rulesDictionary;
    
    NSMutableArray* rulesArray = [[NSMutableArray alloc] initWithCapacity: sourceLength];
    
    for (int y=0; y < sourceLength; y++) {
        //
        NSString* key = [ruleString substringWithRange: NSMakeRange(y, 1)];
        
        LSDrawingRule* rule = rulesDict[key];
        
        if (rule) {
            [rulesArray addObject: rule];
        }
        
    }
    return [rulesArray copy];
}

-(NSInteger)loadRulesFromPListRulesArray: (NSArray*)rulesArray {
    NSInteger addedRulesCount = 0;
    
    if (rulesArray) {
        NSManagedObjectContext* context = self.managedObjectContext;
        
        
        NSMutableOrderedSet* currentDefaultRules = [self mutableOrderedSetValueForKey: @"rules"];
        // COuld convert set to dictionary and ise a lookup to detect existence but not worth it for a few rules.
        
        //Sort rules before adding so orderedSet is created in desired order.
        //Will not work as desired if rules using same indexes already exist in LSDrawingRuleType.
        NSSortDescriptor* ruleIndexSorting = [NSSortDescriptor sortDescriptorWithKey: @"displayIndex" ascending: YES];
        NSSortDescriptor* ruleAlphaSorting = [NSSortDescriptor sortDescriptorWithKey: @"iconIdentifierString" ascending: YES];
        NSArray* sortedRules = [rulesArray sortedArrayUsingDescriptors: @[ruleIndexSorting,ruleAlphaSorting]];
        
        for (NSDictionary* rule in sortedRules) {
            BOOL alreadyExists = NO;
            
            for (NSManagedObject* existingRuleObject in currentDefaultRules) {
                if ([existingRuleObject isKindOfClass: [LSDrawingRule class]]) {
                    LSDrawingRule* existingRule = (LSDrawingRule*)existingRuleObject;
                    if ([existingRule.productionString isEqualToString: rule[@"productionString"]]) {
                        alreadyExists = YES;
                    }
                }
            }
            if (!alreadyExists) {
                LSDrawingRule *newDrawingRule = [LSDrawingRule insertNewObjectIntoContext: context];
                newDrawingRule.productionString = rule[@"productionString"];
                newDrawingRule.drawingMethodString = rule[@"drawingMethodString"];
                newDrawingRule.iconIdentifierString = rule[@"iconIdentifierString"];
                newDrawingRule.displayIndex = rule[@"displayIndex"];
                [currentDefaultRules addObject: newDrawingRule]; // this should also take care of relationship?
                addedRulesCount += 1;
            }
        }
    }
    return addedRulesCount;
}

@end
