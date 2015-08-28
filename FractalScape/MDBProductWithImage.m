//
//  MDBProductWithImage.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/27/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBProductWithImage.h"
#import "MDBPurchaseManager.h"

@interface MDBProductWithImage ()

@property(readonly)NSNumberFormatter        *priceFormatter;

@end

@implementation MDBProductWithImage

@synthesize priceFormatter = _priceFormatter;

+(instancetype)newWithProduct: (SKProduct*)product image:(UIImage*)image
{
    return [[MDBProductWithImage alloc] initWithProduct: product image: image];
}

-(instancetype)initWithProduct: (SKProduct*)product image:(UIImage*)image
{
    self = [super init];
    if (self) {
        _product = product;
        _image = image;
    }
    return self;
}

-(NSString *)localizedPriceString
{
    self.priceFormatter.locale = self.product.priceLocale;
    return [self.priceFormatter stringFromNumber: self.product.price];
}

#pragma mark - Utility
-(NSNumberFormatter *)priceFormatter
{
    if (_priceFormatter)
    {
        _priceFormatter = [NSNumberFormatter new];
        [_priceFormatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
        [_priceFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    }
    
    return _priceFormatter;
}

@end
