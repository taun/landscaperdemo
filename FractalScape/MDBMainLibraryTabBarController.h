//
//  MDBMainLibraryTabBarController.h
//  FractalScapes
//
//  Created by Taun Chapman on 05/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MDBAppModel;
@class MBFractalLibraryViewController, MDBFractalCloudBrowser, MDBSettingsTableViewController;

@interface MDBMainLibraryTabBarController : UITabBarController <UITabBarControllerDelegate>

@property (nonatomic,strong) MDBAppModel                                    *appModel;
@property (nonatomic,readonly) MBFractalLibraryViewController               *libraryController;
@property (nonatomic,readonly) MDBFractalCloudBrowser                       *cloudController;
@property (nonatomic,readonly) MDBSettingsTableViewController               *settingsController;

@end
