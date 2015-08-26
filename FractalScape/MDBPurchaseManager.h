//
//  MDBPurchaseManager.h
//  FractalScapes
//
//  Created by Taun Chapman on 08/25/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MDBAppModel;

/*!
 This class handles the Apple in-app purchase details for the AppModel.
 */
@interface MDBPurchaseManager : NSObject <SKProductsRequestDelegate,SKPaymentTransactionObserver>

@property (nonatomic,weak) MDBAppModel                      *appModel;
@property (nonatomic,strong) NSArray                        *validProducts;

+(NSArray*)purchaseOptionIDs;

-(NSString*)stringForProductPrice: (SKProduct*)product;

-(void)processPaymentForProduct:(SKProduct*)product quantity: (NSUInteger)qty;

@end
