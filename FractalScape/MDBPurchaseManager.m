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
@property (nonatomic,strong) MDBColorPakPurchaseableProduct *colorPak1;

-(void)validateProductIdentifiers:(NSSet*)productIdentifiers;

@end

@implementation MDBPurchaseManager

@synthesize possiblePurchaseableProducts = _possiblePurchaseableProducts;
@synthesize validAppReceiptFound = _validAppReceiptFound;
@synthesize userCanMakePayments = _userCanMakePayments;

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
        
        _colorPak1 = [MDBColorPakPurchaseableProduct newWithProductIdentifier: @"com.moedae.FractalScapes.colors.aluminum1" image: [UIImage imageNamed: @"purchaseColorsAluminum1Portrait"]];
        _colorPak1.resourcePListName = @"MBColorsList_aluminum1";
        _colorPak1.purchaseManager = self;
        
        [_colorPak1 loadContent]; // give the user the benefit of the doubt
                
        [[SKPaymentQueue defaultQueue] addTransactionObserver: self];
    }
    return self;
}

-(BOOL)areThereProductsToBuyOrRestore
{
    BOOL areThere = NO;
    
    for (MDBBasePurchaseableProduct* product in self.possiblePurchaseableProducts)
    {
        if (product.canBuy || product.canRestore)
        {
            areThere = YES;
            break;
        }
    }
    return areThere;
}

-(void)dealloc
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver: self];
}


#pragma mark - Getters & Setters

-(BOOL)isPremiumPaidFor
{
    return YES;
}

-(BOOL)isColorPakAvailable
{
    NSSet* colorPaks = [self.validPurchaseableProducts objectsPassingTest:^BOOL(MDBBasePurchaseableProduct *obj, BOOL *stop) {
        BOOL pass = NO;
        if ([obj isMemberOfClass: [MDBColorPakPurchaseableProduct class]] && !obj.hasLocalReceipt) {
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

-(void)requestDidFinish:(SKRequest *)request
{
    if (!_validAppReceiptFound && ![request isMemberOfClass: [SKProductsRequest class]])
    {
        [self updateAppReceipt];
    }
}

#pragma mark - PaymentTransactionsObserver

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction* transaction in transactions)
    {
        MDBBasePurchaseableProduct* baseProduct = [self baseProductForIdentifier: transaction.payment.productIdentifier];

        SKPaymentTransactionState state = transaction.transactionState;
        
        switch (state) {
            case SKPaymentTransactionStatePurchased:
                [baseProduct setCurrentTransaction: transaction];
                [queue finishTransaction: transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [baseProduct setCurrentTransaction: transaction];
                [queue finishTransaction: transaction];
                break;
                
            case SKPaymentTransactionStatePurchasing:
                [baseProduct setCurrentTransaction: transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [baseProduct setCurrentTransaction: transaction];
                [queue finishTransaction: transaction];
               break;
                
            default:
                break;
        }
    }
    // set state and update view controller through observers
}

-(void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
}


@end
