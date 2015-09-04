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
#import "NSString+MDKConvenience.h"

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
@property (nonatomic, assign) CGFloat       lineChangeFactor; // this is used
@property (nonatomic, assign) CGFloat       lineLength;
@property (nonatomic, assign) CGFloat       lineLengthScaleFactor;
@property (nonatomic, assign) CGFloat       lineWidth;
#pragma message "REMOVE: lineWidthIncrement"
/*!
 percent change in width for each incidence of the lineWidthIncrement rule.
 */
@property (nonatomic, assign) CGFloat       lineWidthIncrement; // no longer used
@property (nonatomic, assign) CGFloat       randomness;
@property (nonatomic, assign) CGFloat       turningAngle;
/*!
 percent change in angle for each incidence of the turningAngleIncrement rule.
 */
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
@property (nonatomic, assign) CGFloat       lineHueRotationPercent;
@property (nonatomic, assign) CGFloat       fillHueRotationPercent;
@property (nonatomic, assign) CGFloat       lineSaturationRotationPercent;
@property (nonatomic, assign) CGFloat       fillSaturationRotationPercent;
@property (nonatomic, assign) CGFloat       lineBrightnessRotationPercent;
@property (nonatomic, assign) CGFloat       fillBrightnessRotationPercent;

/*!
 Transform the startingRules into the equivalent string
 */
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString               *startingRulesAsString;
/*!
 Transform the replacements rules into a dictionary.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) NSDictionary                 *replacementRulesDictionary;
/*!
 Lazily create and return the level 0 rules.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) NSData                       *level0Rules;
/*!
 Lazily create and return the level 1 rules.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) NSData                       *level1Rules;
/*!
 Lazily create and return the level 2 rules.
 */
@property (NS_NONATOMIC_IOSONLY, readonly) NSData                       *level2Rules;
/*!
 Lazily create and return the level N rules.
 Creating the level N rules always creates the 0-2 rules as well.
 */
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
/*!
 Way of encoding the ranges for properties to be used in UI elements like sliders
 
 @param propertyKey the property to look up
 
 @return the min desired value
 */
-(CGFloat)minValueForProperty: (NSString*)propertyKey;
/*!
 Way of encoding the ranges for properties to be used in UI elements like sliders
 
 @param propertyKey the property to look up
 
 @return the max desired value
 */
-(CGFloat)maxValueForProperty: (NSString*)propertyKey;
/*!
 Way of encoding the ranges for properties to be used in UI elements like sliders
 
 @param propertyKey the property to look up
 
 @return if the property is an angle
 */
-(BOOL)isAngularProperty: (NSString*)propertyKey;

/*!
 Generates and caches the level data if the rules have changed or the level has changed.
 */
-(void) generateLevelData;
/*!
 When adding the first item to the filters list, would like to be able turn on apply filters without triggering notifications
 for both the change to the filters list AND the change in applyFilters. This method is used to turn applyFilters back on 
 whenever an item is added or removed from the filters list when applyFilters had been off.
 
 There should be a custom method for setting/getting the filters object list and this should only be called there but...
 */
-(void)updateApplyFiltersWithoutNotificationForFiltersListChange;

@end