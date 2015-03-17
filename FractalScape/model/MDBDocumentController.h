//
//  MDBDocumentController.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/03/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;

@class MDBDocumentController, MDBFractalInfo, MDBFractalDocument, LSFractal;

@protocol MDBFractalDocumentCoordinator;


@protocol MDBFractalDocumentControllerDelegate <NSObject>

/*!
 * Notifies the receiver of this method that the document controller will change it's contents in some
 * form. This method is *always* called before any insert, remove, or update is received. In this method,
 * you should prepare your UI for making any changes related to the changes that you will need to reflect
 * once they are received. For example, if you have a table view in your UI that needs to respond to
 * changes to a newly inserted \c MDBFractalDocumentInfo object, you would want to call your table view's
 * \c -beginUpdates method. Once all of the updates are performed, your \c -documentControllerDidChangeContent:
 * method will be called. This is where you would to call your table view's \c -endUpdates method.
 *
 * @param documentController The \c MDBDocumentController instance that will change its content.
 */
- (void)documentControllerWillChangeContent:(MDBDocumentController *)documentController;
#pragma message "TODO: Since we are going to collection not table, these methods can use performBatchUpdates: and pass array if indexPaths"
/*!
 * Notifies the receiver of this method that the document controller is tracking a new \c MDBFractalDocumentInfo
 * object. Receivers of this method should update their UI accordingly.
 *
 * @param documentController The \c MDBDocumentController instance that inserted the new \c MDBFractalDocumentInfo.
 * @param fractalInfo The new \c MDBFractalDocumentInfo object that has been inserted at \c index.
 * @param index The index that \c fractalInfo was inserted at.
 */
- (void)documentController:(MDBDocumentController *)documentController didInsertFractalInfo:(MDBFractalInfo *)fractalInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the document controller received a message that \c fractalInfo
 * has updated its content. Receivers of this method should update their UI accordingly.
 *
 * @param documentController The \c MDBDocumentController instance that was notified that \c fractalInfo has
 *                       been updated.
 * @param fractalInfo The \c MDBFractalDocumentInfo object that has been updated.
 * @param index The index of \c fractalInfo, the updated \c MDBFractalDocumentInfo.
 */
- (void)documentController:(MDBDocumentController *)documentController didremoveFractalInfo:(MDBFractalInfo *)fractalInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the document controller is no longer tracking \c fractalInfo.
 * Receivers of this method should update their UI accordingly.
 *
 * @param documentController The \c MDBDocumentController instance that removed \c fractalInfo.
 * @param fractalInfo The removed \c MDBFractalDocumentInfo object.
 * @param index The index that \c fractalInfo was removed at.
 */
- (void)documentController:(MDBDocumentController *)documentController didUpdateFractalInfo:(MDBFractalInfo *)fractalInfo atIndex:(NSInteger)index;

/*!
 * Notifies the receiver of this method that the document controller did change it's contents in some form.
 * This method is *always* called after any insert, remove, or update is received. In this method, you
 * should finish off changes to your UI that were related to any insert, remove, or update. For an example
 * of how you might handle a "did change" contents call, see the discussion for \c -documentControllerWillChangeContent:.
 *
 * @param documentController The \c MDBDocumentController instance that did change its content.
 */
- (void)documentControllerDidChangeContent:(MDBDocumentController *)documentController;

/*!
 * Notifies the receiver of this method that an error occured when creating a new \c MDBFractalDocumentInfo object.
 * In implementing this method, you should present the error to the user. Do not rely on the \c MDBFractalDocumentInfo
 * instance to be valid since an error occured in creating the object.
 *
 * @param documentController The \c MDBDocumentController that is notifying that a failure occured.
 * @param fractalInfo The \c MDBFractalDocumentInfo that represents the document that couldn't be created.
 * @param error The error that occured.
 */
- (void)documentController:(MDBDocumentController *)documentController didFailCreatingFractalInfo:(MDBFractalInfo *)fractalInfo withError:(NSError *)error;

/*!
 * Notifies the receiver of this method that an error occured when removing an existing \c MDBFractalDocumentInfo
 * object. In implementing this method, you should present the error to the user.
 *
 * @param documentController The \c MDBDocumentController that is notifying that a failure occured.
 * @param fractalInfo The \c MDBFractalDocumentInfo that represents the document that couldn't be removed.
 * @param error The error that occured.
 */
- (void)documentController:(MDBDocumentController *)documentController didFailRemovingFractalInfo:(MDBFractalInfo *)fractalInfo withError:(NSError *)error;

