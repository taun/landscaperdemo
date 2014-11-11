//
//  NSManagedObject+Shortcuts.h
//  FractalScape
//
//  Created by Taun Chapman on 11/10/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Shortcuts)

+ (NSString *)entityName;
+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context;
+ (NSEntityDescription*)entityDescriptionForContext: (NSManagedObjectContext*)context;

@end
