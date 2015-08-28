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


#pragma mark - UITableDataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.purchaseManager.validProductsWithImages.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier: @"PurchaseCell" forIndexPath: indexPath];
}

#pragma mark - UITableDelegate
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    MDBPurchaseTableViewCell* purchaseCell = (MDBPurchaseTableViewCell*)cell;
    purchaseCell.productWithImage = self.purchaseManager.validProductsWithImages[indexPath.row];
}

@end
