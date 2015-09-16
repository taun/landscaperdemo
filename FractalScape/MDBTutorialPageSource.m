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

/*!
 Array of available page storyboard identifiers
 */
@property (nonatomic,strong) NSArray                      *helpPageIdentifiers;
@property (nonatomic,strong) NSArray                      *helpPageTitles;
@property (nonatomic,strong) UIViewController             *currentHelpController;
@property (nonatomic,strong) UIViewController             *nextHelpController;
@property (nonatomic,strong) UIViewController             *prevHelpController;

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
-(void)dealloc
{
    
}

-(void)findAndStoreIdentifiersAndTitles
{
    @autoreleasepool {
        
    NSUInteger maxPageCount = 14;
    NSMutableArray* pages = [NSMutableArray new];
    NSMutableArray* titles = [NSMutableArray new];
    
    
    @try {
        int pageIndex = 0;
        UIViewController* page = nil;
        
        do {
            
                NSString* pageIdentifier = nil;

                pageIdentifier = [NSString stringWithFormat: @"HelpControllerPage%u",pageIndex];
                page = (UIViewController *)[self.storyboard instantiateViewControllerWithIdentifier: pageIdentifier];
                
                [pages addObject: pageIdentifier];
                [titles addObject: page.title];
                
                ++pageIndex;
        } while (page && pageIndex < maxPageCount);
        
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
        _helpPageIdentifiers = [pages copy];
        _helpPageTitles = [titles copy];
    }
    }
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

-(UIViewController *)newHelpPageControllerForIndex:(NSUInteger)index
{
//    UIStoryboard* storyboard = self.viewController.storyboard;
    [UIColor blackColor];
    NSString* identifier = self.helpPageIdentifiers[index];
    UIViewController* currentHelpController = (MDBEditorIntroWhatIsFractalViewController *)[self.storyboard instantiateViewControllerWithIdentifier: identifier];
//    [self.currentHelpController loadView];
    return currentHelpController;
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
    self.currentHelpController = [self newHelpPageControllerForIndex: 0];
    
    [pageController setViewControllers: @[self.currentHelpController] direction: UIPageViewControllerNavigationDirectionForward animated: NO completion:^(BOOL finished) {
        //
        [tableView selectRowAtIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0] animated: NO scrollPosition: UITableViewScrollPositionTop];
    }];
}

#pragma mark - UIPageViewControllerDataSource
-(nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerAfterViewController:(nonnull UIViewController *)viewController
{
    UIViewController* nextVC;
    
        self.prevHelpController = viewController;
        NSUInteger currentIndex = [self indexOfController: viewController];
        NSUInteger nextIndex = currentIndex + 1;
        self.prevHelpController = viewController;
        self.currentHelpController = currentIndex == (self.helpPageIdentifiers.count - 1) ? nil : [self newHelpPageControllerForIndex: nextIndex];
        nextVC = self.currentHelpController;
    
    return nextVC;
}

-(nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerBeforeViewController:(nonnull UIViewController *)viewController
{
    UIViewController* prevVC;
    
        self.nextHelpController = viewController;
        NSUInteger currentIndex = [self indexOfController: viewController];
        NSUInteger nextIndex = currentIndex - 1;
        self.currentHelpController = currentIndex == 0 ? nil : [self newHelpPageControllerForIndex: nextIndex];
        prevVC = self.currentHelpController;

    return prevVC;
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
