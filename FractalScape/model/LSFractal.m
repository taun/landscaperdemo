//
//  LSFractal.m
//  FractalScape
//
//  Created by Taun Chapman on 02/05/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "LSFractal.h"
#import "LSDrawingRule.h"
#import "LSDrawingRuleType.h"
#import "LSReplacementRule.h"
#import "MBColor.h"
#import "MBPlacedEntity.h"


@implementation LSFractal

@dynamic baseAngle;
@dynamic category;
@dynamic descriptor;
@dynamic eoFill;
@dynamic isImmutable;
@dynamic isReadOnly;
@dynamic level;
@dynamic lineChangeFactor;
@dynamic lineLength;
@dynamic lineLengthScaleFactor;
@dynamic lineWidth;
@dynamic lineWidthIncrement;
@dynamic name;
@dynamic randomness;
@dynamic turningAngle;
@dynamic turningAngleIncrement;
@dynamic autoExpand;
@dynamic level0RulesCache;
@dynamic level1RulesCache;
@dynamic level2RulesCache;
@dynamic levelNRulesCache;
@dynamic levelGrowthRate;
@dynamic rulesUnchanged;
@dynamic levelUnchanged;
@dynamic backgroundColor;
@dynamic drawingRulesType;
@dynamic fillColors;
@dynamic lineColors;
@dynamic placements;
@dynamic replacementRules;
@dynamic startingRules;

@end
