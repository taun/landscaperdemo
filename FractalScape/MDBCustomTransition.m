//
//  MDBCustomTransition.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/28/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBCustomTransition.h"

@implementation MDBCustomTransition

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 1.0;
}

@end

@implementation MDBZoomPushTransition

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    //Get references to the view hierarchy
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
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
}

@end

@implementation MDBZoomPopTransition

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    //Get references to the view hierarchy
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
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


@end

@implementation MDBZoomPushBounceTransition

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    //Get references to the view hierarchy
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    //Add 'to' view to the hierarchy with 0.0 scale
    toViewController.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
    [containerView insertSubview:toViewController.view aboveSubview:fromViewController.view];
    
    //Scale the 'to' view to to its final position
    toViewController.view.alpha = 0.0;
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:duration / 2.0 animations:^{
        toViewController.view.alpha = 1.0;
    }];
    
    CGFloat damping = 0.55;
    
    [UIView animateWithDuration: duration delay:0.0
         usingSpringWithDamping: damping initialSpringVelocity:1.0 / damping
                        options:0 animations:^{
        toViewController.view.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];}

@end

@implementation MDBZoomPopBounceTransition

#pragma message "TODO: pass the target bounds"

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    //Get references to the view hierarchy
    UIView *containerView = [transitionContext containerView];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    [containerView insertSubview:toViewController.view belowSubview:fromViewController.view];

    CGSize containerSize = containerView.bounds.size;
    // hardcoding collectionCell bounds for now.
    CGFloat cellCenterX = 8.0+(146.0/2.0);
    CGFloat cellCenterY = 40.0 + 8.0 + 6.0 + (138.0/2.0);
    
    CGFloat viewCenterX = containerSize.width/2.0;
    CGFloat viewCenterY = containerSize.height/2.0;
    
    CGAffineTransform scale = CGAffineTransformMakeScale(0.2, 0.2);
    CGAffineTransform translate = CGAffineTransformMakeTranslation(cellCenterX-viewCenterX, cellCenterY-viewCenterY);

    NSTimeInterval duration = [self transitionDuration:transitionContext];

    [UIView animateWithDuration:3.0 * duration / 2.0
                          delay:duration / 4.0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         fromViewController.view.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
//                         [fromViewController.view removeFromSuperview];
                         [transitionContext completeTransition:YES];
                     }];
    
    [UIView animateWithDuration:2.0 * duration
                          delay:0.0
         usingSpringWithDamping:1.0
          initialSpringVelocity:-15.0
                        options:0
                     animations:^{
                         
                         fromViewController.view.transform = CGAffineTransformConcat(scale, translate);
                     }
                     completion:nil];

}

@end