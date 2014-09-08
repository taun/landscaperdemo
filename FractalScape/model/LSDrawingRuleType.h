//
//  LSDrawingRuleType.h
//  FractalScape
//
//  Created by Taun Chapman on 04/02/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSDrawingRule, LSFractal;

@interface LSDrawingRuleType : NSManagedObject

@property (nonatomic, retain) NSString * descriptor;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *fractals;
@property (nonatomic, retain) NSSet *rules;
@end

@interface LSDrawingRuleType (CoreDataGeneratedAccessors)

- (void)addFractalsObject:(LSFractal *)value;
- (void)removeFractalsObject:(LSFractal *)value;
- (void)addFractals:(NSSet *)values;
- (void)removeFractals:(NSSet *)values;

- (void)addRulesObject:(LSDrawingRule *)value;
- (void)removeRulesObject:(LSDrawingRule *)value;
- (void)addRules:(NSSet *)values;
- (void)removeRules:(NSSet *)values;

@end
