//
//  MBColor+addons.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 02/02/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBColor+addons.h"

@implementation MBColor (addons)

+(NSArray*) allColorsInContext: (NSManagedObjectContext *)context {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MBColor"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        // Handle the error.
    }
    return fetchedObjects;
}

+(UIColor*) newDefaultUIColor {
    return [UIColor colorWithRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0];
}

+(MBColor*) newMBColorWithUIColor:(UIColor *)color inContext:(NSManagedObjectContext *)context {
    
    MBColor *newColor = [NSEntityDescription
                         insertNewObjectForEntityForName:@"MBColor"
                         inManagedObjectContext: context];
    
    if (newColor) {
        CGFloat red;
        CGFloat green;
        CGFloat blue;
        CGFloat alpha;
        
        BOOL success = [color getRed: &red green: &green blue: &blue alpha: &alpha];
        
        if (success) {
            newColor.red = [NSNumber numberWithDouble: red];
            newColor.blue = [NSNumber numberWithDouble: blue];
            newColor.green = [NSNumber numberWithDouble: green];
            newColor.alpha = [NSNumber numberWithDouble: alpha];
        }
    }
    return newColor;
}

+(MBColor*) findMBColorWithIdentifier:(NSString *)colorIdentifier inContext: (NSManagedObjectContext*) context{
    
//    NSLog(@"All defined colors: %@;", [MBColor allColorsInContext: context]);
    
    MBColor* node = nil;
    
    NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    
    NSDictionary *substitutionDictionary =
    [NSDictionary dictionaryWithObjectsAndKeys: colorIdentifier, @"MBIDENTIFIER", nil];
    
    NSFetchRequest *fetchRequest =
    [model fetchRequestFromTemplateWithName:@"MBColorWithIdentifier"
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

-(UIColor*) asUIColor {
    
    UIColor* newUIColor;
    
    UIImage* colorImage = [UIImage imageNamed: self.imagePath];
    
    if (colorImage) {
        // use pattern image
        newUIColor = [UIColor colorWithPatternImage: colorImage];
    } else {
        newUIColor = [UIColor colorWithRed:[self.red floatValue]
                                     green:[self.green floatValue]
                                      blue:[self.blue floatValue]
                                     alpha:[self.alpha floatValue]];
    }
    return newUIColor;
}

@end
