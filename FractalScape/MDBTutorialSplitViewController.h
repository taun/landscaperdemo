//
//  MDBTutorialSplitViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 07/19/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MDBAppModel;

@interface MDBTutorialSplitViewController : UISplitViewController <UITableViewDataSource, UITableViewDelegate, UIPageViewControllerDataSource>

@property (nonatomic,strong) MDBAppModel                                    *appModel;


@end
