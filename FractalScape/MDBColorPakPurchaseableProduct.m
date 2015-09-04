//
//  MDBColorPakPurchaseableProduct.m
//  FractalScapes
//
//  Created by Taun Chapman on 09/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBColorPakPurchaseableProduct.h"
#import "MDBAppModel.h"
#import "MDBPurchaseManager.h"

@implementation MDBColorPakPurchaseableProduct

-(NSInteger)storeClassIndex
{
    return 20;
}


-(BOOL)processPurchase: (NSDate*)date
{
    [super processPurchase: date];
    // over ride return since there is nothing to install
    // need to install color pak
    
    return YES;
}

-(BOOL)loadContent
{
    if (!self.isContentLoaded)
    {
        BOOL success = [self.purchaseManager.appModel loadAdditionalColorsFromPlistFileNamed: self.resourcePListName];
        NSLog(@"FractalScapes loading additonal content %@",self.productIdentifier);
        
        if (success)
        {
            [super loadContent];
        }
    }
    
    return self.isContentLoaded;
}
@end
