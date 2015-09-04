//  Created by Taun Chapman on 07/29/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBEditorIntroPageControllerDataSource.h"
#import "MDBEditorIntroWhatIsFractalViewController.h"

@interface MDBEditorIntroPageControllerDataSource ()


@end

@implementation MDBEditorIntroPageControllerDataSource

-(NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return self.pageControllerPages.count;
}

//- (NSInteger) presentationIndexForPageViewController: (UIPageViewController *) pageViewController
//{
//    return 0;
//}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerAfterViewController:(UIViewController *)viewController
{
    UIViewController* next = 0;
    
    NSInteger currentIndex = [self.pageControllerPages indexOfObject: viewController];
    if (currentIndex < self.pageControllerPages.count - 1)
    {
        next = self.pageControllerPages[currentIndex+1];
    }
    return next;
}

-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController
     viewControllerBeforeViewController:(UIViewController *)viewController
{
    UIViewController* prev;
    
    NSInteger currentIndex = [self.pageControllerPages indexOfObject: viewController];
    if (currentIndex > 0)
    {
        prev = self.pageControllerPages[currentIndex-1];
    }
    return prev;
}

#pragma mark - UIPageViewControllerDelegate
-(void)pageViewController:(nonnull UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray*)previousViewControllers transitionCompleted:(BOOL)completed
{
    
}
-(void)pageViewController:(nonnull UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray*)pendingViewControllers
{
    
}
@end
