//
//  MDBEditorHelpTransitioningDelegate.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/18/15.
//  Copyright © 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBEditorHelpTransitioningDelegate.h"

@implementation MDBEditorHelpTransitioningDelegate

-(nullable UIPresentationController *)presentationControllerForPresentedViewController:(nonnull UIViewController *)presented presentingViewController:(nonnull UIViewController *)presenting sourceViewController:(nonnull UIViewController *)source
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