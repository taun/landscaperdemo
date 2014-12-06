//
//  LSReplacementRule+addons.h
//  FractalScape
//
//  Created by Taun Chapman on 04/02/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "LSReplacementRule.h"

@interface LSReplacementRule (addons)

+(NSString*) rulesKey;
+(NSString*) contextRuleKey;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString   *rulesString;

@end
