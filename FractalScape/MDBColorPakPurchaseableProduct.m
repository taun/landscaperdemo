//
//  MDBColorPakPurchaseableProduct.m
//  FractalScapes
//
//  Created by Taun Chapman on 09/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBColorPakPurchaseableProduct.h"

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
    
    self.resourcePListName;
    
    return YES;
}

@end
