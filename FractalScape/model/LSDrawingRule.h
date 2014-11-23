//
//  LSDrawingRule.h
//  FractalScape
//
//  Created by Taun Chapman on 11/22/14.
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
@property (nonatomic, retain) LSDrawingRuleType *type;
@property (nonatomic, retain) LSReplacementRule *replacementRule;
@property (nonatomic, retain) LSFractal *fractalStart;

@end
