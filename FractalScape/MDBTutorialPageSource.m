//
//  MDBTutorialSource.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/13/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBTutorialPageSource.h"
#import "MDBHelpContentsTableViewCell.h"

@interface MDBTutorialPageSource ()

/*!
 Array of available page storyboard identifiers
 */
@property (nonatomic,strong) NSArray                      *helpPageIdentifiers;
@property (nonatomic,strong) NSArray                      *helpPageTitles;

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

-(void)findAndStoreIdentifiersAndTitles
{
    UIStoryboard* storyboard = self.viewController.storyboard;
    
    NSUInteger maxPageCount = 14;
    NSMutableArray* pages = [NSMutableArray new];
    NSMutableArray* titles = [NSMutableArray new];
    
    int pageIndex = 0;
    
    @try {
        @autoreleasepool {
            NSString* pageIdentifier;
            UIViewController* page;
            do {
                pageIdentifier = [NSString stringWithFormat: @"HelpControllerPage%u",pageIndex];
                page = (UIViewController *)[storyboard instantiateViewControllerWithIdentifier: pageIdentifier];
                
                [pages addObject: pageIdentifier];
                [titles addObject: page.title];
                
                ++pageIndex;
            } while (page && pageIndex < maxPageCount);
        }
        if (pageIndex + 1 == maxPageCount)
        {
            NSLog(@"FractalScapes help pages max page count reached: %ul",pageIndex);
        }
    }
    @catch (NSException *exception) {
        //
    }
    @finally {
        //
    }
    
    _helpPageIdentifiers = [pages copy];
    _helpPageTitles = [titles copy];
}

-(NSArray*)helpPageIdentifiers
{
    if (!_helpPageIdentifiers)
    {
        [self findAndStoreIdentifiersAndTitles];
    }
    return _helpPageIdentifiers;
}

-(NSArray *)helpPageTitles
{
    if (!_helpPageTitles)
    {
        [self findAndStoreIdentifiersAndTitles];
    }
    return _helpPageTitles;
}

-(UIViewController *)helpPageControllerForIndex:(NSUInteger)index
{
    UIStoryboard* storyboard = self.viewController.storyboard;
    NSString* identifier = self.helpPageIdentifiers[index];
    return  (UIViewController *)[storyboard instantiateViewControllerWithIdentifier: identifier];
}

-(NSUInteger)indexOfController:(UIViewController *)viewController
{
    NSUInteger index = [self.helpPageIdentifiers indexOfObject: viewController.restorationIdentifier];
    return index;
}

#pragma mark - UITableViewDataSource
-(NSInteger)numberOfSectionsInTableView:(nonnull UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.helpPageIdentifiers.count;
}

-(nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    MDBHelpContentsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: @"HelpContentsCell"];
    cell.title = self.helpPageTitles[indexPath.row];
    return cell;
}

-(void)setInitialPageFor:(UIPageViewController *)pageController andTableView: (UITableView*)tableView
{
    UIViewController* firstController = [self helpPageControllerForIndex: 0];
    [pageController setViewControllers: @[firstController] direction: UIPageViewControllerNavigationDirectionForward animated: NO completion:^(BOOL finished) {
        //
        [tableView selectRowAtIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0] animated: NO scrollPosition: UITableViewScrollPositionTop];
    }];
}

#pragma mark - UIPageViewControllerDataSource
-(nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerAfterViewController:(nonnull UIViewController *)viewController
{
    NSUInteger currentIndex = [self indexOfController: viewController];
    NSUInteger nextIndex = currentIndex + 1;
    UIViewController* nextController = currentIndex == (self.helpPageIdentifiers.count - 1) ? nil : [self helpPageControllerForIndex: nextIndex];
    return nextController;
}

-(nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerBeforeViewController:(nonnull UIViewController *)viewController
{
    NSUInteger currentIndex = [self indexOfController: viewController];
    NSUInteger nextIndex = currentIndex - 1;
    UIViewController* nextController = currentIndex == 0 ? nil : [self helpPageControllerForIndex: nextIndex];
    return nextController;
}

-(NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return self.helpPageIdentifiers.count;
}

-(NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    UIViewController* currentPage = [pageViewController.viewControllers firstObject];
    return [self indexOfController: currentPage];
}

@end
