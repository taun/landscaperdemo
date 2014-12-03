//
//  LSDrawingRule+addons.h
//  FractalScape
//
//  Created by Taun Chapman on 03/27/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "LSDrawingRule.h"
#import "MDBTileObjectProtocol.h"


@interface LSDrawingRule (addons) <MDBTileObjectProtocol>

+(LSDrawingRule*) findRuleWithType:(NSString *)ruleType productionString: (NSString*)production inContext: (NSManagedObjectContext*) context;


@property (nonatomic,readonly) BOOL     isDefaultObject;

-(UIImage*) asImage;

@end
