//
//  LSDrawingRule+addons.m
//  FractalScape
//
//  Created by Taun Chapman on 03/27/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "LSDrawingRule+addons.h"

@implementation LSDrawingRule (addons)

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

-(UIImage*) asImage {
    UIImage* cellImage = [UIImage imageNamed: self.iconIdentifierString];
//    UIImage* resizingImage = [cellImage resizableImageWithCapInsets: UIEdgeInsetsZero resizingMode: UIImageResizingModeStretch];
    return cellImage;
}

@end
