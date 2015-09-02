//
//  MDBProductWithImage.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/27/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBBasePurchaseableProduct.h"
#import "MDBPurchaseManager.h"

@interface MDBBasePurchaseableProduct ()

@property(readonly)NSNumberFormatter        *priceFormatter;
@property (nonatomic,readonly) id            keyValueStorage;

@end

@implementation MDBBasePurchaseableProduct

@synthesize priceFormatter = _priceFormatter;

+(instancetype)newWithProductIdentifier: (NSString*)productID image:(UIImage*)image
{
    return [[[self class] alloc] initWithProductIdentifier: productID image: image];
}

-(NSInteger)storeClassIndex
{
    return 100;
}

-(instancetype)initWithProductIdentifier: (NSString*)productID image:(UIImage*)image
{
    self = [super init];
    if (self) {
        _productIdentifier = productID;
        _image = image;
    }
    return self;
}

-(id)keyValueStorage
{
    id storage = [NSUbiquitousKeyValueStore defaultStore];
    if (!storage)
    {
        storage = [NSUserDefaults standardUserDefaults];
    }
    return storage;
}

-(BOOL)processPurchase
{
    
    [self.keyValueStorage setObject: nil forKey: self.receiptStorageKeyString];
    
    return NO;
}

-(NSString *)receiptStorageKeyString
{
    NSString* prefixedString = [NSString stringWithFormat: @"receipt.%@",self.productIdentifier];
    return prefixedString;
}

-(BOOL)hasReceipt
{
    return [self.keyValueStorage arrayForKey: self.receiptStorageKeyString];
}


-(NSString *)localizedPriceString
{
    self.priceFormatter.locale = self.product.priceLocale;
    return [self.priceFormatter stringFromNumber: self.product.price];
}

#pragma mark - Utility
-(NSNumberFormatter *)priceFormatter
{
    if (!_priceFormatter)
    {
        _priceFormatter = [NSNumberFormatter new];
        [_priceFormatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
        [_priceFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    }
    
    return _priceFormatter;
}

@end
