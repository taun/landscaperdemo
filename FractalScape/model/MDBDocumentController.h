//
//  MDBDocumentController.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/03/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;

#import "MDBFractalDocumentCoordinator.h"

@class MDBDocumentController, MDBFractalInfo, MDBFractalDocument, LSFractal;

@protocol MDBFractalDocumentCoordinator;


@protocol MDBFractalDocumentControllerDelegate <NSObject>

/*!
 * Notifies the receiver of this method that the document controller will change it's contents in some
 * form. This method is *always* called before any insert, remove, or update is received. In this method,
 * you should prepare your UI for making any changes related to the changes that you will need to reflect
 * once they are received. For example, if you have a table view in your UI that needs to respond to
 * changes to a newly inserted \c MDBFractalInfo object, you would want to call your table view's
 * \c -beginUpdates method. Once all of the updates are performed, your \c -documentControllerDidChangeContent:
 * method will be called. This is where you would to call your table view's \c -endUpdates method.
 *
 * @param documentController The \c MDBDocumentController instance that will change its content.
 */
- (void)documentControllerWillChangeContent:(MDBDocumentController *)documentController;
/*!
 * Notifies the receiver of this method that the document controller is tracking a new \c MDBFractalInfo
 * object. Receivers of this method should update their UI accordingly.
 *
 * @param documentController The \c MDBDocumentController instance that inserted the new \c MDBFractalInfo.
 * @param fractalInfo The new \c MDBFractalInfo object that has been inserted at \c index.
 * @param index The index that \c fractalInfo was inserted at.
 */
- (void)documentController:(MDBDocumentController *)documentController didInsertFractalInfosAtIndexPaths:(NSArray*)index totalRows: (NSInteger)rows;

- (void)documentController:(MDBDocumentController *)documentController didMoveFractalInfoAtIndexPath:(NSIndexPath*)fromIndex toIndexPath: (NSIndexPath*)toIndex;

/*!
 * Notifies the receiver of this method that the document controller received a message that \c fractalInfo
 * has updated its content. Receivers of this method should update their UI accordingly.
 *
 * @param documentController The \c MDBDocumentController instance that was notified that \c fractalInfo has
 *                       been updated.
 * @param fractalInfo The \c MDBFractalInfo object that has been updated.
 * @param index The index of \c fractalInfo, the updated \c MDBFractalInfo.
 */
- (void)documentController:(MDBDocumentController *)documentController didRemoveFractalInfosAtIndexPaths:(NSArray*)index totalRows: (NSInteger)rows;

/*!
 * Notifies the receiver of this method that the document controller is no longer tracking \c fractalInfo.
 * Receivers of this method should update their UI accordingly.
 *
 * @param documentController The \c MDBDocumentController instance that removed \c fractalInfo.
 * @param fractalInfo The removed \c MDBFractalInfo object.
 * @param index The index that \c fractalInfo was removed at.
 */
- (void)documentController:(MDBDocumentController *)documentController didUpdateFractalInfosAtIndexPaths:(NSArray*)index totalRows: (NSInteger)rows;

#pragma message "TODO: add method didMoveFractalInfosAtIndexPaths:toIndexPaths:totalRows;"
/*
 It would be called when setFractalInfoHasNewContents: is called to move the updated fractal to the front in sort by change date."
*/

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
 * Notifies the receiver of this method that an error occured when creating a new \c MDBFractalInfo object.
 * In implementing this method, you should present the error to the user. Do not rely on the \c MDBFractalInfo
 * instance to be valid since an error occured in creating the object.
 *
 * @param documentController The \c MDBDocumentController that is notifying that a failure occured.
 * @param fractalInfo The \c MDBFractalInfo that represents the document that couldn't be created.
 * @param error The error that occured.
 */
- (void)documentController:(MDBDocumentController *)documentController didFailCreatingFractalInfo:(MDBFractalInfo *)fractalInfo withError:(NSError *)error;

