//
//  MBColor+addons.m
//  FractalScape
//
//  Created by Taun Chapman on 02/02/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBColor+addons.h"
#import "LSFractal+addons.h"
#import "NSManagedObject+Shortcuts.h"

@implementation MBColor (addons)

+ (NSString *)entityName {
    return @"MBColor";
}
+(instancetype) insertNewObjectIntoContext:(NSManagedObjectContext *)context {
    MBColor* newInstance = [super insertNewObjectIntoContext: context];
    newInstance.imagePath = @"kBIconRulePlaceEmpty";
    return newInstance;
}
+(NSArray*) allColorsInContext: (NSManagedObjectContext *)context {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [MBColor entityDescriptionForContext: context];
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
+(NSString*) defaultIdentifierString {
    // This string is assigned by default in the CoreData model definition for the MBColor property identifier.
    static NSString* MBColorDefaultIdentifierString = @"NoneYet";
    return MBColorDefaultIdentifierString;
}
+(MBColor*) newMBColorWithPListDictionary:(NSDictionary *)colorDict inContext:(NSManagedObjectContext *)context {
    
    MBColor *newColor = [MBColor insertNewObjectIntoContext: context];
    
    if (newColor) {
        for (id propertyKey in colorDict) {
            [newColor setValue: colorDict[propertyKey] forKey: propertyKey];
        }
    }
    return newColor;
}


+(MBColor*) newMBColorWithUIColor:(UIColor *)color inContext:(NSManagedObjectContext *)context {
    
    MBColor *newColor = [MBColor insertNewObjectIntoContext: context];
    
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
        
        newColor.imagePath = @"";
    }
    return newColor;
}

+(MBColor*) findMBColorWithIdentifier:(NSString *)colorIdentifier inContext: (NSManagedObjectContext*) context{
    
//    NSLog(@"All defined colors: %@;", [MBColor allColorsInContext: context]);
    
    MBColor* node = nil;
    
    NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    
    NSDictionary *substitutionDictionary =
    @{@"MBIDENTIFIER": colorIdentifier};
    
    NSFetchRequest *fetchRequest =
    [model fetchRequestFromTemplateWithName:@"MBColorWithIdentifier"
                      substitutionVariables:substitutionDictionary];
    
    NSArray *fetchedObjects;
    fetchedObjects = [context executeFetchRequest:fetchRequest error: nil];
    
    // ToDo deal with error
    // There should always be only one. Don't know what error to post if > 1
    if ( ([fetchedObjects count] >= 1) ) {
        node = fetchedObjects[0];
    }
    
    return node;
}
+(NSSortDescriptor*) colorsSortDescriptor {
    return  [NSSortDescriptor sortDescriptorWithKey: @"index" ascending: YES];
}

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    if (keysToBeCopied == nil) {
        keysToBeCopied = [[NSSet alloc] initWithObjects:
                          @"alpha",
                          @"red",
                          @"blue",
                          @"green",
                          @"identifier",
                          @"imagePath",
                          @"name",
                          @"index",
                          nil];
    }
    return keysToBeCopied;
}
-(id) mutableCopy {
    MBColor *entityCopy = (MBColor*)[MBColor insertNewObjectIntoContext: self.managedObjectContext];
    
    if (entityCopy) {
        for ( NSString* aKey in [MBColor keysToBeCopied]) {
            id value = [self valueForKey: aKey];
            [entityCopy setValue: value forKey: aKey];
        }
        
     }
    return entityCopy;
}


-(UIColor*) asUIColor {
    
    UIColor* newUIColor;
    UIImage* colorImage;
    
    NSString* imagePath = self.imagePath;
    
    if (imagePath && imagePath.length != 0) {
        colorImage = [UIImage imageNamed: self.imagePath];
        if (colorImage) {
            // use pattern image
            newUIColor = [UIColor colorWithPatternImage: colorImage];
        }
    } else {
        newUIColor = [UIColor colorWithRed:[self.red floatValue]
                                     green:[self.green floatValue]
                                      blue:[self.blue floatValue]
                                     alpha:[self.alpha floatValue]];
    }
    
    return newUIColor;
}

-(UIImage*) thumbnailImageSize: (CGSize) size {
    UIImage* thumbnail;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGRect viewRect = CGRectMake(0, 0, size.width, size.height);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    UIColor* thumbNailBackground = [self asUIColor];
    [thumbNailBackground setFill];
    CGContextFillRect(context, viewRect);
    CGContextRestoreGState(context);
    
    
    thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return thumbnail;
}

-(BOOL) isDefaultObject {
    return [[MBColor defaultIdentifierString] isEqualToString: self.identifier];
}
-(BOOL) isReferenced {
    BOOL referenced = (self.background !=nil
                       || self.category != nil
                       || self.fractalColor != nil
                       || self.fractalFill != nil
                       || self.fractalLine != nil);
    return referenced;
}
-(UIImage*) asImage {
    return [self thumbnailImageSize: CGSizeMake(40.0, 40.0)];
}

@end
