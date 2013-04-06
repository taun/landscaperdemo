//
//  LSDrawingRuleType+addons.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 04/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "LSDrawingRuleType.h"

@interface LSDrawingRuleType (addons)

+(NSArray*) allRuleTypesInContext: (NSManagedObjectContext *)context;
+(LSDrawingRuleType*) findRuleTypeWithIdentifier:(NSString *)identifier inContext: (NSManagedObjectContext*) context;
@end
