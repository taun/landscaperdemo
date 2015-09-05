//
//  MDBTutorialSplitViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 07/19/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBTutorialSplitViewController.h"
#import "MDBTutorialDetailContainerViewController.h"
#import "MDBTutorialPageSource.h"

@interface MDBTutorialSplitViewController ()


@end

@implementation MDBTutorialSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIStoryboard* storyboard = self.storyboard;
    self.tutorialSource.storyboard = storyboard;
    self.tutorialSource.viewController = self;
    
    self.masterNavCon = (UINavigationController*)self.viewControllers[0];
    self.masterTableView = (UITableViewController*)self.masterNavCon.viewControllers[0];
    self.masterTableView.tableView.delegate = self;
    self.masterTableView.tableView.dataSource = self.tutorialSource;
    
    self.detailNavCon = (UINavigationController*)self.viewControllers[1];
    if (self.detailNavCon)
    {
        self.detailPageController = (UIPageViewController*)self.detailNavCon.viewControllers[0];
        self.detailPageController.delegate = self;
        self.detailPageController.dataSource = self.tutorialSource;
        
        [self.tutorialSource setInitialPageFor: self.detailPageController andTableView: self.masterTableView.tableView];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.detailPageController.navigationItem.leftBarButtonItem = self.displayModeButtonItem;
    self.detailPageController.navigationItem.leftItemsSupplementBackButton = YES;
    
}

#pragma mark - UITableViewDelegate
-(void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSUInteger currentIndex = [self.tutorialSource indexOfController: [self.detailPageController.viewControllers firstObject]];
    
    UIPageViewControllerNavigationDirection direction = currentIndex < indexPath.row ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    
    UIViewController* pageControllerPage = [self.tutorialSource newHelpPageControllerForIndex: indexPath.row];
    // set pagecontroller initial page and showDetail...
    BOOL isCollapsed = self.isCollapsed;
    UINavigationController* masterController = self.viewControllers[0];
    __weak UIPageViewController* pageController = self.detailPageController;
    
    [pageController setViewControllers: @[pageControllerPage] direction: direction animated: !isCollapsed completion:^(BOOL finished) {
        //
        if (isCollapsed)
        {
            [masterController pushViewController: pageController animated: YES];
        }
    }];
}

#pragma mark - UIPageViewControllerDelegate
-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed)
    {
        UIViewController* currentPage = [pageViewController.viewControllers firstObject];
        NSUInteger index = [self.tutorialSource indexOfController: currentPage];
        if (index != NSNotFound)
        {
            [self.masterTableView.tableView selectRowAtIndexPath: [NSIndexPath indexPathForItem: index inSection: 0] animated: YES scrollPosition: UITableViewScrollPositionTop];
        }
    }
}

@end
