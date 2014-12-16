//
//  FractalScapeIconSet.h
//  FractalScape
//
//  Created by Taun Chapman on 12/16/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface FractalScapeIconSet : NSObject

// iOS Controls Customization Outlets
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* tabBarLineColorIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* tabBarFillColorIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* tabBarLinePropertiesIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* tabBarRulesIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* tabBarPageColorIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* toolBarCopyIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* toolBarAppearanceIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleDrawLineTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleMoveByLineTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleDrawDotTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleDecrementLineWidthTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleIncrementLineWidthTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleOpenPolygonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleClosePolygonTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleDecrementAngleTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleIncrementAngleTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleRotateCTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleRotateCCTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRulePushTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRulePopTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleSwapRotationTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleReverseDirectionTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleFillOnTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleFillOffTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleUpscaleLineLengthTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleDownscaleLineLengthTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleStrokeOffTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleStrokeOnTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleRandomizeOffTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleRandomizeOnTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRulePlace0Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRulePlace1Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kbIconRulePlace2Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRulePlace3Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRulePlace4Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRulePlace5Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRulePlaceEmptyTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kPathArrowTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* controlDragCircleTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* iPad76Targets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* iPad2xTargets;

// Colors
+ (UIColor*)symbolFillColor;
+ (UIColor*)white5050;
+ (UIColor*)transformActionColor;
+ (UIColor*)groupBorderColor;
+ (UIColor*)selectionBackgrundColor;

// Drawing Methods
+ (void)drawTabBarLineColorIcon;
+ (void)drawTabBarFillColorIcon;
+ (void)drawTabBarLinePropertiesIcon;
+ (void)drawTabBarRulesIcon;
+ (void)drawTabBarPageColorIcon;
+ (void)drawToolBarCopyIcon;
+ (void)drawToolBarAppearanceIcon;
+ (void)drawToolBarFullScreenIcon;
+ (void)drawToolBarHUDScreenIconOld;
+ (void)drawToolBarFullScreenIcon2;
+ (void)drawToolBarHUDScreenIcon2;
+ (void)drawKBIconRuleDrawLine;
+ (void)drawKBIconRuleMoveByLine;
+ (void)drawKBIconRuleDrawDot;
+ (void)drawKBIconRuleDecrementLineWidth;
+ (void)drawKBIconRuleIncrementLineWidth;
+ (void)drawKBIconRuleOpenPolygon;
+ (void)drawKBIconRuleClosePolygon;
+ (void)drawKBIconRuleDecrementAngle;
+ (void)drawKBIconRuleIncrementAngle;
+ (void)drawKBIconRuleRotateC;
+ (void)drawKBIconRuleRotateCC;
+ (void)drawKBIconRulePush;
+ (void)drawKBIconRulePop;
+ (void)drawKBIconRuleSwapRotation;
+ (void)drawKBIconRuleReverseDirection;
+ (void)drawKBIconRuleFillOn;
+ (void)drawKBIconRuleFillOff;
+ (void)drawKBIconRuleUpscaleLineLength;
+ (void)drawKBIconRuleDownscaleLineLength;
+ (void)drawKBIconRuleStrokeOff;
+ (void)drawKBIconRuleStrokeOn;
+ (void)drawKBIconRuleRandomizeOff;
+ (void)drawKBIconRuleRandomizeOn;
+ (void)drawKBIconRulePlace0;
+ (void)drawKBIconRulePlace1;
+ (void)drawKbIconRulePlace2;
+ (void)drawKBIconRulePlace3;
+ (void)drawKBIconRulePlace4;
+ (void)drawKBIconRulePlace5;
+ (void)drawElements;
+ (void)drawKBIconRuleDrawDotFilled;
+ (void)drawKBIconRuleNextColor;
+ (void)drawKBIconRulePreviousColor;
+ (void)drawKBIconRulePlaceEmpty;
+ (void)drawKBIconRuleNextFillColor;
+ (void)drawKBIconRulePreviousFillColor;
+ (void)drawKBIconRuleDrawLineVarD;
+ (void)drawKBIconRuleSymbolArrowHead;
+ (void)drawKPathArrow;
+ (void)drawLineEditControllerWithFrame: (CGRect)frame;
+ (void)drawKCGLineCapSquareIcon;
+ (void)drawKCGLineCapRoundIcon;
+ (void)drawKCGLineCapButtIcon;
+ (void)drawKCGLineJoinBevelIcon;
+ (void)drawKCGLineJoinRoundIcon;
+ (void)drawKCGLineJoinMiterIcon;
+ (void)drawControlDragCircle;

// Generated Images
+ (UIImage*)imageOfTabBarLineColorIcon;
+ (UIImage*)imageOfTabBarFillColorIcon;
+ (UIImage*)imageOfTabBarLinePropertiesIcon;
+ (UIImage*)imageOfTabBarRulesIcon;
+ (UIImage*)imageOfTabBarPageColorIcon;
+ (UIImage*)imageOfToolBarCopyIcon;
+ (UIImage*)imageOfToolBarAppearanceIcon;
+ (UIImage*)imageOfKBIconRuleDrawLine;
+ (UIImage*)imageOfKBIconRuleMoveByLine;
+ (UIImage*)imageOfKBIconRuleDrawDot;
+ (UIImage*)imageOfKBIconRuleDecrementLineWidth;
+ (UIImage*)imageOfKBIconRuleIncrementLineWidth;
+ (UIImage*)imageOfKBIconRuleOpenPolygon;
+ (UIImage*)imageOfKBIconRuleClosePolygon;
+ (UIImage*)imageOfKBIconRuleDecrementAngle;
+ (UIImage*)imageOfKBIconRuleIncrementAngle;
+ (UIImage*)imageOfKBIconRuleRotateC;
+ (UIImage*)imageOfKBIconRuleRotateCC;
+ (UIImage*)imageOfKBIconRulePush;
+ (UIImage*)imageOfKBIconRulePop;
+ (UIImage*)imageOfKBIconRuleSwapRotation;
+ (UIImage*)imageOfKBIconRuleReverseDirection;
+ (UIImage*)imageOfKBIconRuleFillOn;
+ (UIImage*)imageOfKBIconRuleFillOff;
+ (UIImage*)imageOfKBIconRuleUpscaleLineLength;
+ (UIImage*)imageOfKBIconRuleDownscaleLineLength;
+ (UIImage*)imageOfKBIconRuleStrokeOff;
+ (UIImage*)imageOfKBIconRuleStrokeOn;
+ (UIImage*)imageOfKBIconRuleRandomizeOff;
+ (UIImage*)imageOfKBIconRuleRandomizeOn;
+ (UIImage*)imageOfKBIconRulePlace0;
+ (UIImage*)imageOfKBIconRulePlace1;
+ (UIImage*)imageOfKbIconRulePlace2;
+ (UIImage*)imageOfKBIconRulePlace3;
+ (UIImage*)imageOfKBIconRulePlace4;
+ (UIImage*)imageOfKBIconRulePlace5;
+ (UIImage*)imageOfKBIconRulePlaceEmpty;
+ (UIImage*)imageOfKPathArrow;
+ (UIImage*)imageOfLineEditControllerWithFrame: (CGRect)frame;
+ (UIImage*)imageOfControlDragCircle;
+ (UIImage*)imageOfIPad76;
+ (UIImage*)imageOfIPad2x;

@end
