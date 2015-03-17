//
//  LSDrawingRule.h
//  FractalScape
//
//  Created by Taun Chapman on 12/06/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

@import Foundation;

#import "MDBTileObjectProtocol.h"

#define kLSMaxCommandLength 64

@class LSDrawingRuleType;

@interface LSDrawingRule : NSObject <MDBTileObjectProtocol, NSCopying, NSCoding>

@property (nonatomic, copy) NSString        *descriptor;
@property (nonatomic, assign) NSInteger     displayIndex;
@property (nonatomic, copy) NSString        *drawingMethodString;
@property (nonatomic, copy) NSString        *iconIdentifierString;
@property (nonatomic, copy) NSString        *productionString;
@property (nonatomic, copy) NSString        *typeIdentifier;

@property (nonatomic,readonly) NSDictionary *asPListDictionary;

+(NSString*) defaultIdentifierString;

+(NSSortDescriptor*) sortDescriptor;

+(instancetype)newLSDrawingRuleFromPListDictionary: (NSDictionary*) ruleDict;

/*!
 Do two rules have the same property values?
 Does not include/check relationships.
 
 @param object the other rule
 
 @return YES if the properties are the same.
 */
-(BOOL) isSimilar:(id)object;

@end