//
//  LSFractal.h
//  FractalScape
//
//  Created by Taun Chapman on 11/21/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSDrawingRule, LSDrawingRuleType, LSReplacementRule, MBColor, MBPlacedEntity;

@interface LSFractal : NSManagedObject

@property (nonatomic, retain) NSNumber * baseAngle;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSString * descriptor;
@property (nonatomic, retain) NSNumber * eoFill;
@property (nonatomic, retain) NSNumber * fill;
@property (nonatomic, retain) NSNumber * isImmutable;
@property (nonatomic, retain) NSNumber * isReadOnly;
@property (nonatomic, retain) NSNumber * level;
@property (nonatomic, retain) NSNumber * lineCap;
@property (nonatomic, retain) NSNumber * lineJoin;
@property (nonatomic, retain) NSNumber * lineLength;
@property (nonatomic, retain) NSNumber * lineLengthScaleFactor;
@property (nonatomic, retain) NSNumber * lineWidth;
@property (nonatomic, retain) NSNumber * lineWidthIncrement;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * randomize;
@property (nonatomic, retain) NSNumber * randomness;
@property (nonatomic, retain) NSNumber * stroke;
@property (nonatomic, retain) NSNumber * turningAngle;
@property (nonatomic, retain) NSNumber * turningAngleIncrement;
@property (nonatomic, retain) LSDrawingRuleType *drawingRulesType;
@property (nonatomic, retain) NSSet *fillColors;
@property (nonatomic, retain) NSSet *lineColors;
@property (nonatomic, retain) NSSet *placements;
@property (nonatomic, retain) NSOrderedSet *replacementRules;
@property (nonatomic, retain) NSOrderedSet *startingRules;
@property (nonatomic, retain) MBColor *backgroundColor;
@end

@interface LSFractal (CoreDataGeneratedAccessors)

- (void)addFillColorsObject:(MBColor *)value;
- (void)removeFillColorsObject:(MBColor *)value;
- (void)addFillColors:(NSSet *)values;
- (void)removeFillColors:(NSSet *)values;

- (void)addLineColorsObject:(MBColor *)value;
- (void)removeLineColorsObject:(MBColor *)value;
- (void)addLineColors:(NSSet *)values;
- (void)removeLineColors:(NSSet *)values;

- (void)addPlacementsObject:(MBPlacedEntity *)value;
- (void)removePlacementsObject:(MBPlacedEntity *)value;
- (void)addPlacements:(NSSet *)values;
- (void)removePlacements:(NSSet *)values;

- (void)insertObject:(LSReplacementRule *)value inReplacementRulesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromReplacementRulesAtIndex:(NSUInteger)idx;
- (void)insertReplacementRules:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeReplacementRulesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInReplacementRulesAtIndex:(NSUInteger)idx withObject:(LSReplacementRule *)value;
- (void)replaceReplacementRulesAtIndexes:(NSIndexSet *)indexes withReplacementRules:(NSArray *)values;
- (void)addReplacementRulesObject:(LSReplacementRule *)value;
- (void)removeReplacementRulesObject:(LSReplacementRule *)value;
- (void)addReplacementRules:(NSOrderedSet *)values;
- (void)removeReplacementRules:(NSOrderedSet *)values;
- (void)insertObject:(LSDrawingRule *)value inStartingRulesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromStartingRulesAtIndex:(NSUInteger)idx;
- (void)insertStartingRules:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeStartingRulesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInStartingRulesAtIndex:(NSUInteger)idx withObject:(LSDrawingRule *)value;
- (void)replaceStartingRulesAtIndexes:(NSIndexSet *)indexes withStartingRules:(NSArray *)values;
- (void)addStartingRulesObject:(LSDrawingRule *)value;
- (void)removeStartingRulesObject:(LSDrawingRule *)value;
- (void)addStartingRules:(NSOrderedSet *)values;
- (void)removeStartingRules:(NSOrderedSet *)values;
@end
