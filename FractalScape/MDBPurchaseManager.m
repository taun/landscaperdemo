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

#include <openssl/objects.h>
#include <openssl/pkcs7.h>
#include <openssl/x509.h>

@interface MDBPurchaseManager ()

@property (nonatomic,readonly) id                           keyValueStorage;
@property (nonatomic,assign,readwrite) BOOL                 isColorPakAvailable;
@property (nonatomic,strong) MDBProPurchaseableProduct      *proPak;

-(void)validateProductIdentifiers:(NSSet*)productIdentifiers;

@end

@implementation MDBPurchaseManager

@synthesize possiblePurchaseableProducts = _possiblePurchaseableProducts;
@synthesize validAppReceiptFound = _validAppReceiptFound;

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
        colorProduct.resourcePListName = @"MBColorsList_aluminum1";
        colorProduct.purchaseManager = self;
        
        _possiblePurchaseableProducts = [NSSet setWithObjects: _proPak,colorProduct, nil];
        
        [self receiptsOnboard];
        
        [[SKPaymentQueue defaultQueue]addTransactionObserver: self];
        [self revalidateProducts];
    }
    return self;
}

-(void)receiptsOnboard
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSURL *myURL = [mainBundle appStoreReceiptURL];
    NSError *myError;
    BOOL isPresent = [myURL checkResourceIsReachableAndReturnError: &myError];
    if (isPresent) {
        // Validate
        [self validateMeAtURL: myURL];
    }
    else
    {
        // no receipt
        [self refreshReceiptOnce];
    }
    
}

-(void)validateMeAtURL:(NSURL*)myURL
{
    // @"PommeDeTer" @"cer"
    PKCS7 *receiptPKCS7;
    
    { // receipt package
      // FractalScapes receipt file
        NSData *frData = [NSData dataWithContentsOfURL: myURL];
        
        BIO *receiptBIO = BIO_new(BIO_s_mem());
        BIO_write(receiptBIO, [frData bytes], (int) [frData length]);
        receiptPKCS7 = d2i_PKCS7_bio(receiptBIO, NULL);
        //    PKCS7
        if (!receiptPKCS7) {
            // Validation fails
            [self refreshReceiptOnce];
            return;
        }
        
        // Check that the container has a signature
        if (!PKCS7_type_is_signed(receiptPKCS7)) {
            // Validation fails
            [self refreshReceiptOnce];
            return;
        }
        
        // Check that the signed container has actual data
        if (!PKCS7_type_is_data(receiptPKCS7->d.sign->contents)) {
            // Validation fails
            [self refreshReceiptOnce];
            return;
        }
    }
    { // certificate package
      // Apple Root Certificate
        NSURL *arURL = [[NSBundle mainBundle] URLForResource:@"PommeDeTer" withExtension:@"cer"];
        NSData *arData = [NSData dataWithContentsOfURL: arURL];
        
        BIO *appleRootBIO = BIO_new(BIO_s_mem());
        BIO_write(appleRootBIO, (const void *) [arData bytes], (int) [arData length]);
        X509 *appleRootX509 = d2i_X509_bio(appleRootBIO, NULL);
        
        // Create a certificate store
        X509_STORE *store = X509_STORE_new();
        X509_STORE_add_cert(store, appleRootX509);
        
        // Be sure to load the digests before the verification
        OpenSSL_add_all_digests();
        
        // Check the signature
        int result = PKCS7_verify(receiptPKCS7, NULL, store, NULL, NULL, 0);
        if (result != 1) {
            // Validation fails
            [self refreshReceiptOnce];
            return;
        }
    }
    // have valid receipt container and signature
    // time to get attributes
    NSString *bundleIdString = nil;
    NSString *bundleVersionString = nil;
    NSData *bundleIdData = nil;
    NSData *hashData = nil;
    NSData *opaqueData = nil;
    NSData *iapData = nil;
    NSDate *expirationDate = nil;
    {
        // Get a pointer to the ASN.1 payload
        ASN1_OCTET_STRING *octets = receiptPKCS7->d.sign->contents->d.data;
        const unsigned char *ptr = octets->data;
        const unsigned char *end = ptr + octets->length;
        const unsigned char *str_ptr;
        
        int type = 0, str_type = 0;
        int xclass = 0, str_xclass = 0;
        long length = 0, str_length = 0;
        
        // Store for the receipt information
        
        // Date formatter to handle RFC 3339 dates in GMT time zone
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        // Decode payload (a SET is expected)
        ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
        if (type != V_ASN1_SET) {
            // Validation fails
            [self refreshReceiptOnce];
            return;
        }
        
        while (ptr < end) {
            ASN1_INTEGER *integer;
            
            // Parse the attribute sequence (a SEQUENCE is expected)
            ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
            if (type != V_ASN1_SEQUENCE) {
                // Validation fails
                [self refreshReceiptOnce];
                return;
            }
            
            const unsigned char *seq_end = ptr + length;
            long attr_type = 0;
            long attr_version = 0;
            
            // Parse the attribute type (an INTEGER is expected)
            ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
            if (type != V_ASN1_INTEGER) {
                // Validation fails
                [self refreshReceiptOnce];
                return;
            }
            integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
            attr_type = ASN1_INTEGER_get(integer);
            ASN1_INTEGER_free(integer);
            
            // Parse the attribute version (an INTEGER is expected)
            ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
            if (type != V_ASN1_INTEGER) {
                // Validation fails
                [self refreshReceiptOnce];
                return;
            }
            integer = c2i_ASN1_INTEGER(NULL, &ptr, length);
            attr_version = ASN1_INTEGER_get(integer);
            ASN1_INTEGER_free(integer);
            
            // Check the attribute value (an OCTET STRING is expected)
            ASN1_get_object(&ptr, &length, &type, &xclass, end - ptr);
            if (type != V_ASN1_OCTET_STRING) {
                // Validation fails
                [self refreshReceiptOnce];
                return;
            }
            
            switch (attr_type) {
                case 2:
                    // Bundle identifier
                    str_ptr = ptr;
                    ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                    if (str_type == V_ASN1_UTF8STRING) {
                        // We store both the decoded string and the raw data for later
                        // The raw is data will be used when computing the GUID hash
                        bundleIdString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSUTF8StringEncoding];
                        bundleIdData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                    }
                    break;
                    
                case 3:
                    // Bundle version
                    str_ptr = ptr;
                    ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                    if (str_type == V_ASN1_UTF8STRING) {
                        // We store the decoded string for later
                        bundleVersionString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSUTF8StringEncoding];
                    }
                    break;
                    
                case 4:
                    // Opaque value
                    opaqueData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                    break;
                    
                case 5:
                    // Computed GUID (SHA-1 Hash)
                    hashData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                    break;
                    
                case 17:
                    // in-app purchases
                    // 1701 quantity, 02 identifier, 03 transactionId, 04 purchase date
                    iapData = [[NSData alloc] initWithBytes:(const void *)ptr length:length];
                    break;
                    
                case 21:
                    // Expiration date
                    str_ptr = ptr;
                    ASN1_get_object(&str_ptr, &str_length, &str_type, &str_xclass, seq_end - str_ptr);
                    if (str_type == V_ASN1_IA5STRING) {
                        // The date is stored as a string that needs to be parsed
                        NSString *dateString = [[NSString alloc] initWithBytes:str_ptr length:str_length encoding:NSASCIIStringEncoding];
                        expirationDate = [formatter dateFromString:dateString];
                    }
                    break;
                    
                    // You can parse more attributes...
                    
                default:
                    break;
            }
            
            // Move past the value
            ptr += length;
        }
        
        // Be sure that all information is present
        if (bundleIdString == nil ||
            bundleVersionString == nil ||
            opaqueData == nil ||
            hashData == nil) {
            // Validation fails
            [self refreshReceiptOnce];
            return;
        }
    }
    // Check the bundle identifier
