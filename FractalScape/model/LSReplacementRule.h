//
//  LSReplacementRule.h
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import Foundation;

@class MDBFractalObjectList;

// max based on CoreData model
#define kLSMaxReplacementRules 101

@class LSDrawingRule, LSFractal;

@interface LSReplacementRule : NSObject <NSCopying, NSCoding>

/*!
 The rule to be replaced.
 */
@property (nonatomic, retain) LSDrawingRule                 *contextRule;
/*!
 An array of LSDrawingRule to replace the contextRule
 */
@property (nonatomic, retain) MDBFractalObjectList          *rules;

/*!
 The string representation of the series of replacements rules.
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString   *rulesString;

@property (nonatomic,readonly) NSDictionary                 *asPListDictionary;

+(instancetype) newLSReplacementRuleFromPListDictionary: (NSDictionary*) rRuleDict;


+(NSString*) rulesKey;
+(NSString*) contextRuleKey;


@end