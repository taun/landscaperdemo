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
    [self.purchaseManager revalidateProducts];
}

-(void)dealloc
{
    if (_purchaseManager)
    {
        [_purchaseManager setDelegate: nil];
    }
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
