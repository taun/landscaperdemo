//
//  FractalDefinitionKeyboardView.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 01/29/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import "FractalDefinitionKeyboardView.h"

@implementation FractalDefinitionKeyboardView


//- (BOOL)loadFractalKeyboardNibFile
//{
//    NSArray*    topLevelObjs = nil;
//    
//    topLevelObjs = [[NSBundle mainBundle] loadNibNamed:@"FractalDefinitionKeyboardView" owner:self options:nil];
//    if (topLevelObjs == nil)
//    {
//        NSLog(@"Error! Could not load FractalDefinitionKeyboardView file.\n");
//        return NO;
//    }
//    
//    return YES;
//}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
//    [self loadFractalKeyboardNibFile];
//    UIImage* background = [UIImage imageNamed: @"FractalKeyboardBackground"];
//    UIColor* backgroundColor = [UIColor colorWithPatternImage: background];
//    self.view.backgroundColor = backgroundColor;
}


- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
    self.delegate = nil;
}

- (IBAction)keyPressed:(UIButton*)sender {
    
    NSString* keyTitle = sender.titleLabel.text;
    
    [self.delegate keyTapped: keyTitle];
}
@end
