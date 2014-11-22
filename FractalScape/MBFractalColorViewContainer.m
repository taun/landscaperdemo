//
//  MBFractalColorViewContainer.m
//  FractalScape
//
//  Created by Taun Chapman on 11/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBFractalColorViewContainer.h"
#import "MBLSRuleCollectionViewCell.h"
#import "MBColor+addons.h"

#import "QuartzHelpers.h"

@interface MBFractalColorViewContainer ()

@property (nonatomic,strong) MBDraggingItem                     *draggingItem;

@end

@implementation MBFractalColorViewContainer

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _colorsChanged = YES;
    }
    return self;
}
-(void)awakeFromNib {
    [super awakeFromNib];
    _colorsChanged = YES;
}
-(void)viewDidLoad {
    // seems to be a bug in that the tintColor is not being used unless I re-set it.
    // this way it still takes the tintColor from IB.
    _lineColorsTemplateImageView.tintColor = _lineColorsTemplateImageView.tintColor;
    _fillColorsTemplateImageView.tintColor = _fillColorsTemplateImageView.tintColor;
    _pageColorTemplateImage.tintColor = _pageColorTemplateImage.tintColor;
    
    [super viewDidLoad];
}
-(void) viewDidAppear:(BOOL)animated {
    [self setupChildViewController:(UIViewController<FractalControllerProtocol> *)[self.childViewControllers firstObject]];
    
    // must be after child setup
    [super viewDidAppear:animated];
}
-(void) viewDidDisappear:(BOOL)animated {
    [self saveContext];
    [super viewDidDisappear:animated];
}
- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.fractal.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } else {
            //            self.fractalDataChanged = YES;
        }
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void) setupChildViewController:(UIViewController<FractalControllerProtocol>*)fractalController {
    fractalController.fractalUndoManager = self.fractalUndoManager;
    fractalController.fractal = self.fractal;
}

-(void)setFractal:(LSFractal *)fractal {
    _fractal = fractal;
    self.colorsChanged = YES;
    [self.fractalLineColorsDestinationCollection reloadData];
    [self.fractalFillColorsDestinationCollection reloadData];

}
-(NSArray*)cachedFractalColors {
    if (_fractal && (!_cachedFractalColors || self.colorsChanged)) {
        NSSortDescriptor* indexSort = [NSSortDescriptor sortDescriptorWithKey: @"index" ascending: YES];

        NSSet* lineColors = self.fractal.lineColors;
        NSArray* cachedFractalLineColors = [lineColors sortedArrayUsingDescriptors: @[indexSort]];

        NSSet* fillColors = self.fractal.fillColors;
        NSArray* cachedFractalFillColors = [fillColors sortedArrayUsingDescriptors: @[indexSort]];
        
        _cachedFractalColors = @[cachedFractalLineColors,cachedFractalFillColors];
    }
    return _cachedFractalColors;
}

-(void)viewWillLayoutSubviews {
    UIView* containerView = self.colorCollectionContainer;
    UIView* collectionViewWrapper = [containerView.subviews firstObject];
    UIView* collectionView = [collectionViewWrapper.subviews firstObject];
    
    NSLayoutConstraint* leftConstraint = [NSLayoutConstraint constraintWithItem:collectionView
                                                                       attribute:NSLayoutAttributeLeft
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:collectionViewWrapper
                                                                       attribute:NSLayoutAttributeLeft
                                                                      multiplier:1.0
                                                                        constant:0.0
                                           ];
    NSLayoutConstraint* rightConstraint = [NSLayoutConstraint constraintWithItem:collectionView
                                                                       attribute:NSLayoutAttributeRight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:collectionViewWrapper
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1.0
                                                                        constant:0.0
                                           ];
    
    NSLayoutConstraint* topConstraint = [NSLayoutConstraint constraintWithItem:collectionView
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:collectionViewWrapper
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:56.0
                                             ];
    NSLayoutConstraint* bottomConstraint = [NSLayoutConstraint constraintWithItem:collectionView
                                                                         attribute:NSLayoutAttributeBottom
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:collectionViewWrapper
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0
                                                                          constant:0.0
                                             ];
    [collectionViewWrapper addConstraints:@[leftConstraint,rightConstraint,topConstraint,bottomConstraint]];
    [collectionView setTranslatesAutoresizingMaskIntoConstraints: NO];
    
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    if (collectionView == self.fractalLineColorsDestinationCollection) {
        section = 0;
    } else {
        section = 1;
    }
    
    return [self.cachedFractalColors[section] count] + 1;
}
-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger section;
    
    if (collectionView == self.fractalLineColorsDestinationCollection) {
        section = 0;
    } else {
        section = 1;
    }
    
    static NSString *CellIdentifier = @"DestinationColorSwatchCell";
    MBLSRuleCollectionViewCell *cell = (MBLSRuleCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        
    if (indexPath.row < [self.cachedFractalColors[section] count]) {
        // we have a color
        MBColor* managedObjectColor = self.cachedFractalColors[section][indexPath.row];
        cell.cellItem = managedObjectColor;
    } else {
        // use a placeholder
        cell.cellItem = nil;
    }
    
    return cell;
}

