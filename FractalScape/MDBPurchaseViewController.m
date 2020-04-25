//
//  MDBPurchaseViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/27/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBPurchaseViewController.h"
#import "MDBPurchaseManager.h"
#import "MDBPurchaseTableViewCell.h"


@interface MDBPurchaseViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MDBPurchaseViewController

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.purchaseManager.delegate = self;
}

-(void)dealloc
{
    if (_purchaseManager)
    {
        [_purchaseManager setDelegate: nil];
    }
}

-(IBAction) attemptProductRestore: (id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Restore",nil)
                                                                   message: NSLocalizedString(@"Access App Store for Purchases?",nil)
                                                            preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertController* __weak weakAlert = alert;
    
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Ok", @"Ok, go ahead with action")
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated: YES completion:nil];
                                        [self.purchaseManager updateAppReceipt];
                                    }];
    [alert addAction: defaultAction];

    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel", @"Cancel, cancel action")
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction * action)
                                    {
                                        [weakAlert dismissViewControllerAnimated: YES completion:nil];
                                    }];
    [alert addAction: cancelAction];

    
    [self.navigationController presentViewController: weakAlert animated:YES completion:nil];
}

#pragma mark - UITableDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = MAX(1, self.purchaseManager.validPurchaseableProducts.count);
    return count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;
    if (self.purchaseManager.validPurchaseableProducts.count)
    {
        cell = [tableView dequeueReusableCellWithIdentifier: @"PurchaseCell" forIndexPath: indexPath];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier: @"EmptyStoreCell" forIndexPath: indexPath];
    }
    return cell;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil; //@"Available one time purchases";
}

#pragma mark - UITableDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (self.purchaseManager.validPurchaseableProducts.count)
    {
        return 88.0;
    }
    else
    {
        return 0.0;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIButton* restoreButton;
    
    restoreButton = [UIButton buttonWithType: UIButtonTypeSystem];
    
    if (self.purchaseManager.userCanMakePayments && self.purchaseManager.validPurchaseableProducts.count && self.purchaseManager.areThereProductsToBuyOrRestore)
    {
        [restoreButton setTitle: NSLocalizedString(@"Check for restorable purchases", @"Store restore button") forState: UIControlStateNormal];
        [restoreButton addTarget: self action: @selector(attemptProductRestore:) forControlEvents: UIControlEventTouchUpInside];
    }
    else
    {
        [restoreButton setTitle: NSLocalizedString(@"No Purchases to Restore", @"Store nothing to restore button") forState: UIControlStateNormal];
        restoreButton.enabled = NO;
    }
    
    return restoreButton;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{    
    if ([cell isKindOfClass:[MDBPurchaseTableViewCell class]])
    {
        MDBPurchaseTableViewCell* purchaseCell = (MDBPurchaseTableViewCell*)cell;
        purchaseCell.purchaseableProduct = self.purchaseManager.sortedValidPurchaseableProducts[indexPath.row];
    }
}

#pragma mark - PurchaseManagerDelegate
-(void)productsChanged
{
    [self.tableView reloadData];
}

@end
