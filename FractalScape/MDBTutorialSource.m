//
//  MDBTutorialSource.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/13/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBTutorialSource.h"
#import "MDBHelpContentsTableViewCell.h"



@interface MDBTutorialSource ()

@property (nonatomic,strong) NSArray        *helpPages;

@end

@implementation MDBTutorialSource

-(NSArray*)helpPages
{
    if (!_helpPages)
    {
        UIStoryboard* storyboard = self.viewController.storyboard;
        
        NSUInteger pageCount = 3;
        NSMutableArray* pages = [NSMutableArray new];
        
        for (int pageIndex = 0; pageIndex < pageCount; pageIndex++)
        {
            NSString* pageIdentifier = [NSString stringWithFormat: @"HelpControllerPage%u",pageIndex];
            UIViewController* page = (UIViewController *)[storyboard instantiateViewControllerWithIdentifier: pageIdentifier];
            [pages addObject: page];
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

#pragma mark - UITableViewDelegate
-(void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UIViewController* pageControllerPage = self.helpPages[indexPath.row];
    // set pagecontroller initial page and showDetail...
}

#pragma mark - UIPageViewControllerDataSource
-(nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerAfterViewController:(nonnull UIViewController *)viewController
{
    NSUInteger currentIndex = [self.helpPages indexOfObject: viewController];
    NSUInteger nextIndex = MIN(currentIndex+1,self.helpPages.count-1);
    UIViewController* nextController = self.helpPages[nextIndex];
    return nextController;
}

-(nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerBeforeViewController:(nonnull UIViewController *)viewController
{
    NSUInteger currentIndex = [self.helpPages indexOfObject: viewController];
    NSUInteger nextIndex = currentIndex == 0 ? 0 : currentIndex - 1;
    UIViewController* nextController = self.helpPages[nextIndex];
    return nextController;
}

@end
