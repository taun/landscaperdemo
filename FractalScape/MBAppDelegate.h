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

@class LSDrawingRuleType;
@class LSFractal;

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

@end
