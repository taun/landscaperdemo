//
//  LSReplacementRule+addons.m
//  FractalScape
//
//  Created by Taun Chapman on 04/02/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "LSReplacementRule+addons.h"
#import "LSDrawingRule+addons.h"
#import "NSManagedObject+Shortcuts.h"

@implementation LSReplacementRule (addons)

+ (NSString *)entityName {
    return @"LSReplacementRule";
}

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"contextRule",
                          nil];
    }
    return keysToBeCopied;
}

-(id) mutableCopy {
    LSReplacementRule *copy = [LSReplacementRule insertNewObjectIntoContext: self.managedObjectContext];
    
    if (copy) {
        for ( NSString* aKey in [LSReplacementRule keysToBeCopied]) {
            id value = [self valueForKey: aKey];
            [copy setValue: value forKey: aKey];
        }
    }
    
    //contextRule
    //rules
    
    NSMutableOrderedSet* rules = [copy mutableOrderedSetValueForKey: @"rules"];
    for (LSDrawingRule* rule in self.rules) {
        [rules addObject: [rule mutableCopy]];
    }
  
    return copy;
}

-(NSString*) rulesString {
    NSMutableString* rulesString = [[NSMutableString alloc]initWithCapacity: self.rules.count];
    for (LSDrawingRule* rule in self.rules) {
        [rulesString appendString: rule.productionString];
    }
    return rulesString;
}

@end
