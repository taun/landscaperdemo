//
//  LSDrawingRuleType.h
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import Foundation;


@interface LSDrawingRuleType : NSObject <NSCoding>

/*!
 Class version number.
 */
@property (nonatomic, readonly) NSInteger       version;
/*!
 unique key identifier
 */
@property (nonatomic, copy) NSString            *identifier;
/*!
 Name for the user
 */
@property (nonatomic, copy) NSString            *name;
/*!
 User description
 */
@property (nonatomic, copy) NSString            *descriptor;
/*!
 Available rules
 */
@property (nonatomic, strong) NSDictionary      *rules;
/*!
 Available rules sorted by index?
 */
@property (nonatomic, readonly) NSArray         *rulesAsSortedArray;

+(instancetype)newLSDrawingRuleTypeFromDefaultPListDictionary;
+(instancetype)newLSDrawingRuleTypeFromPListDictionary: (NSDictionary*)plistDict;

-(NSArray*)rulesArrayFromRuleString: (NSString*) ruleString;

-(NSInteger)loadRulesFromPListRulesArray: (NSArray*) rulesArray;

@end