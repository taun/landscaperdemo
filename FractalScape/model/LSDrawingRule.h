//
//  LSDrawingRule.h
//  FractalScape
//
//  Created by Taun Chapman on 12/01/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSDrawingRuleType, LSFractal, LSReplacementRule;

@interface LSDrawingRule : NSManagedObject

@property (nonatomic, retain) NSNumber * displayIndex;
@property (nonatomic, retain) NSString * drawingMethodString;
@property (nonatomic, retain) NSString * iconIdentifierString;
@property (nonatomic, retain) NSString * productionString;
@property (nonatomic, retain) NSString * descriptor;
@property (nonatomic, retain) NSSet *contexts;
@property (nonatomic, retain) LSFractal *fractalStart;
@property (nonatomic, retain) LSReplacementRule *replacementRule;
@property (nonatomic, retain) LSDrawingRuleType *type;
@end

@interface LSDrawingRule (CoreDataGeneratedAccessors)

- (void)addContextsObject:(LSReplacementRule *)value;
- (void)removeContextsObject:(LSReplacementRule *)value;
- (void)addContexts:(NSSet *)values;
- (void)removeContexts:(NSSet *)values;

@end
