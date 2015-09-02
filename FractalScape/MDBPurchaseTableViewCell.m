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

-(void)updateValueDisplays
{
    self.productImageView.image = self.productWithImage.image;
    self.productLabel.text = self.productWithImage.product.localizedTitle;
    self.productDescription.text = self.productWithImage.product.localizedDescription;
    if ([self.productWithImage.product.price isEqualToNumber: [NSDecimalNumber numberWithDouble: 0.0]])
    {
        self.priceLabel.text = NSLocalizedString(@"Free", @"App Price is free");
        [self.buyButton setTitle: NSLocalizedString(@"Get", @"App store Get") forState: UIControlStateNormal];
    }
    else
    {
        self.priceLabel.text = self.productWithImage.localizedPriceString;
        [self.buyButton setTitle: NSLocalizedString(@"Buy", @"App store Buy") forState: UIControlStateNormal];
    }
    
    if (self.productWithImage.hasReceipt)
    {
        [self.buyButton setTitle: NSLocalizedString(@"Bought", @"App store already bought") forState: UIControlStateNormal];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Getters & Setters

-(void)setProductWithImage:(MDBBasePurchaseableProduct *)productWithImage
{
    if (_productWithImage != productWithImage)
    {
        _productWithImage = productWithImage;
    }
    
    [self updateValueDisplays];
}

#pragma mark - Actions
- (IBAction)buyButtonTapped:(UIButton *)sender
{
    [self.productWithImage.purchaseManager processPaymentForProduct: self.productWithImage.product quantity: 1];
}

@end
