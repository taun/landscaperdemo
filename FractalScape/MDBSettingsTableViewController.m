//
//  MDBSettingsTableViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 07/15/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBSettingsTableViewController.h"

#import "MDBAppModel.h"


@interface MDBSettingsTableViewController ()

@end

@implementation MDBSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateControls];
}

-(void) updateControls
{
    self.appVersion.text = self.appModel.versionBuildString;
    
    self.showHelpTipsSwitch.on = self.appModel.showHelpTips;
    self.showParallaxEffect.on = self.appModel.showParallax;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)showHelpTipsChanged:(UISwitch *)sender
{
    [self.appModel setShowHelpTips: sender.on];
}

- (IBAction)showParallaxEffectChanged:(UISwitch *)sender
{
    [self.appModel setShowParallax: sender.on];
}

@end
