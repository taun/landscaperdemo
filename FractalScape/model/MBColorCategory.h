//
//  MBColorCategory.h
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MBColor;

@interface MBColorCategory : NSManagedObject

@property (nonatomic, retain) NSString * descriptor;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSOrderedSet *colors;
@end

@interface MBColorCategory (CoreDataGeneratedAccessors)

- (void)insertObject:(MBColor *)value inColorsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromColorsAtIndex:(NSUInteger)idx;
- (void)insertColors:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeColorsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInColorsAtIndex:(NSUInteger)idx withObject:(MBColor *)value;
- (void)replaceColorsAtIndexes:(NSIndexSet *)indexes withColors:(NSArray *)values;
- (void)addColorsObject:(MBColor *)value;
- (void)removeColorsObject:(MBColor *)value;
- (void)addColors:(NSOrderedSet *)values;
- (void)removeColors:(NSOrderedSet *)values;
@end
