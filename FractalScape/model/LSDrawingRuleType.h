//
//  LSDrawingRuleType.h
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSDrawingRule, LSFractal;

@interface LSDrawingRuleType : NSManagedObject

@property (nonatomic, retain) NSString * descriptor;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *fractals;
@property (nonatomic, retain) NSOrderedSet *rules;
@end

@interface LSDrawingRuleType (CoreDataGeneratedAccessors)

- (void)addFractalsObject:(LSFractal *)value;
- (void)removeFractalsObject:(LSFractal *)value;
- (void)addFractals:(NSSet *)values;
- (void)removeFractals:(NSSet *)values;

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
