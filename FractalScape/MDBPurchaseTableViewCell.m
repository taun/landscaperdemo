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

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
//    self.backgroundView = [[UIImageView alloc]initWithImage: [UIImage
//                                                              imageNamed: @"skMasterTableCellBackground"]];
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
        [_purchaseableProduct addObserver: self forKeyPath: @"localizedStoreButtonString" options: 0 context: NULL];
    }
}

-(void)removeProductObservers
{
    if (_purchaseableProduct)
    {
        [_purchaseableProduct removeObserver: self forKeyPath: @"localizedStoreButtonString"];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString: @"localizedStoreButtonString"])
    {
        [self updateBuyButtonStatus];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

-(void)dealloc
{
    [self removeProductObservers];
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
    self.buyButton.enabled = (_purchaseableProduct.canBuy || _purchaseableProduct.canRestore);
    [self.buyButton setTitle: _purchaseableProduct.localizedStoreButtonString forState: UIControlStateNormal];
    self.priceLabel.text = self.purchaseableProduct.localizedPriceString;
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
