//
//  MDBZoomTransition.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/27/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBZoomTransition.h"

@implementation MDBZoomTransition

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
    if (operation == UINavigationControllerOperationPush) {
        self.type = AnimationTypePresent;
    } else if (operation == UINavigationControllerOperationPop){
        self.type = AnimationTypeDismiss;
    }
    return self;
}


-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    //Get references to the view hierarchy
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (self.type == AnimationTypePresent) {
        //Add 'to' view to the hierarchy with 0.0 scale
        toViewController.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
        toViewController.view.alpha = 0.1;
        [containerView insertSubview:toViewController.view aboveSubview:fromViewController.view];
        
        //Scale the 'to' view to to its final position
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            toViewController.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
            toViewController.view.alpha = 1.0;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    } else if (self.type == AnimationTypeDismiss) {
        //Add 'to' view to the hierarchy
        [containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
        
        //Scale the 'from' view down until it disappears
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            fromViewController.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
            fromViewController.view.alpha = 0.1;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.5;
}

@end