#pragma mark - Drag&Drop

- (IBAction)lineColorLongPress:(UILongPressGestureRecognizer *)gesture {
    UIGestureRecognizerState gestureState = gesture.state;
    
    if (gestureState == UIGestureRecognizerStateBegan) {
        [self dragDidStartAtSourceCollection: self withGesture: gesture];
        
    } else if (gestureState == UIGestureRecognizerStateChanged) {
        [self dragDidChangeAtSourceCollection: self withGesture: gesture];
        
    } else if (gestureState == UIGestureRecognizerStateEnded) {
        [self dragDidEndAtSourceCollection: self withGesture: gesture];
        
    } else if (gestureState == UIGestureRecognizerStateCancelled) {
        [self dragCancelledAtSourceCollection: self withGesture: gesture];
        
    }
}

- (IBAction)fillColorLongPress:(UILongPressGestureRecognizer *)gesture {
}

-(UIView*) lineColorDragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    return nil;
}

-(BOOL) lineColorDragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    return NO;
}

-(BOOL) lineColorDragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    return NO;
}

-(BOOL) lineColorDragDidEndDraggingItem: (MBDraggingItem*) draggingRule {
    return NO;
}

-(BOOL) lineColorDragDidExitDraggingItem: (MBDraggingItem*) draggingRule {
    return NO;
}

-(UIView*) fillColorDragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    return nil;
}

-(BOOL) fillColorDragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    return NO;
}

-(BOOL) fillColorDragDidChangeToLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    return NO;
}

-(BOOL) fillColorDragDidEndDraggingItem: (MBDraggingItem*) draggingRule {
    return NO;
}

-(BOOL) fillColorDragDidExitDraggingItem: (MBDraggingItem*) draggingRule {
    return NO;
}


-(void)dragDidStartAtSourceCollection: (MBColorSourceCollectionViewController*) collectionViewController withGesture: (UIGestureRecognizer*) gesture {
    CGPoint touchPoint = [gesture locationInView: collectionViewController.collectionView];

    if (!self.draggingItem) {
        self.draggingItem = [[MBDraggingItem alloc] initWithItem: nil size: 26.0];
        //        self.draggingRule = [[MBDraggingRule alloc] init];
        //        self.draggingRule.size = 30;
        self.draggingItem.touchToDragViewOffset = CGPointMake(0.0, -40.0);
    }

    UIView* draggingView = [collectionViewController dragDidStartAtLocalPoint: touchPoint draggingItem: self.draggingItem];
    
    if (draggingView) {
        [self.view addSubview: draggingView];
        CGPoint localPoint = [gesture locationInView: self.view];
        self.draggingItem.viewCenter = localPoint;
    }
}
- (void)updateDestinationCellAtIndex:(NSIndexPath *)lineCellIndex gesture:(UIGestureRecognizer *)gesture collectionViewController:(MBColorSourceCollectionViewController *)collectionViewController {
}

