//
//  MDBPurchaseManager.h
//  FractalScapes
//
//  Created by Taun Chapman on 08/25/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import StoreKit;


@class MDBAppModel;

@protocol PurchaseManagerDelegate <NSObject>

-(void) productsChanged;

@end

/*!
 This class handles the Apple in-app purchase details for the AppModel.
 */
@interface MDBPurchaseManager : NSObject <SKProductsRequestDelegate,SKPaymentTransactionObserver>

@property (nonatomic,weak) MDBAppModel                      *appModel;
@property (nonatomic,strong) NSArray                        *validProductsWithImages;
@property (nonatomic,readonly) BOOL                         isPremiumPaidFor;
@property (nonatomic,readonly) BOOL                         userCanMakePayments;
@property (nonatomic,weak) id<PurchaseManagerDelegate>      delegate;

+(instancetype)newManagerWithModel:(MDBAppModel*)model;
-(void)validateProductIdentifiers:(NSSet*)productIdentifiers;

-(void)processPaymentForProduct:(SKProduct*)product quantity: (NSUInteger)qty;

@end
