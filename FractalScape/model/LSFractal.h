//
//  LSFractal.h
//  FractalScape
//
//  Created by Taun Chapman on 02/05/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//


@import Foundation;
@import QuartzCore;
@import UIKit;

#import "MDBFractalCategory.h"
#import "MDBFractalObjectList.h"

@class LSDrawingRuleType;

#define kLSMaxRules 256
/*!
 Convenience functions which should be in a math library.
 
 @param degrees angle in degrees
 
 @return angle in radians
 */
static inline double radians (double degrees) {return degrees * M_PI/180.0;}
static inline double degrees (double radians) {return radians * 180.0/M_PI;}


@class LSDrawingRule, LSDrawingRuleType, LSReplacementRule, MBColor, MBColorCategory;

/*!
 An Lindenmaier System Fractal. Using a CoreData persistence layer. Probably should have just used PList archiving for persistence.
 */
@interface LSFractal : NSObject <NSCopying, NSCoding>

+(NSInteger)    version;

//@property(nonatomic,strong) LSDrawingRuleType               *sourceDrawingRules;
//@property(nonatomic,strong) NSArray                         *sourceColorCategories;
//@property(nonatomic,strong) NSArray                         *categories;

/*!
 Class version number.
 */
@property (nonatomic, readonly) NSInteger               version;
/*!
 Category of the fractal.
 */
@property (nonatomic, strong) MDBFractalCategory        *category;
/*!
 UUID string
 */
@property (nonatomic, copy) NSString                    *identifier;
/*!
 Fractal name.
 */
@property (nonatomic, copy) NSString                    *name;
/*!
 Description
 */
@property (nonatomic, copy) NSString                    *descriptor;

/*!
 Basic mode adds the draw command automatically.
 
 Advanced mode requires manual addition of the draw mode. Advanced mode gives more control.
 */
@property (nonatomic, assign) BOOL                      advancedMode;
/*!
 Array if starting LSDrawingRule rules
 */
@property (nonatomic, strong) MDBFractalObjectList      *startingRules;
/*!
 Array of LSReplacementRule
 */
@property (nonatomic, strong) NSMutableArray            *replacementRules;
/*!
 The angle in radians about which to rotate the whole fractal.
 */
@property (nonatomic, assign) CGFloat       baseAngle;
/*!
 Even odd fill boolean.
 */
@property (nonatomic, assign) BOOL          eoFill;
/*!
 An immutable sample fractal. Obsolete?
 */
@property (nonatomic, assign) BOOL          isImmutable;
@property (nonatomic, assign) BOOL          isReadOnly;
/*!
 Property to indicate whether there are enough rules defined to generate a fractal.
 */
@property (nonatomic,assign,readonly) BOOL  isRenderable;
/*!
 Number of generations to generate.
 */
@property (nonatomic, assign) NSInteger     level;
@property (nonatomic, assign) CGFloat       lineChangeFactor;
@property (nonatomic, assign) CGFloat       lineLength;
@property (nonatomic, assign) CGFloat       lineLengthScaleFactor;
@property (nonatomic, assign) CGFloat       lineWidth;
@property (nonatomic, assign) CGFloat       lineWidthIncrement;
@property (nonatomic, assign) CGFloat       randomness;
@property (nonatomic, assign) CGFloat       turningAngle;
@property (nonatomic, assign) CGFloat       turningAngleIncrement;
@property (nonatomic, assign) BOOL          autoExpand;
@property (nonatomic, strong) NSData        *level0RulesCache;
@property (nonatomic, strong) NSData        *level1RulesCache;
@property (nonatomic, strong) NSData        *level2RulesCache;
@property (nonatomic, strong) NSData        *levelNRulesCache;
@property (nonatomic, assign) CGFloat       levelGrowthRate;
@property (nonatomic, assign) BOOL          rulesUnchanged;
@property (nonatomic, assign) BOOL          levelUnchanged;
@property (nonatomic, strong) MBColor       *backgroundColor;
@property (nonatomic, strong) MDBFractalObjectList       *fillColors;
@property (nonatomic, strong) MDBFractalObjectList       *lineColors;
@property (nonatomic, strong) MDBFractalObjectList       *imageFilters;
@property (nonatomic, assign) BOOL                       applyFilters;

@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString               *startingRulesAsString;
@property (NS_NONATOMIC_IOSONLY, readonly) NSDictionary                 *replacementRulesDictionary;
@property (NS_NONATOMIC_IOSONLY, readonly) NSData                       *level0Rules;
@property (NS_NONATOMIC_IOSONLY, readonly) NSData                       *level1Rules;
@property (NS_NONATOMIC_IOSONLY, readonly) NSData                       *level2Rules;
@property (NS_NONATOMIC_IOSONLY, readonly) NSData                       *levelNRules;

@property (nonatomic,readonly) NSDictionary                             *asPListDictionary;
@property (nonatomic,readonly) NSArray                                  *startingRulesAsPListArray;
@property (nonatomic,readonly) NSArray                                  *replacementRulesAsPListArray;
@property (nonatomic,readonly) NSArray                                  *lineColorAsPListArray;
@property (nonatomic,readonly) NSArray                                  *fillColorAsPListArray;

+(BOOL)automaticallyNotifiesObserversOfrulesUnchanged;
+(BOOL)automaticallyNotifiesObserversOflevelUnchanged;
+(instancetype) newLSFractalFromPListDictionary: (NSDictionary*)plistDict;
+(NSMutableArray*) newCollectionOfLSReplacementRulesFromPListArray: (NSArray*) plistArray;
+(MDBFractalObjectList*) newCollectionOfLSDrawingRulesFromPListArray: (NSArray*) plistArray;
+(MDBFractalObjectList*) newCollectionOfMBColorsFromPListArray: (NSArray*) plistArray;

/*!
 A set of fractal property paths which effect the label views of the fractal. To be observed by presenters of the labels
 
 @return a set of strings corresponding to fractal property key paths effecting the labels.
 */
+(NSSet*) labelProperties;
/*!
 A set of fractal property paths which effect the production of the final fractal generation. Such as rules, replacementRules, ...
 
 @return a set of strings corresponding to fractal production generation key paths effecting the graphic views.
 */
+(NSSet*) productionRuleProperties;
/*!
 A set of fractal property paths which effect the appearance of the final fractal generation. Such as color, stroke, ...
 
 @return a set of strings corresponding to fractal drawing key paths effecting the graphic views.
 */
+(NSSet*) appearanceProperties;
/*!
 A set of fractal property paths which only effect drawing of the line segments. Meaning neither the production nor the segment deneration are effect.
 
 @return a set of property path strings.
 */
+(NSSet*) redrawProperties;
/*!
 NSString for startingRules property to be used for KVO
 
 @return NSString representing the startingRules property
 */
+(NSString*) startingRulesKey;
/*!
 NSString for replacementRules property to be used for KVO
 
 @return NSString representing the replacementRules property
 */
+(NSString*) replacementRulesKey;
/*!
 NSString for lineColors property to be used for KVO
 
 @return NSString representing the lineColors property
 */
+(NSString*) lineColorsKey;
/*!
 NSString for fillColors property to be used for KVO
 
 @return NSString representing the fillColors property
 */
+(NSString*) fillColorsKey;

-(CGFloat)minValueForProperty: (NSString*)propertyKey;
-(CGFloat)maxValueForProperty: (NSString*)propertyKey;

-(void) generateLevelData;



@end