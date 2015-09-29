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


-(void)validReceiptFoundForDate: (NSDate*)date
{
    [super validReceiptFoundForDate: date];
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
