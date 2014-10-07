//
//  LSDrawingRule+addons.h
//  FractalScape
//
//  Created by Taun Chapman on 03/27/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "LSDrawingRule.h"

@interface LSDrawingRule (addons)

+(LSDrawingRule*) findRuleWithType:(NSString *)ruleType productionString: (NSString*)production inContext: (NSManagedObjectContext*) context;

-(UIImage*) asImage;

@end
