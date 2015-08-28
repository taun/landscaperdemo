//
//  MDBPurchaseViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 08/27/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MDBPurchaseManager;

@interface MDBPurchaseViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,weak)MDBPurchaseManager         *purchaseManager;

@end
