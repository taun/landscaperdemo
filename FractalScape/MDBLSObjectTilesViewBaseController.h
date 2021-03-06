//
//  MDBLSObjectTilesViewBaseController.h
//  
//
//  Created by Taun Chapman on 12/03/14.
//
//

@import Foundation;
@import UIKit;

#import "FractalControllerProtocol.h"

#import "MBLSRuleDragAndDropProtocol.h"
#import "MBDraggingItem.h"
#import "MBLSObjectListTileViewer.h"
#import "MDBLSObjectTileView.h"

#import "MBFractalPrefConstants.h"

@class MDBAppModel;

@interface MDBLSObjectTilesViewBaseController : UIViewController <FractalControllerProtocol>

@property (nonatomic,strong) MDBAppModel                      *appModel;
@property (nonatomic,strong) MDBFractalDocument             *fractalDocument;
@property (nonatomic,weak) NSUndoManager                    *fractalUndoManager;
@property (weak,nonatomic) id<FractalControllerDelegate>    fractalControllerDelegate;
//@property(nonatomic,assign) CGSize                          portraitSize;
//@property(nonatomic,assign) CGSize                          landscapeSize;

@property (nonatomic,strong) MBDraggingItem                 *draggingItem;
/*!
 When dragging an item in the scroll content, autoScroll yes will scroll the content as the 
 dragged item gets to the top or bottom. Good if the drag destination is somewhere in the 
 scrollView content. 
 
 Default is no.
 */
@property (nonatomic,assign) BOOL                           autoScroll;
/*!
 To be instantiated with a view class representing the source of the tiles.
 */
@property (weak, nonatomic) IBOutlet id                             sourceListView;
/*!
 A destination for the tiles. More destinations can be added by the subclass.
 
 Use [MBLSObjectListTileViewer objectList] to assign the list of items.
 */
@property (weak, nonatomic) IBOutlet MBLSObjectListTileViewer       *destinationView;
/*!
 Only used for flashing the scrollbars during viewDidAppear.
 */
@property (weak, nonatomic) IBOutlet UIScrollView                   *scrollView;
@property (weak, nonatomic) IBOutlet UILabel                        *ruleHelpLabel;
@property (weak, nonatomic) IBOutlet UIVisualEffectView             *ruleHelpView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView             *visualEffectView;
@property (nonatomic,strong) UIMotionEffectGroup                    *foregroundMotionEffect;
@property (nonatomic,strong) UIMotionEffectGroup                    *backgroundMotionEffect;
@property (nonatomic,strong) UIView<MBLSRuleDragAndDropProtocol>    *lastDragViewContainer;
@property (nonatomic,strong) NSArray                                *allowedDestinationViews;
/*!
 Called during assignment of a new LSFractal instance.
 */
-(void) updateFractalDependents;
/*!
 Action to initiate a tile drag.
 
 @param sender the gesture recognaizer.
 */
- (IBAction)sourceDragLongGesture:(UIGestureRecognizer *)sender;
- (IBAction)sourceTapGesture:(UIGestureRecognizer *)sender;
/*!
 A convenience method to verify a destination classes drag and drop protocol compliance.
 
 @param anObject the potential destination class
 
 @return Whether the potential destination class can handle tile drag and drop.
 */
-(BOOL) handlesDragAndDrop: (id) anObject;
/*!
 Particular to CoreData. The fractal app models such as MBColor and LSDrawingRule are copied when 
 dragging from a readOnly source. This means there is no other reference to the instance and if it 
 is not dropped, it will be persisted forever. At the end of the drag and drop process, the draggedItem is
 check for references and deleted if there are none. 
 
 @warning *Important:* Checking the references is particular to each class so this needs to be overriden if subclassed.
 
 @param object the instance to be reference checked.
 */
-(void) deleteObjectIfUnreferenced: (id) object;

-(void) showInfoForView: (UIView*) aView;
-(void) infoAnimateView: (UIView*) aView;


@end