#pragma message "UpdateForBuilds to build version before archiving"
    if (![bundleIdString isEqualToString: @"com.moedae.FractalScapes"])
    {
        // Validation fails
        [self refreshReceiptOnce];
        return;
    }
    
    // Check the bundle version
#pragma message "UpdateForBuilds to build version before archiving"
    if (![bundleVersionString isEqualToString: @"382"]) // bundleVersionString is build # not version
    {
        // Validation fails
        [self refreshReceiptOnce];
        return;
    }
    
    UIDevice *device = [UIDevice currentDevice];
    NSUUID *identifier = [device identifierForVendor];
    uuid_t uuid;
    [identifier getUUIDBytes:uuid];
    NSData *guidData = [NSData dataWithBytes:(const void *)uuid length:16];

    // hash calculation
    unsigned char hash[20];
    
    // Create a hashing context for computation
    SHA_CTX ctx;
    SHA1_Init(&ctx);
    SHA1_Update(&ctx, [guidData bytes], (size_t) [guidData length]);
    SHA1_Update(&ctx, [opaqueData bytes], (size_t) [opaqueData length]);
    SHA1_Update(&ctx, [bundleIdData bytes], (size_t) [bundleIdData length]);
    SHA1_Final(hash, &ctx);
    
    // Do the comparison
    NSData *computedHashData = [NSData dataWithBytes:hash length:20];
    if (![computedHashData isEqualToData:hashData])
    {
        // Validation fails
        [self refreshReceiptOnce];
        return;
    }
    
    _validAppReceiptFound = YES;
}


-(void)refreshReceiptOnce
{
    _validAppReceiptFound = NO;
    
    NSString* receiptCheckKey = @"com.moedae.FractalScapes.receiptLastCheckedDate";
    NSUserDefaults* storage = [NSUserDefaults standardUserDefaults];
    NSDate* lastDate = [storage objectForKey: receiptCheckKey];
    NSTimeInterval checkInterval = -60.0*60.0*12.0; // time in the past
    if (!lastDate || [lastDate timeIntervalSinceNow] < checkInterval) // more in the past than the interval
    {
        // time to try again
        [storage setObject: [NSDate date] forKey: receiptCheckKey];
        SKReceiptRefreshRequest* request = [[SKReceiptRefreshRequest alloc]init];
        request.delegate = self;
        [request start];
    }
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
    return self.proPak.hasReceipt;
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

-(void)requestDidFinish:(SKRequest *)request
{
    if (!_validAppReceiptFound)
    {
        [self receiptsOnboard];
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
