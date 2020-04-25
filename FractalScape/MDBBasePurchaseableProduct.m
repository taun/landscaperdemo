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

@property(readonly)NSNumberFormatter            *priceFormatter;
@property (nonatomic,readonly) id               keyValueStorage;
@property(atomic,readwrite)NSString             *localizedStoreButtonString;
@property(atomic,readwrite)NSString             *localizedPriceString;
@property(readwrite)BOOL                         hasAppReceipt;

/*!
 A purchase has just been made, this is different from finding a purchase receipt.
 This will load content if necessary and persist the hasLocalReceipt property.
 
 @param date of transaction
 */
-(void)processPurchase: (NSDate*)date;

@end

@implementation MDBBasePurchaseableProduct

@synthesize priceFormatter = _priceFormatter;
@synthesize isContentLoaded = _isContentLoaded;
@synthesize localizedStoreButtonString = _localizedStoreButtonString;
@synthesize localizedPriceString = _localizedPriceString;
@synthesize hasAppReceipt = _hasAppReceipt;


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
        _transactionState = -1; // default value to know if the state is set

        if (self.hasLocalReceipt)
        {
            _localizedStoreButtonString = NSLocalizedString(@"Purchased", @"App store already purchased");
        }
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

-(BOOL)canBuy
{
    return !self.hasAppReceipt && !self.hasLocalReceipt;
}

-(BOOL)canRestore
{
    return self.hasAppReceipt && !self.hasLocalReceipt;
}

-(void)setProduct:(SKProduct *)product
{
    if (_product != product)
    {
        _product = product;
        
        if (!self.hasLocalReceipt && !self.hasAppReceipt)
        {
            if ([_product.price isEqualToNumber: [NSDecimalNumber numberWithDouble: 0.0]])
            {
                self.localizedStoreButtonString = NSLocalizedString(@"Get", @"App store Get");
            }
            else
            {
                self.localizedStoreButtonString = NSLocalizedString(@"Buy", @"App store Buy");
            }
        }
        
        self.priceFormatter.locale = _product.priceLocale;

        if ([_product.price isEqualToNumber: [NSDecimalNumber numberWithDouble: 0.0]])
        {
            self.localizedPriceString = NSLocalizedString(@"Free", @"App Price is free");
        }
        else
        {
            self.localizedPriceString = [self.priceFormatter stringFromNumber: _product.price];
        }
    }
}

-(void)setCurrentTransaction:(SKPaymentTransaction*)transaction
{
    SKPaymentTransactionState transactionState = transaction.transactionState;
    
    if (_transactionState != transactionState)
    {
        _transactionState = transactionState;
        
        
        switch (_transactionState) {
            case SKPaymentTransactionStatePurchasing:
                // no purchase
                self.localizedStoreButtonString = NSLocalizedString(@"Purchasing", @"App store purchasing");
                break;
                
            case SKPaymentTransactionStateDeferred:
                // no purchase
                self.localizedStoreButtonString = NSLocalizedString(@"Bought", @"App store deferred");
                break;
                
            case SKPaymentTransactionStatePurchased:
                // no purchase
                self.localizedStoreButtonString = NSLocalizedString(@"Purchased", @"App store just purchased");
                [self processPurchase: transaction.transactionDate];
                break;
                
            case SKPaymentTransactionStateRestored:
                // no purchase
                self.localizedStoreButtonString = NSLocalizedString(@"Restored", @"App store just restored");
                [self processPurchase: transaction.transactionDate];
                break;
                
            case SKPaymentTransactionStateFailed:
                // no purchase
                self.localizedStoreButtonString = NSLocalizedString(@"Failed", @"App store just failed");
                break;
                
            default:
                break;
        }
    }
}

-(void)processPurchase: (NSDate*)date
{
        [self.keyValueStorage setObject: date forKey: self.receiptStorageKeyString];
    
        NSLog(@"FractalScapes processing additonal content %@, receipt date %@",self.productIdentifier, date);
        [self loadContent];
}

-(void)validReceiptFoundForDate: (NSDate*)date
{
    self.hasAppReceipt = YES;

    [self loadContent];
}

-(BOOL)loadContent
{
    _isContentLoaded = YES;
    
    return _isContentLoaded;
}

-(NSString *)receiptStorageKeyString
{
    NSString* prefixedString = [NSString stringWithFormat: @"receipt.%@",self.productIdentifier];
    return prefixedString;
}

-(BOOL)hasLocalReceipt
{
    return [self.keyValueStorage objectForKey: self.receiptStorageKeyString] != nil;
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
