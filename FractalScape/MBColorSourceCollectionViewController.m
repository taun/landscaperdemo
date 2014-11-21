//
//  MBColorSourceCollectionViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/06/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBColorSourceCollectionViewController.h"
#import "MBAppDelegate.h"
#import "MBLSRuleCollectionViewCell.h"
#import "MBFractalColorViewContainer.h"
#import "MBColor+addons.h"
#import "NSManagedObject+Shortcuts.h"

#import "QuartzHelpers.h"


#import "MBCollectionFractalSupplementaryLabel.h" // from Library collectionView
static NSString *kSupplementaryHeaderCellIdentifier = @"ColorsHeader";

@interface MBColorSourceCollectionViewController ()

@property (nonatomic,strong) MBDraggingItem                     *draggingItem;

@end

@implementation MBColorSourceCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) initControls {
    // need to set current selection
    // use selectItemAtIndexPath:animated:scrollPosition:
    // need to determine index of selectedFractal
    // perhaps make part of selectedFractal setter?
}

-(void)setFractal:(LSFractal *)fractal {
    _fractal = fractal;
    [self.collectionView reloadData];    
}

//-(NSManagedObjectContext*) appManagedObjectContext {
//    
//    UIApplication* app = [UIApplication sharedApplication];
//    MBAppDelegate* appDelegate = [app delegate];
//    NSManagedObjectContext* appContext = appDelegate.managedObjectContext;
//    
//    return appContext;
//}
-(NSFetchedResultsController*) libraryColorsFetchedResultsController {
    if (_libraryColorsFetchedResultsController == nil) {
        // instantiate
        NSManagedObjectContext* context;
        UIViewController<FractalControllerProtocol>* parent = (UIViewController<FractalControllerProtocol>*)self.parentViewController;
        if (parent) {
            context = parent.fractal.managedObjectContext;
            
            if (context) {
                NSManagedObjectContext* appContext = context;
                
                NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
                NSEntityDescription* entity = [MBColor entityDescriptionForContext: context];
                [fetchRequest setEntity: entity];
                [fetchRequest setFetchBatchSize: 40];
                
                NSSortDescriptor* category = [NSSortDescriptor sortDescriptorWithKey: @"category.identifier" ascending: YES];
                NSSortDescriptor* index = [NSSortDescriptor sortDescriptorWithKey: @"index" ascending: YES];
                NSArray* sortDescriptors = @[category, index];
                [fetchRequest setSortDescriptors: sortDescriptors];
                
                NSPredicate* filterPredicate = [NSPredicate predicateWithFormat: @"category != NIL"];
                [fetchRequest setPredicate: filterPredicate];
                
                _libraryColorsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest managedObjectContext: appContext sectionNameKeyPath: @"category.name" cacheName: nil]; //@"colorLibraryCache"
                
                _libraryColorsFetchedResultsController.delegate = self;
                
                NSError* error = nil;
                
                if (![_libraryColorsFetchedResultsController performFetch: &error]) {
                    NSLog(@"Fetched Results Error %@, %@", error, [error userInfo]);
                    abort();
                }
            }
        
        }
    }
    
    return _libraryColorsFetchedResultsController;
}

#pragma mark - NSFetchedResultsControllerDelegate conformance -
-(void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.collectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [[self.libraryColorsFetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)table numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.libraryColorsFetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    MBCollectionFractalSupplementaryLabel* rView = [collectionView dequeueReusableSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                                                                                      withReuseIdentifier: kSupplementaryHeaderCellIdentifier
                                                                                             forIndexPath: indexPath];
    
    rView.textLabel.text = [[self.libraryColorsFetchedResultsController sections][indexPath.section] name];
    
    return rView;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"SourceColorSwatchCell";
    
    MBLSRuleCollectionViewCell *cell = (MBLSRuleCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    //    if (cell == nil) {
    //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    //    }
    MBColor* managedObjectColor;
    
    managedObjectColor = (MBColor*)[self.libraryColorsFetchedResultsController objectAtIndexPath: indexPath];
    cell.cellItem = managedObjectColor;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}



- (IBAction)collectionLongPress:(UILongPressGestureRecognizer*)gesture {
    UIGestureRecognizerState gestureState = gesture.state;
    
    MBFractalColorViewContainer* viewContainerController = (MBFractalColorViewContainer*)self.parentViewController;
    
    if (gestureState == UIGestureRecognizerStateBegan) {
        [viewContainerController dragDidStartAtSourceCollection: self withGesture: gesture];
        
    } else if (gestureState == UIGestureRecognizerStateChanged) {
        [viewContainerController dragDidChangeAtSourceCollection: self withGesture: gesture];
        
    } else if (gestureState == UIGestureRecognizerStateEnded) {
        [viewContainerController dragDidEndAtSourceCollection: self withGesture: gesture];
        
    } else if (gestureState == UIGestureRecognizerStateCancelled) {
        [viewContainerController dragCancelledAtSourceCollection: self withGesture: gesture];

    }
}

-(UIView*) dragDidStartAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingItem {
    UIView* returnView;
    UICollectionView* strongCollectionView = self.collectionView;
    
    NSIndexPath* cellIndexPath = [strongCollectionView indexPathForItemAtPoint: point];
    MBLSRuleCollectionViewCell* collectionSourceCell = (MBLSRuleCollectionViewCell*)[strongCollectionView cellForItemAtIndexPath: cellIndexPath];
    
    if (collectionSourceCell) {
        id draggedItem = [collectionSourceCell.cellItem mutableCopy];
        
        draggingItem.dragItem = draggedItem;
        
        returnView = draggingItem.view;
    }
    return returnView;
}
-(BOOL) dragDidEnterAtLocalPoint: (CGPoint)point draggingItem: (MBDraggingItem*) draggingRule {
    BOOL reloadContainer = NO;
    return reloadContainer;
}
-(BOOL) dragDidChangeToLocalPoint:(CGPoint)point draggingItem:(MBDraggingItem *)draggingRule {
    BOOL reloadContainer = NO;
    return reloadContainer;
}
-(BOOL) dragDidExitDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL reloadContainer = NO;
    return reloadContainer;
}
-(BOOL) dragDidEndDraggingItem: (MBDraggingItem*) draggingRule {
    BOOL reloadContainer = NO;
    return reloadContainer;
}



@end
