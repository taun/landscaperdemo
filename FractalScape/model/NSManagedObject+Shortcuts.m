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
@end
