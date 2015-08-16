//  Created by Taun Chapman on 07/19/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;

@class MDBAppModel;
@class MDBTutorialSource;


@interface MDBTutorialSplitViewController : UISplitViewController <UITableViewDelegate,UIPageViewControllerDelegate>

@property (nonatomic,strong) MDBAppModel                                    *appModel;
@property (nonatomic,weak) IBOutlet UINavigationController                  *masterNavCon;
@property (nonatomic,weak) IBOutlet UITableViewController                   *masterTableView;
@property (nonatomic,strong) IBOutlet UINavigationController                  *detailNavCon;
@property (nonatomic,strong) IBOutlet UIPageViewController                    *detailPageController;
@property (nonatomic,strong) IBOutlet MDBTutorialSource                     *tutorialSource;

@end
