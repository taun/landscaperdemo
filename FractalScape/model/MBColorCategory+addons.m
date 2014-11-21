//
//  MBColorCategory+addons.m
//  FractalScape
//
//  Created by Taun Chapman on 11/10/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBColorCategory+addons.h"
#import "MBColor+addons.h"
#import "NSManagedObject+Shortcuts.h"

@implementation MBColorCategory (addons)

+ (NSString *)entityName {
    return @"MBColorCategory";
}

+(NSArray*) allCatetegoriesInContext: (NSManagedObjectContext *)context {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [MBColorCategory entityDescriptionForContext: context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    return fetchedObjects;
}
+(MBColorCategory*) findCategoryWithIdentifier:(NSString *)identifier inContext: (NSManagedObjectContext*) context {
    MBColorCategory* node = nil;
    
    NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    
    NSDictionary *substitutionDictionary =
    [NSDictionary dictionaryWithObjectsAndKeys: identifier, @"TYPEIDENTIFIER", nil];
    
    NSFetchRequest *fetchRequest =
    [model fetchRequestFromTemplateWithName:@"MBColorCategoryWithIdentifier"
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

-(NSInteger)loadColorsFromPListColorsArray:(NSArray *)colorsArray {
    NSInteger addedColorsCount = 0;
    
    if (colorsArray) {
        NSManagedObjectContext* context = self.managedObjectContext;
        
        NSMutableSet* currentColors = [self mutableSetValueForKey: @"colors"];

        NSMutableSet* colorIdentifiers = [NSMutableSet setWithCapacity: currentColors.count];
        for (MBColor* color in currentColors) {
            [colorIdentifiers addObject: color.identifier];
        }
        
        
        for (NSDictionary* colorDict in colorsArray) {
            // iterate each color definition dictionary in the category
            if ([colorDict isKindOfClass: [NSDictionary class]]) {
                
                NSString* colorIdentifier = colorDict[@"identifier"];
                
                // don't add if no identifier or identifier already exists
                if (colorIdentifier && ![colorIdentifiers containsObject: colorIdentifier]) {
                    MBColor* newColor = [MBColor insertNewObjectIntoContext: context];
                    if (newColor) {
                        for (id propertyKey in colorDict) {
                            [newColor setValue: colorDict[propertyKey] forKey: propertyKey];
                        }
                        newColor.index = @(addedColorsCount);
                        [currentColors addObject: newColor];
                        addedColorsCount++;
                    }
                }
                
             }
        }
        
    }
    return addedColorsCount;
}
@end
