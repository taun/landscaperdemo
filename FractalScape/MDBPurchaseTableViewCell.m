//
//  MDBPurchaseTableViewCell.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/27/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBPurchaseTableViewCell.h"
#import "MDBBasePurchaseableProduct.h"
#import "MDBPurchaseManager.h"

@interface MDBPurchaseTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *productImageView;
@property (weak, nonatomic) IBOutlet UILabel *productLabel;
@property (weak, nonatomic) IBOutlet UITextView *productDescription;

@property (weak, nonatomic) IBOutlet UIButton *buyButton;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;

- (IBAction)buyButtonTapped:(UIButton *)sender;

@end

@implementation MDBPurchaseTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

#pragma mark - Getters & Setters

-(void)setPurchaseableProduct:(MDBBasePurchaseableProduct *)productWithImage
{
    if (_purchaseableProduct != productWithImage)
    {
        [self removeProductObservers];
        _purchaseableProduct = productWithImage;
        [self addProductObservers];
    }
    
    [self updateValueDisplays];
}

-(void)addProductObservers
{
    if (_purchaseableProduct)
    {
        [_purchaseableProduct addObserver: self forKeyPath: @"transactionState" options: 0 context: NULL];
    }
}

-(void)removeProductObservers
{
    if (_purchaseableProduct)
    {
        [_purchaseableProduct removeObserver: self forKeyPath: @"transactionState"];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString: @"transactionState"])
    {
        [self updateBuyButtonStatus];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)updateValueDisplays
{
    self.productImageView.image = self.purchaseableProduct.image;
    self.productLabel.text = self.purchaseableProduct.product.localizedTitle;
    self.productDescription.text = self.purchaseableProduct.product.localizedDescription;
    [self updateBuyButtonStatus];
}

-(void)updateBuyButtonStatus
{
    self.buyButton.enabled = NO;
    
    if (_purchaseableProduct)
    {
        NSString* buttonTitle;
        
        if (self.purchaseableProduct.hasReceipt)
        {
            buttonTitle = NSLocalizedString(@"Purchased", @"App store already purchased");
        }
        else if (_purchaseableProduct.transactionState != -1)
        {
            SKPaymentTransactionState state = _purchaseableProduct.transactionState;

            switch (state) {
                case SKPaymentTransactionStatePurchasing:
                    // no purchase
                    buttonTitle = NSLocalizedString(@"Purchasing", @"App store purchasing");
                    break;
                    
                case SKPaymentTransactionStateDeferred:
                    // no purchase
                    buttonTitle = NSLocalizedString(@"Bought", @"App store deferred");
                    break;
                    
                case SKPaymentTransactionStatePurchased:
                    // no purchase
                    buttonTitle = NSLocalizedString(@"Purchased", @"App store just purchased");
                    break;
                    
                case SKPaymentTransactionStateRestored:
                    // no purchase
                    buttonTitle = NSLocalizedString(@"Restored", @"App store just restored");
                    break;
                    
                case SKPaymentTransactionStateFailed:
                    // no purchase
                    buttonTitle = NSLocalizedString(@"Failed", @"App store just failed");
                    break;
                    
                default:
                    break;
            }
        }
        else
        {   // not bought or being bought
            self.buyButton.enabled = YES;
            if ([self.purchaseableProduct.product.price isEqualToNumber: [NSDecimalNumber numberWithDouble: 0.0]])
            {
                buttonTitle = NSLocalizedString(@"Get", @"App store Get");
            }
            else
            {
                buttonTitle = NSLocalizedString(@"Buy", @"App store Buy");
            }
        }
        [self.buyButton setTitle: buttonTitle forState: UIControlStateNormal];

        if ([self.purchaseableProduct.product.price isEqualToNumber: [NSDecimalNumber numberWithDouble: 0.0]])
        {
            self.priceLabel.text = NSLocalizedString(@"Free", @"App Price is free");
        }
        else
        {
            self.priceLabel.text = self.purchaseableProduct.localizedPriceString;
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


#pragma mark - Actions
- (IBAction)buyButtonTapped:(UIButton *)sender
{
    self.buyButton.enabled = NO;
    [self.purchaseableProduct.purchaseManager processPaymentForProduct: self.purchaseableProduct.product quantity: 1];
}

@end
