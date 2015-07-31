//
//  MDBEditorIntroPage4ViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 07/31/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBEditorIntroPage3ViewController.h"

@interface MDBEditorIntroPage3ViewController ()

@end

@implementation MDBEditorIntroPage3ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIImage* animation = [UIImage animatedImageNamed: @"DragAndDrop" duration: 16.0];
    
    self.dragAndDropAnimationImageView.image = animation;
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.dragAndDropAnimationImageView startAnimating];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.dragAndDropAnimationImageView stopAnimating];
}

@end
