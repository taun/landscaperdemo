//
//  LSDrawingRule.h
//  FractalScape
//
//  Created by Taun Chapman on 04/02/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSDrawingRuleType;

@interface LSDrawingRule : NSManagedObject

@property (nonatomic, retain) NSString * drawingMethodString;
@property (nonatomic, retain) NSString * productionString;
@property (nonatomic, retain) LSDrawingRuleType *type;

@end
