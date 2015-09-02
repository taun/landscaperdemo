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
#import "MDBBasePurchaseableProduct.h"
#import "MDBColorPakPurchaseableProduct.h"
#import "MDBProPurchaseableProduct.h"

#import "FractalScapeIconSet.h"


@interface MDBPurchaseManager ()

@property (nonatomic,readonly) id                           keyValueStorage;
@property (nonatomic,assign,readwrite) BOOL                 isColorPakAvailable;
@property (nonatomic,strong) MDBProPurchaseableProduct      *proPak;

-(void)validateProductIdentifiers:(NSSet*)productIdentifiers;

@end

@implementation MDBPurchaseManager

@synthesize possiblePurchaseableProducts = _possiblePurchaseableProducts;


+(instancetype)newManagerWithModel:(MDBAppModel *)model
{
    return [[self alloc]initWithAppModel: model];
}

- (instancetype)initWithAppModel: (MDBAppModel*)model
{
    self = [super init];
    if (self) {
        _appModel = model;
        
        _proPak = [MDBProPurchaseableProduct newWithProductIdentifier: @"com.moedae.FractalScapes.premiumpak" image: [UIImage imageNamed: @"purchasePremiumPakPortrait"]];
        _proPak.purchaseManager = self;
        
        MDBColorPakPurchaseableProduct* colorProduct = [MDBColorPakPurchaseableProduct newWithProductIdentifier: @"com.moedae.FractalScapes.colors.aluminum1" image: [UIImage imageNamed: @"purchaseColorsAluminum1Portrait"]];
        colorProduct.purchaseManager = self;
        
        _possiblePurchaseableProducts = [NSSet setWithObjects: _proPak,colorProduct, nil];
        
        [[SKPaymentQueue defaultQueue]addTransactionObserver: self];
        [self revalidateProducts];
    }
    return self;
}

-(NSSet *)purchaseOptionIDs
{
    NSMutableSet* ids = [NSMutableSet setWithCapacity: self.possiblePurchaseableProducts.count];
    for (MDBBasePurchaseableProduct* baseProduct in self.possiblePurchaseableProducts)
    {
        [ids addObject: baseProduct.productIdentifier];
    }
    return [ids copy];
}

-(MDBBasePurchaseableProduct *)baseProductForIdentifier:(NSString *)id
{
    MDBBasePurchaseableProduct* found;
    
    for (MDBBasePurchaseableProduct* baseProduct in self.possiblePurchaseableProducts)
    {
        if ([baseProduct.productIdentifier isEqualToString: id])
        {
            found = baseProduct;
            break;
        }
    }
    
    return found;
}

#pragma mark - Payment Processing

-(void)revalidateProducts
{
    [self validateProductIdentifiers: self.purchaseOptionIDs];
}

-(void)validateProductIdentifiers:(NSSet *)productIdentifiers
{
    SKProductsRequest* productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers: productIdentifiers];
    productsRequest.delegate = self;
    [productsRequest start];
}

-(NSArray *)sortedValidPurchaseableProducts
{
    NSSortDescriptor* byType = [NSSortDescriptor sortDescriptorWithKey: @"storeClassIndex" ascending: YES];
    NSSortDescriptor* byID = [NSSortDescriptor sortDescriptorWithKey: @"productIdentifier" ascending: YES];
    
    NSArray* sortedProducts = [self.validPurchaseableProducts sortedArrayUsingDescriptors: @[byType, byID]];
    return sortedProducts;
}

-(BOOL)userCanMakePayments
{
    return [SKPaymentQueue canMakePayments];
}

-(void)processPaymentForProduct:(SKProduct *)product quantity:(NSUInteger)qty
{
    NSLog(@"Process payment");
    SKMutablePayment* payment = [SKMutablePayment paymentWithProduct: product];
    payment.quantity = qty;
    [[SKPaymentQueue defaultQueue] addPayment: payment];
}


#pragma mark - Getters & Setters

-(BOOL)isPremiumPaidFor
{
    return NO;
}

-(BOOL)isColorPakAvailable
{
    NSSet* colorPaks = [self.validPurchaseableProducts objectsPassingTest:^BOOL(MDBBasePurchaseableProduct *obj, BOOL *stop) {
        BOOL pass = NO;
        if ([obj isMemberOfClass: [MDBColorPakPurchaseableProduct class]] && !obj.hasReceipt) {
            pass = YES;
        }
        return pass;
    }];
    return colorPaks.count > 0;
}

#pragma mark - SKProducsRequestDelegate
-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSMutableSet* products = [NSMutableSet setWithCapacity: response.products.count];
    
    for (SKProduct* product in response.products)
    {
        MDBBasePurchaseableProduct* baseProduct = [self baseProductForIdentifier: product.productIdentifier];
        if (baseProduct)
        {
            baseProduct.product = product;
            [products addObject: baseProduct];
        }
    }
    
    self.validPurchaseableProducts = [products copy];
    [self.delegate productsChanged];
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
            MDBBasePurchaseableProduct* baseProduct = [self baseProductForIdentifier: transaction.payment.productIdentifier];
            if (baseProduct && [baseProduct processPurchase])
            {
                [queue finishTransaction: transaction];
            }
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
