//
//  LSDrawingRuleType+addons.h
//  FractalScape
//
//  Created by Taun Chapman on 04/01/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "LSDrawingRuleType.h"

@interface LSDrawingRuleType (addons)

+(NSString*) rulesKey;
+(NSArray*) allRuleTypesInContext: (NSManagedObjectContext *)context;
+(LSDrawingRuleType*) findRuleTypeWithIdentifier:(NSString *)identifier inContext: (NSManagedObjectContext*) context;

/*!
 dictionary generated for each access to the property. The rule.productionString is the key.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSDictionary* rulesDictionary;
-(NSArray*) rulesArrayFromRuleString: (NSString*) ruleString;

-(NSInteger)loadRulesFromPListRulesArray: (NSArray*) rulesArray;
@end
