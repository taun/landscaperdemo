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
@property(readonly)NSString                     *localizedPriceString;
@property(readonly)BOOL                         hasReceipt;
@property(readonly)NSInteger                    storeClassIndex;
@property(readonly)SKPaymentTransactionState    transactionState;
@property(readonly)BOOL                         isContentLoaded;

+(instancetype)newWithProductIdentifier: (NSString*)productID image:(UIImage*)image;
-(instancetype)initWithProductIdentifier: (NSString*)productID image:(UIImage*)image;

/*!
 Handle purchase by enabling feature or installing content.
 Will need to be overridden by subclass.
 
 Content is loaded as part of processPurchase: so it needs to be called at startup.
 
 @return if success for enabling or installing content
 */
-(BOOL)processPurchase:(NSDate*)date;

/*!
 Method to override for classes which load content.
 
 Only call super if the content loading was successful.
 
 @return value of _isContentLoaded set to YES
 */
-(BOOL)loadContent;

-(NSString*)receiptStorageKeyString;

-(void)setCurrentTransaction:(SKPaymentTransaction*)transaction;

@end
