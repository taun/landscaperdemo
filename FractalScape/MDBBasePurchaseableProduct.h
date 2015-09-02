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

+(instancetype)newWithProductIdentifier: (NSString*)productID image:(UIImage*)image;
-(instancetype)initWithProductIdentifier: (NSString*)productID image:(UIImage*)image;

/*!
 Handle purchase by enabling feature or installing content.
 Will need to be overridden by subclass.
 
 @return if success for enabling or installing content
 */
-(BOOL)processPurchase;

-(NSString*)receiptStorageKeyString;

@end