@end

/*!
 A collection type object with a collection of MDBFractalDocumentInfo objects from the file system or cloud.
 
 :returns: 
 */
@interface MDBDocumentController : NSObject

/*!
 * Initializes an \c MDBFractalDocumentController instance with an initial \c MDBFractalDocumentCoordinator object and a
 * sort comparator (if any). If sort comparator is nil, the controller ignores sort order.
 *
 * @param documentCoordinator The \c MDBFractalDocumentController object's initial \c MDBFractalDocumentCoordinator.
 * @param sortComparator The predicate that determines the strict sort ordering of the \c AAPLdocumentInfos
 *                       array.
 */
- (instancetype)initWithDocumentCoordinator:(id<MDBFractalDocumentCoordinator>)documentCoordinator sortComparator:(NSComparisonResult (^)(MDBFractalInfo *lhs, MDBFractalInfo *rhs))sortComparator;

/*!
 * The \c MDBFractalDocumentController object's delegate who is responsible for responding to \c MDBFractalDocumentController
 * changes.
 */
@property (nonatomic, weak) id<MDBFractalDocumentControllerDelegate> delegate;

/*!
 * @return The number of tracked \c MDBFractalDocumentInfo objects.
 */
@property (nonatomic, readonly) NSInteger count;

/*!
 * The current \c MDBFractalDocumentCoordinator that the document controller manages.
 */
@property (nonatomic, strong) id<MDBFractalDocumentCoordinator> documentCoordinator;

/*!
 * @return The \c MDBFractalDocumentInfo instance at a specific index. This method traps if the index is out
 *         of bounds.
 */
- (MDBFractalInfo *)objectAtIndexedSubscript:(NSInteger)index;

/*!
 * Removes \c fractalInfo from the tracked \c DocumentInfo instances. This method forwards the remove operation
 * directly to the document coordinator. The operation can be performed asynchronously so long as the
 * underlying \c MDBFractalDocumentCoordinator instance sends the \c MDBFractalDocumentController the correct delegate
 * messages: either a \c -documentCoordinatorDidUpdateContentsWithInsertedURLs:removedURLs:updatedURLs:
 * call with the removed \c MDBFractalDocumentInfo object, or with an error callback.
 *
 * @param fractalInfo The \c MDBFractalDocumentInfo object to remove from the document of tracked \c MDBFractalDocumentInfo
 *                 instances.
 */
- (void)removeFractalInfo:(MDBFractalInfo *)fractalInfo;

/*!
 * Attempts to create \c MDBFractalDocumentInfo representing \c document with the given name. If the method is succesful,
 * the document controller adds it to the document of tracked \c MDBFractalDocumentInfo instances. This method forwards
 * the create operation directly to the document coordinator. The operation can be performed asynchronously
 * so long as the underlying \c MDBFractalDocumentCoordinator instance sends the \c MDBFractalDocumentController the correct
 * delegate messages: either a \c -documentCoordinatorDidUpdateContentsWithInsertedURLs:removedURLs:updatedURLs:
 * call with the newly inserted \c MDBFractalDocumentInfo, or with an error callback.
 *
 * Note: it's important that before calling this method, a call to \c -canCreateFractalWithName: is
 * performed to make sure that the name is a valid document name. Doing so will decrease the errors that
 * you see when you actually create a document.
 *
 * @param document The \c MDBFractalDocument object that should be used to save the initial document.
 * @param name The name of the new document.
 */
- (void)createFractalInfoForFractal:(LSFractal *)fractal withIdentifier:(NSString *)name;

/*!
 * Determines whether or not a document can be created with a given name. This method delegates to
 * \c documentCoordinator to actually check to see if the document can be created with the given name. This
 * method should be called before \c -createDocumentInfoForDocument:withName: is called to ensure to minimize
 * the number of errors that can occur when creating a document.
 *
 * @param name The name to check to see if it's valid or not.
 *
 * @return \c YES if the document can be created with the given name, \c NO otherwise.
 */
- (BOOL)canCreateFractalInfoWithIdentifier:(NSString *)name;

/*!
 * Lets the \c MDBFractalDocumentController know that \c fractalInfo has been udpdated. Once the change is reflected
 * in \c documentInfos array, a didUpdateDocumentInfo message is sent.
 *
 * @param fractalInfo The \c MDBFractalDocumentInfo instance that has new content.
 */
- (void)setFractalInfoHasNewContents:(MDBFractalInfo *)fractalInfo;

@end
