//
//  LSReplacementRule.h
//  FractalScape
//
//  Created by Taun Chapman on 10/16/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSDrawingRule, LSFractal;

@interface LSReplacementRule : NSManagedObject

@property (nonatomic, retain) NSSet *lsFractal;
@property (nonatomic, retain) LSDrawingRule *contextRule;
@property (nonatomic, retain) NSOrderedSet *rules;
@end

@interface LSReplacementRule (CoreDataGeneratedAccessors)

- (void)addLsFractalObject:(LSFractal *)value;
- (void)removeLsFractalObject:(LSFractal *)value;
- (void)addLsFractal:(NSSet *)values;
- (void)removeLsFractal:(NSSet *)values;

- (void)insertObject:(LSDrawingRule *)value inRulesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRulesAtIndex:(NSUInteger)idx;
- (void)insertRules:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRulesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRulesAtIndex:(NSUInteger)idx withObject:(LSDrawingRule *)value;
- (void)replaceRulesAtIndexes:(NSIndexSet *)indexes withRules:(NSArray *)values;
- (void)addRulesObject:(LSDrawingRule *)value;
- (void)removeRulesObject:(LSDrawingRule *)value;
- (void)addRules:(NSOrderedSet *)values;
- (void)removeRules:(NSOrderedSet *)values;
@end