-(void)dragDidChangeAtSourceCollection: (MBColorSourceCollectionViewController*) collectionViewController withGesture: (UIGestureRecognizer*) gesture {
    if (self.draggingItem) {
        CGRect bounds = self.view.bounds;
        CGPoint touchPoint = [gesture locationInView: self.view];
        CGPoint constrainedPoint = CGPointConfineToRect(touchPoint, bounds);
        // Keep dragged view within the table bounds
        self.draggingItem.viewCenter = constrainedPoint;
        
        CGRect pageColorFrame = self.pageColorDestinationImageView.bounds;
        CGRect superPageColorRect = [self.view convertRect: pageColorFrame fromView: self.pageColorDestinationImageView];
        BOOL overPageColor = CGRectContainsPoint(superPageColorRect, self.draggingItem.viewCenter);
        
#pragma message "TODO: use the page cells did enter and exit protocol so color can be reverted when drag exits."
        if (overPageColor) {
            // drop for page color
            if (self.pageColorDestinationImageView.image != [self.draggingItem.dragItem asImage]) {
                self.pageColorDestinationImageView.image = [self.draggingItem.dragItem asImage];
                self.fractal.backgroundColor = self.draggingItem.dragItem;
            }
        } else {
            CGPoint lineColorsCollectionPoint = [self.view convertPoint: self.draggingItem.viewCenter toView: self.fractalLineColorsDestinationCollection];
            NSIndexPath* lineCellIndex = [self.fractalLineColorsDestinationCollection indexPathForItemAtPoint: lineColorsCollectionPoint];
            if (lineCellIndex) {
                MBLSRuleCollectionViewCell* destinationCell = (MBLSRuleCollectionViewCell*)[self.fractalLineColorsDestinationCollection cellForItemAtIndexPath: lineCellIndex];
                MBColor* color = destinationCell.cellItem;
                if (!color) {
                    // over a placeholder so replace with a color
                    if (self.draggingItem.dragItem != color) {
                        // only add once
                        NSInteger newIndex = [self.cachedFractalColors[0] count];
                        MBColor* newColor = (MBColor*)self.draggingItem.dragItem;
                        newColor.index = @(newIndex);
                        [newColor addFractalLinesObject: self.fractal];
                        self.colorsChanged = YES;
                        [self.fractalLineColorsDestinationCollection reloadData];
                        [self dragDidEndAtSourceCollection: collectionViewController withGesture: gesture];
                    }
                }
            } else {
                CGPoint fillColorsCollectionPoint = [self.view convertPoint: self.draggingItem.viewCenter toView: self.fractalFillColorsDestinationCollection];
                NSIndexPath* fillCellIndex = [self.fractalFillColorsDestinationCollection indexPathForItemAtPoint: fillColorsCollectionPoint];
                if (fillCellIndex) {
                    MBLSRuleCollectionViewCell* destinationCell = (MBLSRuleCollectionViewCell*)[self.fractalFillColorsDestinationCollection cellForItemAtIndexPath: fillCellIndex];
                    MBColor* color = destinationCell.cellItem;
                    if (!color) {
                        // over a placeholder so replace with a color
                        if (self.draggingItem.dragItem != color) {
                            // only add once
                            NSInteger newIndex = [self.cachedFractalColors[1] count];
                            MBColor* newColor = (MBColor*)self.draggingItem.dragItem;
                            newColor.index = @(newIndex);
                            [newColor addFractalFillsObject: self.fractal];
                            self.colorsChanged = YES;
                            [self.fractalFillColorsDestinationCollection reloadData];
                            [self dragDidEndAtSourceCollection: collectionViewController withGesture: gesture];
                        }
                    }
                }
            }
        }
    }
}

-(void)dragDidEndAtSourceCollection: (MBColorSourceCollectionViewController*) collectionViewController withGesture: (UIGestureRecognizer*) gesture {
    [self.draggingItem.view removeFromSuperview];
    self.draggingItem = nil;
}

-(void)dragCancelledAtSourceCollection: (MBColorSourceCollectionViewController*) collectionViewController withGesture: (UIGestureRecognizer*) gesture {
    [self.draggingItem.view removeFromSuperview];
    self.draggingItem = nil;
}


-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    UIView* returnView;
//    MDKUICollectionViewScrollContentSized* strongCollectionView = self.collectionView;
//    
//    CGPoint collectionLoc = [self convertPoint: point toView: strongCollectionView];
//    NSIndexPath* ruleIndexPath = [strongCollectionView indexPathForItemAtPoint: collectionLoc];
//    MBLSRuleCollectionViewCell* collectionSourceCell = (MBLSRuleCollectionViewCell*)[strongCollectionView cellForItemAtIndexPath: ruleIndexPath];
//    
//    if (collectionSourceCell) {
//        LSDrawingRule* draggedRule;
//        if (_isReadOnly) {
//            draggedRule = [collectionSourceCell.cellItem mutableCopy];
//        } else {
//            draggedRule = collectionSourceCell.cellItem;
//        }
//        
//        draggingRule.dragItem = draggedRule;
//        
//        returnView = draggingRule.view;
//    }
    return returnView;
}

