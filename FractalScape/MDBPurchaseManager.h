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
@class MDBBasePurchaseableProduct;
@class MDBColorPakPurchaseableProduct;
@class MDBProPurchaseableProduct;

@protocol PurchaseManagerDelegate <NSObject>

-(void) productsChanged;

@end

/*!
 This class handles the Apple in-app purchase details for the AppModel.
 */
@interface MDBPurchaseManager : NSObject <SKProductsRequestDelegate,SKPaymentTransactionObserver>

@property (nonatomic,weak) MDBAppModel                      *appModel;
@property (nonatomic,readonly) BOOL                         validAppReceiptFound;
@property (nonatomic,readonly)NSSet                         *possiblePurchaseableProducts;
@property (nonatomic,strong) NSSet                          *validPurchaseableProducts;
@property (nonatomic,readonly) BOOL                         isPremiumPaidFor;
@property (nonatomic,readonly) BOOL                         isColorPakAvailable;
@property (nonatomic,assign,readonly) BOOL                  userCanMakePayments;
@property (nonatomic,assign,readonly) BOOL                  areThereProductsToBuyOrRestore;
@property (nonatomic,weak) id<PurchaseManagerDelegate>      delegate;

@property (nonatomic,readonly) MDBProPurchaseableProduct      *proPak;
@property (nonatomic,readonly) MDBColorPakPurchaseableProduct *colorPak1;

+(instancetype)newManagerWithModel:(MDBAppModel*)model;

-(void)processPaymentForProduct:(SKProduct*)product quantity: (NSUInteger)qty;

-(MDBBasePurchaseableProduct*)baseProductForIdentifier: (NSString*)id;

-(NSArray*)sortedValidPurchaseableProducts;

/*!
 Method to iterate through restorable purchases and restore them.
 */
-(void)updateAppReceipt;

@end
