//
//  LSReplacementRule+addons.h
//  FractalScape
//
//  Created by Taun Chapman on 04/02/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "LSReplacementRule.h"

// max based on CoreData model 
#define kLSMaxReplacementRules 101


@interface LSReplacementRule (addons)

+(NSString*) rulesKey;
+(NSString*) contextRuleKey;
/*!
 The string representation of the series of replacements rules.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString   *rulesString;

@end
