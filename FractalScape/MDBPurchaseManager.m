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
#import "MDBProductWithImage.h"
#import "FractalScapeIconSet.h"

NSString* const  kPrefReceipts = @"com.moedae.FractalScapes.receipts";


@interface MDBPurchaseManager ()

@property (nonatomic,readonly) id                           keyValueStorage;

-(void)setReceipts: (NSArray*)receipts;
-(NSArray*)receipts;

-(void)validateProductIdentifiers:(NSArray*)productIdentifiers;

@end

@implementation MDBPurchaseManager


+(NSString*)premiumPurchaseID
{
    return @"com.moedae.FractalScapes.proupgrade";
}

+(UIImage*)premiumImage
{
    return [UIImage imageNamed: @""];
}

+(NSArray *)purchaseOptionIDs
{
    return @[[MDBPurchaseManager premiumPurchaseID]];
}

+(instancetype)newManagerWithModel:(MDBAppModel *)model
{
    return [[self alloc]initWithAppModel: model];
}

- (instancetype)initWithAppModel: (MDBAppModel*)model
{
    self = [super init];
    if (self) {
        _appModel = model;
        [[SKPaymentQueue defaultQueue]addTransactionObserver: self];
        [self validateProductIdentifiers: [[self class]purchaseOptionIDs]];
    }
    return self;
}

#pragma mark - Payment Processing

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


-(void)addReceipt: (NSData*)newReceipt
{
    NSArray* savedReceipts = self.receipts;
    if (!savedReceipts)
    {
        [self setReceipts: @[newReceipt]];
    }
    else
    {
        NSArray* updatedReceipts = [savedReceipts arrayByAddingObject: newReceipt];
        [self setReceipts: updatedReceipts];
    }

}

#pragma mark - Getters & Setters

-(id)keyValueStorage
{
    id storage = [NSUbiquitousKeyValueStore defaultStore];
    if (!storage)
    {
        storage = [NSUserDefaults standardUserDefaults];
    }
    return storage;
}

-(void)setReceipts: (NSArray*)receipts
{
    [self.keyValueStorage setObject: receipts forKey: kPrefReceipts];
}

-(NSArray *)receipts
{
    return [self.keyValueStorage arrayForKey: kPrefReceipts];
}

-(BOOL)isPremiumPaidFor
{
    return NO;
}


#pragma mark - SKProducsRequestDelegate
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSMutableArray* productsArray = [NSMutableArray arrayWithCapacity: response.products.count];
    
    for (SKProduct* product in response.products)
    {
        UIImage* image;
        if ([product.productIdentifier isEqualToString: [[self class]premiumPurchaseID]])
        {
            image = [FractalScapeIconSet imageOfPremiumUpgradeImage];
        }
        MDBProductWithImage* pwm = [MDBProductWithImage newWithProduct: product image: image];
        pwm.purchaseManager = self;
        [productsArray addObject: pwm];
    }
    
    self.validProductsWithImages = [productsArray copy];
    // update view controller via observer
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
    // set state and update view controller through observers
}

-(void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    
}


@end
