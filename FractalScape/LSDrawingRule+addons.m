//
//  LSDrawingRule+addons.m
//  FractalScape
//
//  Created by Taun Chapman on 03/27/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "LSDrawingRule+addons.h"
#import "NSManagedObject+Shortcuts.h"


@implementation LSDrawingRule (addons)

+ (NSString *)entityName {
    return @"LSDrawingRule";
}
+(NSString*) defaultIdentifierString {
    static NSString* LSDrawingRuleDefaultIdentifierString = @"kBIconRulePlaceEmpty";
    return LSDrawingRuleDefaultIdentifierString;
}

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"displayIndex",
                          @"drawingMethodString",
                          @"iconIdentifierString",
                          @"productionString",
                          @"descriptor",
                          nil];
    }
    return keysToBeCopied;
}

+(LSDrawingRule*) findRuleWithType:(NSString *)ruleType productionString: (NSString*)production inContext: (NSManagedObjectContext*) context {
    LSDrawingRule* node = nil;
    
    NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    
    NSDictionary *substitutionDictionary =
    [NSDictionary dictionaryWithObjectsAndKeys: ruleType, @"TYPEIDENTIFIER", production, @"PRODUCTIONSTRING", nil];
    
    NSFetchRequest *fetchRequest =
    [model fetchRequestFromTemplateWithName:@"LSDrawingRuleOfTypeAndName"
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

/*!
 Override to create a default empty fractal definition.
 
 @param context standard NSManagedObjectContext
 
 @return aFractal
 */
+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context {
    LSDrawingRule* newRule = [super insertNewObjectIntoContext: context];
    
    newRule.descriptor = @"Default do nothing rule to be replaced by dragging a new rule.";
    newRule.iconIdentifierString = [LSDrawingRule defaultIdentifierString];
    newRule.drawingMethodString = @"commandDoNothing";
    newRule.productionString = @"A";
    
    return newRule;
}

-(BOOL) isDefaultObject {
    return ([self.iconIdentifierString compare: [LSDrawingRule defaultIdentifierString]] == NSOrderedSame);
}

-(id) mutableCopy {
    LSDrawingRule *ruleCopy = (LSDrawingRule*)[LSDrawingRule insertNewObjectIntoContext: self.managedObjectContext];
    
    if (ruleCopy) {
        for ( NSString* aKey in [LSDrawingRule keysToBeCopied]) {
            id value = [self valueForKey: aKey];
            [ruleCopy setValue: value forKey: aKey];
        }
        
    }
    return ruleCopy;
}

-(BOOL) isReferenced {
    BOOL referenced = (self.fractalStart != nil
                       || self.type != nil
                       || self.replacementRule != nil
                       || (self.contexts != nil && self.contexts.count > 0));
    return referenced;
}

-(UIImage*) asImage {
    UIImage* cellImage = [UIImage imageNamed: self.iconIdentifierString];
//    UIImage* resizingImage = [cellImage resizableImageWithCapInsets: UIEdgeInsetsZero resizingMode: UIImageResizingModeStretch];
    return cellImage;
}

@end
