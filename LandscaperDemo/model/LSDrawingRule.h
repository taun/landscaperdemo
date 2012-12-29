//
//  LSDrawingRule.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/20/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LSDrawingRuleType;

@interface LSDrawingRule : NSManagedObject

@property (nonatomic, retain) NSString * drawingMethodString;
@property (nonatomic, retain) NSString * productionString;
@property (nonatomic, retain) LSDrawingRuleType *type;

@end
