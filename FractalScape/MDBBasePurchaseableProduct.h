//
//  MDBProductWithImage.h
//  FractalScapes
//
//  Created by Taun Chapman on 08/27/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import StoreKit;

@class  MDBPurchaseManager;

@interface MDBBasePurchaseableProduct : NSObject

@property(nonatomic,strong)NSString             *productIdentifier;
@property(nonatomic,strong)SKProduct            *product;
@property(nonatomic,strong)UIImage              *image;
@property(nonatomic,weak) MDBPurchaseManager    *purchaseManager;
@property(atomic,readonly)NSString              *localizedPriceString;
@property(atomic,readonly)NSString              *localizedStoreButtonString;

@property(readonly)BOOL                         canBuy;
@property(readonly)BOOL                         canRestore;
/*!
 A purchase transaction for this product has been completed on this device or an iCloud connected device.
 */
@property(readonly)BOOL                         hasLocalReceipt;
/*!
 The device app receipt processing has indicated there is a receipt for this product. If there is no hasLocalReceipt,
 then a restore option needs to be presented. 
 */
@property(readonly)BOOL                         hasAppReceipt;
@property(readonly)NSInteger                    storeClassIndex;
@property(readonly)SKPaymentTransactionState    transactionState;
@property(readonly)BOOL                         isContentLoaded;

+(instancetype)newWithProductIdentifier: (NSString*)productID image:(UIImage*)image;
-(instancetype)initWithProductIdentifier: (NSString*)productID image:(UIImage*)image;

/*!
 Simply sets the hasAppReceipt property. Usually set at init of the purchase manager.
 
 Does not load content. Content is loaded by manager if hasLocalReceipt is YES.
 
 Feature is enabled if hasLocalReceipt is YES.
 
 This is used to trigger the Restore option.

 @param date of past transaction
*/
-(void)validReceiptFoundForDate:(NSDate*)date;

/*!
 Method to override for classes which load content.
 
 Only call super if the content loading was successful.
 
 @return value of _isContentLoaded set to YES
 */
-(BOOL)loadContent;

-(NSString*)receiptStorageKeyString;

-(void)setCurrentTransaction:(SKPaymentTransaction*)transaction;

@end
