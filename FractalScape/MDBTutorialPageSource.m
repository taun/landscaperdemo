//
//  MDBTutorialSource.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/13/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBTutorialPageSource.h"
#import "MDBHelpContentsTableViewCell.h"
#import "MDBEditorIntroWhatIsFractalViewController.h"

@interface MDBTutorialPageSource ()

@end

@implementation MDBTutorialPageSource

//-(void)awakeFromNib
//{
//    [_pageController setViewControllers: @[self.helpPages[0]] direction: UIPageViewControllerNavigationDirectionForward animated: YES completion:^(BOOL finished) {
//        //
//    }];
//    
//    [self.viewController showDetailViewController: self.pageController sender: self.viewController];
//}


-(NSArray*)helpPages
{
    if (!_helpPages)
    {
        NSUInteger pageCount = 4;
        NSMutableArray* pages = [NSMutableArray new];
        UIViewController* page = nil;
        NSString* pageIdentifier = nil;
        int pageIndex = 0;
        
        @try {
            do {
                pageIdentifier = [NSString stringWithFormat: @"HelpControllerPage%u",pageIndex];
                page = (MDBEditorIntroWhatIsFractalViewController *)[self.storyboard instantiateViewControllerWithIdentifier: pageIdentifier];
                [pages addObject: page];
                ++pageIndex;
            } while (page);
        }
        @catch (NSException *exception) {
            //
        }
        @finally {
            //
        }

        _helpPages = [pages copy];

    }
    return _helpPages;
}


#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(nonnull UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.helpPages.count;
}

-(nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    MDBHelpContentsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: @"HelpContentsCell"];
    cell.title = [self.helpPages[indexPath.row] title];
    return cell;
}

-(void)setInitialPageFor:(UIPageViewController *)pageController andTableView: (UITableView*)tableView
{
    [pageController setViewControllers: @[self.helpPages[0]] direction: UIPageViewControllerNavigationDirectionForward animated: NO completion:^(BOOL finished) {
        //
        [tableView selectRowAtIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0] animated: NO scrollPosition: UITableViewScrollPositionTop];
    }];
}

#pragma mark - UIPageViewControllerDataSource
-(nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerAfterViewController:(nonnull UIViewController *)viewController
{
    NSUInteger currentIndex = [self.helpPages indexOfObject: viewController];
    NSUInteger nextIndex = currentIndex + 1;
    UIViewController* nextController = currentIndex == (self.helpPages.count - 1) ? nil : self.helpPages[nextIndex];
    return nextController;
}

-(nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerBeforeViewController:(nonnull UIViewController *)viewController
{
    NSUInteger currentIndex = [self.helpPages indexOfObject: viewController];
    NSUInteger nextIndex = currentIndex - 1;
    UIViewController* nextController = currentIndex == 0 ? nil : self.helpPages[nextIndex];
    return nextController;
}

-(NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return self.helpPages.count;
}

-(NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    UIViewController* currentPage = [pageViewController.viewControllers firstObject];
    return [self.helpPages indexOfObject: currentPage];
}

@end
