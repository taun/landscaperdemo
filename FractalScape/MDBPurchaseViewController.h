//
//  MDBPurchaseViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 08/27/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDBPurchaseManager.h"


@interface MDBPurchaseViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,PurchaseManagerDelegate>

@property(nonatomic,strong)MDBPurchaseManager         *purchaseManager;

-(IBAction)attemptProductRestore:(id)sender;
-(void)productsChanged;

@end
