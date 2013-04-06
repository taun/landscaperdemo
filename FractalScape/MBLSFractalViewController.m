//
//  MBLSFractalViewController.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/08/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "MBLSFractalViewController.h"
#import "LSFractal+addons.h"
#import "LSFractalGenerator.h"
#import "MBColor+addons.h"
#import "MBPortalStyleView.h"
//#import "MBLSFractalLevelNView.h"

#import "LSFractalGenerator.h"
#import "LSReplacementRule.h"

#import <QuartzCore/QuartzCore.h>

#include <math.h>



@interface MBLSFractalViewController ()


@end

@implementation MBLSFractalViewController





#pragma mark - Getters & Setters




#pragma mark - view utility methods






#pragma mark - UIView methods

#pragma mark - UIViewController Methods



- (void)viewWillDisappear:(BOOL)animated {
    CGRect viewBounds = self.view.bounds;
    [self logBounds: viewBounds info: NSStringFromSelector(_cmd)];
    
    // undo all non-saved changes
    [self.currentFractal.managedObjectContext rollback];

	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
/*
 Controller exists here but controller has no views yet!
 Can set properties but should not set any which depend on a view or a view outlet.
 */
- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    for (CALayer* layer in self.fractalDisplayLayersArray) {
        layer.delegate = nil;
    }

    [self setReplacementRulesArray: nil];

}


@end