/*!
 * Notifies the receiver of this method that an error occured when removing an existing \c MDBFractalInfo
 * object. In implementing this method, you should present the error to the user.
 *
 * @param documentController The \c MDBDocumentController that is notifying that a failure occured.
 * @param fractalInfo The \c MDBFractalInfo that represents the document that couldn't be removed.
 * @param error The error that occured.
 */
- (void)documentController:(MDBDocumentController *)documentController didFailRemovingFractalInfo:(MDBFractalInfo *)fractalInfo withError:(NSError *)error;


@end

/*!
 A collection type object with a collection of MDBFractalInfo objects from the file system or cloud.
 
 :returns: 
 */
@interface MDBDocumentController : NSObject <MDBFractalDocumentCoordinatorDelegate>

/*!
 * Initializes an \c MDBFractalDocumentController instance with an initial \c MDBFractalDocumentCoordinator object and a
 * sort comparator (if any). If sort comparator is nil, the controller ignores sort order.
 *
 * @param documentCoordinator The \c MDBFractalDocumentController object's initial \c MDBFractalDocumentCoordinator.
 * @param sortComparator The predicate that determines the strict sort ordering of the \c MDBFractalInfo
 *                       array.
 */
- (instancetype)initWithDocumentCoordinator:(id<MDBFractalDocumentCoordinator>)documentCoordinator sortComparator:(NSComparisonResult (^)(MDBFractalInfo *lhs, MDBFractalInfo *rhs))sortComparator;

/*!
 * The sort comparator that's set in initialization. The sort predicate ensures a strict sort ordering
 * of the \c documentInfos array. If \c sortComparator is nil, the sort order is ignored.
 */
@property (nonatomic, copy) NSComparisonResult (^sortComparator)(MDBFractalInfo *lhs, MDBFractalInfo *rhs);

/*!
 * The \c MDBFractalDocumentController object's delegate who is responsible for responding to \c MDBFractalDocumentController
 * changes.
 */
@property (nonatomic, weak) id<MDBFractalDocumentControllerDelegate> delegate;

///*!
// * @return The number of tracked \c MDBFractalInfo objects.
// */
//@property (nonatomic, readonly) NSInteger count;

/*!
 * The current \c MDBFractalDocumentCoordinator that the document controller manages.
 */
@property (nonatomic, strong) id<MDBFractalDocumentCoordinator> documentCoordinator;

@property (atomic, strong, readonly) NSMutableArray*                      fractalInfos;

///*!
// * @return The \c MDBFractalInfo instance at a specific index. This method traps if the index is out
// *         of bounds.
// */
//- (MDBFractalInfo *)objectAtIndexedSubscript:(NSInteger)index;
//
//- (NSUInteger) indexOfObject: (id) object;

- (MDBFractalInfo *)controllerFractalInfoFor: (MDBFractalInfo*)fractalInfo;
/*!
 * Removes \c fractalInfo from the tracked \c DocumentInfo instances. This method forwards the remove operation
 * directly to the document coordinator. The operation can be performed asynchronously so long as the
 * underlying \c MDBFractalDocumentCoordinator instance sends the \c MDBFractalDocumentController the correct delegate
 * messages: either a \c -documentCoordinatorDidUpdateContentsWithInsertedURLs:removedURLs:updatedURLs:
 * call with the removed \c MDBFractalInfo object, or with an error callback.
 *
 * @param fractalInfo The \c MDBFractalInfo object to remove from the document of tracked \c MDBFractalInfo
 *                 instances.
 */
- (void)removeFractalInfo:(MDBFractalInfo *)fractalInfo;

/*!
 Create a MDBFractalInfo synchronously and save it. It is given a random UUID name.
 
 @param fractal the fractal to be stored in the document
 @param id the document delegate
 */
- (MDBFractalInfo*)createFractalInfoForFractal:(LSFractal *)fractal withDocumentDelegate: (id)delegate;

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
 * @param fractalInfo The \c MDBFractalInfo instance that has new content.
 */
- (void)setFractalInfoHasNewContents:(MDBFractalInfo *)fractalInfo;

@end
