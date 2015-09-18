//  Created by Taun Chapman on 07/19/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;

@class MDBAppModel;
@class MDBTutorialPageSource;


@interface MDBTutorialSplitViewController : UISplitViewController <UITableViewDelegate,UIPageViewControllerDelegate>

@property (nonatomic,strong) MDBAppModel                                    *appModel;
/*!
 Splitview master view navigation controller.
 */
@property (nonatomic,weak) IBOutlet UINavigationController                  *masterNavCon;
/*!
 Splitview master view table controller.
 */
@property (nonatomic,weak) IBOutlet UITableViewController                   *masterTableView;
/*!
 Splitview detail view navigation controller.
 */
@property (nonatomic,strong) IBOutlet UINavigationController                *detailNavCon;
/*!
 Splitview detail view controller.
 */
@property (nonatomic,strong) IBOutlet UIPageViewController                  *detailPageController;

@end
