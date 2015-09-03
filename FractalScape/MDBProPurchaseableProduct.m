//
//  MDBProPurchaseableProduct.m
//  FractalScapes
//
//  Created by Taun Chapman on 09/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBProPurchaseableProduct.h"

@implementation MDBProPurchaseableProduct


-(NSInteger)storeClassIndex
{
    return 10;
}

-(BOOL)processPurchase: (NSDate*)date
{
    [super processPurchase: date];
    // over ride return since there is nothing to install
    return YES;
}

@end
