//
//  MBAppDelegate.h
//  FractalScape
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//


@import Foundation;
@import UIKit;
@import CoreMotion;

@class MDBAppModel;

/*!
 Segue identifier for transitioning to the document list editor.
 */
extern NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerToEditDocumentListControllerSegueIdentifier;
/*!
 * The segue identifier for the transition between the \c ListDocumentsViewController and the
 * \c NewListDocumentController.
 */
extern NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerToNewDocumentControllerSegueIdentifier;

/*!
 * The segue identifier for the transition between the \c ListDocumentsViewController and the
 * \c ListViewController.
 */
extern NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerToFractalViewControllerSegueIdentifier;

/*!
 * The segue identifier for the transition between the \c ListDocumentsViewController and the
 * \c ListViewController initiated due to the resumption of a user activity.
 */
extern NSString *const kMDBAppDelegateMainStoryboardDocumentsViewControllerContinueUserActivityToFractalViewControllerSegueIdentifier;


@interface MBAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (weak,nonatomic) id               documentsViewController;
@property (weak,nonatomic) id               primaryViewController;
@property (nonatomic, strong) MDBAppModel   *appModel;

- (void)handleUbiquityIdentityDidChangeNotification:(NSNotification *)notification;

@end
