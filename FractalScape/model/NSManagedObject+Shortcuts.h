//
//  NSManagedObject+Shortcuts.h
//  FractalScape
//
//  Created by Taun Chapman on 11/10/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

static NSString* kMBPropertyMaxValueKey = @"maxValue";
static NSString* kMBPropertyMinValueKey = @"minValue";
static NSString* kMBPropertyUnitValueKey = @"valueUnit";


@interface NSManagedObject (Shortcuts)

+ (NSString *)entityName;
+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context;
+ (NSEntityDescription*)entityDescriptionForContext: (NSManagedObjectContext*)context;

-(double) maxValueForProperty: (NSString*)propertyName;
-(double) minValueForProperty: (NSString*)propertyName;
@end
