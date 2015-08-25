//  Created by Taun Chapman on 07/15/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;

@class MDBAppModel;


@interface MDBSettingsTableViewController : UITableViewController

/*!
 The collection of MDBFractalDocumentInfo objects from the local filesystem or cloud.
 */
@property (nonatomic,strong) MDBAppModel                                    *appModel;

@property (weak, nonatomic) IBOutlet UISwitch *showHelpTipsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *showParallaxEffect;

@property (weak, nonatomic) IBOutlet UILabel *appVersion;
@property (weak, nonatomic) IBOutlet UILabel *appBuild;

- (IBAction)showHelpTipsChanged:(UISwitch *)sender;
- (IBAction)showParallaxEffectChanged:(UISwitch *)sender;



@end
