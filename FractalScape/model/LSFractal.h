//
//  LSFractal.h
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
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
@property (nonatomic, retain) NSNumber * isImmutable;
@property (nonatomic, retain) NSNumber * isReadOnly;
@property (nonatomic, retain) NSNumber * level;
@property (nonatomic, retain) NSNumber * lineChangeFactor;
@property (nonatomic, retain) NSNumber * lineLength;
@property (nonatomic, retain) NSNumber * lineLengthScaleFactor;
@property (nonatomic, retain) NSNumber * lineWidth;
@property (nonatomic, retain) NSNumber * lineWidthIncrement;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * randomness;
@property (nonatomic, retain) NSNumber * turningAngle;
@property (nonatomic, retain) NSNumber * turningAngleIncrement;
@property (nonatomic, retain) MBColor *backgroundColor;
@property (nonatomic, retain) LSDrawingRuleType *drawingRulesType;
@property (nonatomic, retain) NSOrderedSet *fillColors;
@property (nonatomic, retain) NSOrderedSet *lineColors;
@property (nonatomic, retain) NSSet *placements;
@property (nonatomic, retain) NSOrderedSet *replacementRules;
@property (nonatomic, retain) NSOrderedSet *startingRules;

// Manually added. Need to re-add if model is changed and exported from Xcode
@property (nonatomic,assign) BOOL                   rulesUnchanged;
@property (nonatomic,assign) BOOL                   levelUnchanged;
@property (nonatomic,strong) NSMutableString         *level0RulesCache;
@property (nonatomic,strong) NSMutableString         *level1RulesCache;
@property (nonatomic,strong) NSMutableString         *level2RulesCache;
@property (nonatomic,strong) NSMutableString         *levelNRulesCache;

@end

@interface LSFractal (CoreDataGeneratedAccessors)

- (void)insertObject:(MBColor *)value inFillColorsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromFillColorsAtIndex:(NSUInteger)idx;
- (void)insertFillColors:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeFillColorsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInFillColorsAtIndex:(NSUInteger)idx withObject:(MBColor *)value;
- (void)replaceFillColorsAtIndexes:(NSIndexSet *)indexes withFillColors:(NSArray *)values;
- (void)addFillColorsObject:(MBColor *)value;
- (void)removeFillColorsObject:(MBColor *)value;
- (void)addFillColors:(NSOrderedSet *)values;
- (void)removeFillColors:(NSOrderedSet *)values;
- (void)insertObject:(MBColor *)value inLineColorsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromLineColorsAtIndex:(NSUInteger)idx;
- (void)insertLineColors:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeLineColorsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInLineColorsAtIndex:(NSUInteger)idx withObject:(MBColor *)value;
- (void)replaceLineColorsAtIndexes:(NSIndexSet *)indexes withLineColors:(NSArray *)values;
- (void)addLineColorsObject:(MBColor *)value;
- (void)removeLineColorsObject:(MBColor *)value;
- (void)addLineColors:(NSOrderedSet *)values;
- (void)removeLineColors:(NSOrderedSet *)values;
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
