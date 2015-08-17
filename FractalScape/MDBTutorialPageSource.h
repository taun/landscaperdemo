//  Created by Taun Chapman on 08/13/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;

@interface MDBTutorialPageSource : NSObject <UITableViewDataSource, UIPageViewControllerDataSource>

@property(nonatomic,weak)IBOutlet UIViewController       *viewController;
@property (nonatomic,strong) NSArray                        *helpPages;

-(void)setInitialPageFor: (UIPageViewController*)pageController andTableView: (UITableView*)tableView;

@end
