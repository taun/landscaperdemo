//  Created by Taun Chapman on 08/13/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;

@interface MDBTutorialPageSource : NSObject <UITableViewDataSource, UIPageViewControllerDataSource>

@property(nonatomic,weak)IBOutlet UIViewController       *viewController;

-(void)setInitialPageFor: (UIPageViewController*)pageController andTableView: (UITableView*)tableView;

-(UIViewController *)helpPageControllerForIndex:(NSUInteger)index;
/*!
 Depends on the viewController having it's restorationIdentifier the same as it's storyboard identifier.
 
 @param viewController viewController to find
 
 @return index of the desired viewController in the page list
 */
-(NSUInteger)indexOfController: (UIViewController*)viewController;
@end
