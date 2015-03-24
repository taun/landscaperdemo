//
//  MDBFractalDocumentCoordinator.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/05/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;

@class MDBFractalDocument, LSFractal;

@protocol MDBFractalDocumentCoordinatorDelegate;

@protocol MDBFractalDocumentCoordinator <NSObject,NSCopying>
/*!
 * The delegate responsible for handling inserts, removes, updates, and errors when the \c MDBFractalDocumentCoordinator
 * instance determines such events occured.
 */
@property (nonatomic, weak) id<MDBFractalDocumentCoordinatorDelegate> delegate;

/*!
 * Starts observing changes to the important \c NSURL instances. For example, if an \c MDBFractalDocumentCoordinator
 * conforming class has the responsibility to manage iCloud documents, the \c -startQuery method
 * would start observing an \c NSMetadataQuery. This method is called on the \c MDBFractalDocumentCoordinator
 * once the coordinator is set on the \c MDBDocumentController.
 */
- (void)startQuery;

/*!
 * Stops observing changes to the important \c NSURL instances. For example, if a \c MDBFractalDocumentCoordinator
 * conforming class has the responsibility to manage iCloud documents, the \c -stopQuery method
 * would stop observing changes to the \c NSMetadataQuery. This method is called on the \c MDBFractalDocumentCoordinator
 * once a new \c MDBFractalDocumentCoordinator has been set on the \c MDBDocumentController.
 */
- (void)stopQuery;

/**
 * Removes \c URL from the list of tracked \c NSURL instances. For example, an iCloud-specific
 * \c MDBFractalDocumentCoordinator would implement this method by deleting the underlying document that \c URL
 * represents. When \c URL is removed, the coordinator object is responsible for informing the delegate
 * by calling \c -listCoordinatorDidUpdateContentsWithInsertedURLs:removedURLs:updatedURLs: with the
 * removed \c NSURL. If a failure occurs when removing \c URL, the coordinator object is responsible
 * for informing the delegate by calling the \c -listCoordinatorDidFailRemovingListAtURL:withError:
 * method. The \c MDBDocumentController is the only object that should be calling this method directly.
 * The "remove" is intended to be called on the \c MDBDocumentController instance with an \c MDBFractalInfo
 * object whose URL would be forwarded down to the coordinator through this method.
 *
 * @param URL The \c NSURL instance to remove from the list of important instances.
 */
- (void)removeFractalAtURL:(NSURL *)URL;

/*!
 * Checks to see if a list can be created with a given name. As an example, if an \c MDBFractalDocumentCoordinator
 * instance was responsible for storing its lists locally as a document, the coordinator would check
 * to see if there are any other documents on the file system that have the same name. If they do, the
 * method would return false. Otherwise, it would return true. This method should only be called by
 * the \c MDBDocumentController instance. Normally you would call the users will call the \c -canCreateListWithName:
 * method on \c MDBDocumentController, which will forward down to the current \c MDBFractalDocumentCoordinator
 * instance.
 *
 * @param name The name to use when checking to see if a list can be created.
 *
 * @return \c YES if the list can be created with the given name, \c NO otherwise.
 */
- (BOOL)canCreateFractalWithIdentifier:(NSString *)name;

- (NSURL *)documentURLForName:(NSString *)name;

@end

/*!
 * The \c MDBFractalDocumentCoordinatorDelegate protocol exists to allow \c MDBFractalDocumentCoordinator instances to forward
 * events. These events include a \c MDBFractalDocumentCoordinator removing, inserting, and updating their important,
 * tracked \c NSURL instances. The \c MDBFractalDocumentCoordinatorDelegate also allows a \c MDBFractalDocumentCoordinator
 * to notify its delegate of any errors that occured when removing or creating a list for a given URL.
 */
@protocol MDBFractalDocumentCoordinatorDelegate <NSObject>

/*!
 * Notifies the \c MDBFractalDocumentCoordinatorDelegate instance of any changes to the tracked URLs of the
 * \c MDBFractalDocumentCoordinator. For more information about when this method should be called, see the
 * description for the other \c MDBFractalDocumentCoordinator methods mentioned above that manipulate the tracked
 * \c NSURL instances.
 *
 * @param insertedURLs The \c NSURL instances that are newly tracked.
 * @param removedURLs The \c NSURL instances that have just been untracked.
 * @param updatedURLs The \c NSURL instances that have had their underlying model updated.
 */
- (void)documentCoordinatorDidUpdateContentsWithInsertedURLs:(NSArray *)insertedURLs removedURLs:(NSArray *)removedURLs updatedURLs:(NSArray *)updatedURLs;

/*!
 * Notifies an \c MDBFractalDocumentCoordinatorDelegate instance of an error that occured when a coordinator
 * tried to remove a specific URL from the tracked \c NSURL instances. For more information about when
 * this method should be called, see the description for \c <tt>-[MDBFractalDocumentCoordinator removeListAtURL:]</tt>.
 *
 * @param URL The \c NSURL instance that failed to be removed.
 * @param error The error that describes why the remove failed.
 */
- (void)documentCoordinatorDidFailRemovingDocumentAtURL:(NSURL *)URL withError:(NSError *)error;

/*!
 * Notifies a \c MDBFractalDocumentCoordinatorDelegate instance of an error that occured when a coordinator tried
 * to create a list at a given URL. For more information about when this method should be called, see
 * the description for \c <tt>-[MDBFractalDocumentCoordinator createURLForList:withName:]</tt>.
 *
 * @param URL The \c NSURL instance that couldn't be created for a list.
 * @param error The error the describes why the create failed.
 */
- (void)documentCoordinatorDidFailCreatingDocumentAtURL:(NSURL *)URL withError:(NSError *)error;

@end
