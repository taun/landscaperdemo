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

@interface MDBProductWithImage : NSObject

@property(nonatomic,strong)SKProduct            *product;
@property(nonatomic,strong)UIImage              *image;
@property(nonatomic,weak) MDBPurchaseManager    *purchaseManager;
@property(readonly)NSString                     *localizedPriceString;

+(instancetype)newWithProduct: (SKProduct*)product image:(UIImage*)image;
-(instancetype)initWithProduct: (SKProduct*)product image:(UIImage*)image;

@end
