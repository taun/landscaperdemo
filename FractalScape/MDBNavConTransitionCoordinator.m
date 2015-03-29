//  Created by Taun Chapman on 03/27/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBNavConTransitionCoordinator.h"

#import "MDBCustomTransition.h"


@implementation MDBNavConTransitionCoordinator

-(void)navigationController:(UINavigationController *)navigationController
      didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    
}

-(void)navigationController:(UINavigationController *)navigationController
     willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    
}

-(id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                 animationControllerForOperation:(UINavigationControllerOperation)operation
                                              fromViewController:(UIViewController *)fromVC
                                                toViewController:(UIViewController *)toVC
{
    MDBCustomTransition* transition;
    
    if (operation == UINavigationControllerOperationPush)
    {
        transition = [MDBZoomPushBounceTransition new];
    }
    else if (operation == UINavigationControllerOperationPop)
    {
        transition = [MDBZoomPopBounceTransition new];
    }
    return transition;
}

@end
