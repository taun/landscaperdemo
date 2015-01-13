//
//  LSDrawingRule+addons.h
//  FractalScape
//
//  Created by Taun Chapman on 03/27/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LSDrawingRule.h"
#import "MDBTileObjectProtocol.h"

#import "NSManagedObject+Shortcuts.h"

@interface LSDrawingRule (addons) <MDBTileObjectProtocol>

+(LSDrawingRule*) findRuleWithType:(NSString *)ruleType productionString: (NSString*)production inContext: (NSManagedObjectContext*) context;
+(NSString*) defaultIdentifierString;

/*!
 Do two rules have the same property values?
 Does not include/check relationships.
 
 @param object the other rule
 
 @return YES if the properties are the same.
 */
-(BOOL) isSimilar:(id)object;

@end
