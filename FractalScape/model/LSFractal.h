//
//  LSFractal.h
//  MDUiKit
//
//  Created by Taun Chapman on 10/09/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSDrawingRuleType, LSReplacementRule, MBColor, MBPlacedEntity;

@interface LSFractal : NSManagedObject

@property (nonatomic, retain) NSString * axiom;
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
@property (nonatomic, retain) MBColor *fillColor;
@property (nonatomic, retain) MBColor *lineColor;
@property (nonatomic, retain) NSSet *placements;
@property (nonatomic, retain) NSOrderedSet *replacementRules;
@end

@interface LSFractal (CoreDataGeneratedAccessors)

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
@end
