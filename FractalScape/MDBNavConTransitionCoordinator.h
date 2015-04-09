//  Created by Taun Chapman on 03/27/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;


/*
 Influenced by: http://objectivetoast.com/2014/03/17/custom-transitions-on-ios/
 
 "A pattern that solves this problem cleanly is to add properties to UIViewController
 called ‑pushAnimationController and ‑popAnimationController. Then the navigation controller’s 
 delegate can be made to return the animation controller as specified by the pushed or popped 
 view controller. This allows the navigation controller’s delegate to remain generic and avoids 
 the need to change which object is the delegate.
 TWTNavigationControllerDelegate implements this pattern and is also included in Toast."
 
 */

@protocol MDBNavConTransitionProtocol

@property (nonatomic,strong)id <UIViewControllerAnimatedTransitioning>      pushTransition;
@property (nonatomic,strong)id <UIViewControllerAnimatedTransitioning>      popTransition;
@property (nonatomic,assign) CGRect                                         transitionDestinationRect;
@property (nonatomic,assign) CGRect                                         transitionSourceRect;

@end


@interface MDBNavConTransitionCoordinator : NSObject <UINavigationControllerDelegate>

@end