#pragma message "There is a possibility this is entered for the same view right after the didStart"
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    BOOL reloadContainer = NO;
//    MDKUICollectionViewScrollContentSized* strongCollectionView = self.collectionView;
//    
//    if (!self.isReadOnly) {
//        CGRect collectionRect = [self convertRect: strongCollectionView.bounds fromView: strongCollectionView];
//        
//        if (CGRectContainsPoint(collectionRect, point)) {
//            CGPoint collectionLoc = [self convertPoint: point toView: strongCollectionView];
//            NSIndexPath* rulesCollectionIndexPath = [self.collectionView indexPathForDropInSection: 0 atPoint: collectionLoc];
//            
//            if (rulesCollectionIndexPath && ![self.rules containsObject: draggingRule.dragItem]) {
//                // If the rule is already here and we are entering, it is a case where the rule was not removed on exit. This would be if it was the last/only rule in the set.
//                // is the touch over a cell or at the end. indexPath will be nil in cell margins.
//                reloadContainer = strongCollectionView.nextItemWillWrapLine;
//                [self willChangeNotify];
//                [self.rules insertObject: draggingRule.dragItem atIndex: rulesCollectionIndexPath.row];
//                [strongCollectionView insertItemsAtIndexPaths: @[rulesCollectionIndexPath]];
//                [self didChangeNotify];
//            }
//            
//            //        } else if ([draggingRule.lastTableIndexPath compare: draggingRule.currentIndexPath] == NSOrderedSame) {
//            //            [self dragDidExitDraggingRule: draggingRule];
//        }
//    }
//    
    return reloadContainer;
}
-(BOOL) dragDidChangeToLocalPoint:(CGPoint)point draggingItem:(MBDraggingItem *)draggingRule {
    BOOL reloadContainer = NO;
//    MDKUICollectionViewScrollContentSized* strongCollectionView = self.collectionView;
//    
//    if (!self.isReadOnly) {
//        CGRect collectionRect = [self convertRect: strongCollectionView.bounds fromView: strongCollectionView];
//        
//        if (CGRectContainsPoint(collectionRect, point)) {
//            NSInteger oldIndex = [self.rules indexOfObject: draggingRule.dragItem];
//            if (oldIndex != NSNotFound) {
//                // was already here and just a change
//                // only change if collection indexPath changed.
//                CGPoint collectionLoc = [self convertPoint: point toView: strongCollectionView];
//                NSIndexPath* rulesCollectionIndexPath = [strongCollectionView indexPathForDropInSection: 0 atPoint: collectionLoc];
//                
//                NSInteger lastCellRow = [strongCollectionView numberOfItemsInSection: 0] - 1;
//                
//                // check if the insertion path is past the last row
//                if (lastCellRow < rulesCollectionIndexPath.row) {
//                    rulesCollectionIndexPath = [NSIndexPath indexPathForItem: rulesCollectionIndexPath.row-1 inSection: rulesCollectionIndexPath.section];
//                }
//                
//                if (rulesCollectionIndexPath != nil && rulesCollectionIndexPath.row != oldIndex) {
//                    [self willChangeNotify];
//                    [self.rules moveObjectsAtIndexes: [NSIndexSet indexSetWithIndex: oldIndex] toIndex: rulesCollectionIndexPath.row];
//                    [strongCollectionView moveItemAtIndexPath: [NSIndexPath indexPathForRow: oldIndex inSection: 0] toIndexPath: rulesCollectionIndexPath];
//                    [self didChangeNotify];
//                }
//            } else {
//                // rule was not found in collection so it is in enter state
//                reloadContainer = [self dragDidEnterAtLocalPoint: point draggingItem: draggingRule];
//            }
//        }
//    }
    return reloadContainer;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL reloadContainer = NO;
//    MDKUICollectionViewScrollContentSized* strongCollectionView = self.collectionView;
//    
//    if (!self.isReadOnly && self.rules.count > 1) {
//        NSUInteger removeIndex = [self.rules indexOfObject: draggingRule.dragItem];
//        if (removeIndex != NSNotFound) {
//            [self willChangeNotify];
//            [self.rules removeObjectAtIndex: removeIndex];
//            [strongCollectionView deleteItemsAtIndexPaths: @[[NSIndexPath indexPathForRow: removeIndex inSection: 0]]];
//            [self didChangeNotify];
//            reloadContainer = strongCollectionView.nextItemWillWrapLine; // If removing item unwraps, then reload to shrink.
//        }
//    }
    return reloadContainer;
}
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL reloadContainer = NO;
    return reloadContainer;
}



@end
