//
//  MDBPurchaseManager.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/25/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import StoreKit;

#import "MDBPurchaseManager.h"
#import "MDBAppModel.h"


@interface MDBPurchaseManager ()

@property (nonatomic,strong,readonly) NSNumberFormatter     *priceFormatter;

-(void)validateProductIdentifiers:(NSArray*)productIdentifiers;

@end

@implementation MDBPurchaseManager

@synthesize priceFormatter = _priceFormatter;


+(NSArray *)purchaseOptionIDs
{
    return @[@"com.moedae.fractalscapes.proupgrade"];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue]addTransactionObserver: self];
    }
    return self;
}

-(void)validateProductIdentifiers:(NSArray *)productIdentifiers
{
    SKProductsRequest* productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers: [NSSet setWithArray: [[self class] purchaseOptionIDs]]];
    productsRequest.delegate = self;
    [productsRequest start];
}

-(BOOL)userCanMakePayments
{
    return [SKPaymentQueue canMakePayments];
}

-(void)processPaymentForProduct:(SKProduct *)product quantity:(NSUInteger)qty
{
    SKMutablePayment* payment = [SKMutablePayment paymentWithProduct: product];
    payment.quantity = qty;
    [[SKPaymentQueue defaultQueue] addPayment: payment];
}

#pragma mark - SKProducsRequestDelegate
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    self.validProducts = response.products;
    // Show updated list of products
}

#pragma mark - PaymentTransactionsObserver

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction* transaction in transactions)
    {
        SKPaymentTransactionState state = transaction.transactionState;
        if (state == SKPaymentTransactionStatePurchased)
        {
            // enable allowPremium
        }
        else if (state == SKPaymentTransactionStatePurchasing)
        {
            // update UI
        }
        else if (state == SKPaymentTransactionStateFailed)
        {
            // update UI
        }
        else if (state == SKPaymentTransactionStateRestored)
        {
            // restore allowPremium
        }
    }
}

-(void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    
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

-(NSString *)stringForProductPrice:(SKProduct *)product
{
    self.priceFormatter.locale = product.priceLocale;
    return [self.priceFormatter stringFromNumber: product.price];
}

@end
