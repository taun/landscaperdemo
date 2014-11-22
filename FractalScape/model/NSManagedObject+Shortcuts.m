//
//  NSManagedObject+Shortcuts.m
//  FractalScape
//
//  Created by Taun Chapman on 11/10/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "NSManagedObject+Shortcuts.h"

@implementation NSManagedObject (Shortcuts)

+ (NSString *)entityName {
    return NSStringFromClass([self class]);
}


+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
                                         inManagedObjectContext:context];
}
+ (NSEntityDescription*)entityDescriptionForContext:(NSManagedObjectContext *)context {
    NSEntityDescription *entity = [NSEntityDescription entityForName: [self entityName]
                                              inManagedObjectContext:context];
    return entity;
}

+ (NSSet *)keysToBeCopied {
    static NSSet *keysToBeCopied = nil;
    return keysToBeCopied;
}

-(id) mutableCopy {
    id entityCopy = [[self class] insertNewObjectIntoContext: self.managedObjectContext];
    
    if (entityCopy) {
        for ( NSString* aKey in [[self class] keysToBeCopied]) {
            id value = [self valueForKey: aKey];
            [entityCopy setValue: value forKey: aKey];
        }
        
    }
    return entityCopy;
}

@end
