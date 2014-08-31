//
//  FractalScapeIconSet.h
//  FractalScape
//
//  Created by Taun Chapman on 08/30/14.
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
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* toolBarCopyIconTargets;
@property(strong, nonatomic) IBOutletCollection(NSObject) NSArray* kBIconRuleFTargets;

// Drawing Methods
+ (void)drawTabBarLineColorIcon;
+ (void)drawTabBarFillColorIcon;
+ (void)drawTabBarLinePropertiesIcon;
+ (void)drawTabBarRulesIcon;
+ (void)drawToolBarCopyIcon;
+ (void)drawKBIconRuleF;

// Generated Images
+ (UIImage*)imageOfTabBarLineColorIcon;
+ (UIImage*)imageOfTabBarFillColorIcon;
+ (UIImage*)imageOfTabBarLinePropertiesIcon;
+ (UIImage*)imageOfTabBarRulesIcon;
+ (UIImage*)imageOfToolBarCopyIcon;
+ (UIImage*)imageOfKBIconRuleF;

@end