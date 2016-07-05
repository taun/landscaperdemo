//
//  MDBEditorHelpTransitioningDelegate.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/18/15.
//  Copyright © 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBEditorHelpTransitioningDelegate.h"

@implementation MDBEditorHelpTransitioningDelegate

-(nullable UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
    return [[MDBEditorHelpPresentationController alloc]initWithPresentedViewController: presented presentingViewController: presenting];
}

@end

@implementation MDBEditorHelpPresentationController

-(void)presentationTransitionWillBegin
{
    
}

-(void)presentationTransitionDidEnd:(BOOL)completed
{
    
}

-(void)dismissalTransitionWillBegin
{
    
}

-(void)dismissalTransitionDidEnd:(BOOL)completed
{
    
}

@end
