//
//  MBFractalLibraryViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBAppDelegate.h"
#import "MBFractalLibraryViewController.h"
#import "LSFractalRenderer.h"
#import "LSFractal+addons.h"
#import "NSManagedObject+Shortcuts.h"

#import "MBCollectionFractalCell.h"
#import "MBCollectionFractalSupplementaryLabel.h"
#import "MBImmutableCellBackgroundView.h"

#import <QuartzCore/QuartzCore.h>

#include "Model/QuartzHelpers.h"

#include <math.h>

static NSString *kSupplementaryHeaderCellIdentifier = @"FractalLibraryCollectionHeader";

@interface MBFractalLibraryViewController () <NSFetchedResultsControllerDelegate> {
    CGSize _cachedThumbnailSize;
}

@property (nonatomic,strong) UIImage                        *cachedPlaceholderImage;
@property (nonatomic, strong) NSFetchedResultsController*   fetchedResultsController;

@property (nonatomic,strong) NSMutableDictionary*           fractalToThumbnailGenerators;
@property (nonatomic,strong) NSOperationQueue*              privateQueue;
@property (nonatomic,strong) NSMutableDictionary*           fractalToGeneratorOperations;

-(void) initControls;
-(CGSize) cachedThumbnailSizeForCell: (MBCollectionFractalCell*) cell;
-(UIImage*) placeHolderImageSized: (CGSize)size background: (UIColor*) color;

@end

@implementation MBFractalLibraryViewController

-(void) initControls {
    // need to set current selection
    // use selectItemAtIndexPath:animated:scrollPosition:
    // need to determine index of selectedFractal
    // perhaps make part of selectedFractal setter?
}

#pragma mark - custom getters -
-(CGSize) cachedThumbnailSizeForCell: (MBCollectionFractalCell*) cell {
    if (CGSizeEqualToSize(_cachedThumbnailSize, CGSizeZero)) {
        _cachedThumbnailSize = [cell.imageView systemLayoutSizeFittingSize: UILayoutFittingExpandedSize];
    }
    return _cachedThumbnailSize;
}
-(NSMutableDictionary*) fractalToThumbnailGenerators {
    if (!_fractalToThumbnailGenerators) {
        _fractalToThumbnailGenerators = [NSMutableDictionary new];
    }
    return _fractalToThumbnailGenerators;
}
-(NSMutableDictionary*) fractalToGeneratorOperations {
    if (!_fractalToGeneratorOperations) {
        _fractalToGeneratorOperations = [NSMutableDictionary new];
    }
    return _fractalToGeneratorOperations;
}
-(NSOperationQueue*) privateQueue {
    if (!_privateQueue) {
        _privateQueue = [[NSOperationQueue alloc] init];
    }
    return _privateQueue;
}

-(NSFetchedResultsController*) fetchedResultsController {
    if (self.fractal != nil && _fetchedResultsController == nil) {
        // instantiate
        NSManagedObjectContext* fractalContext = self.fractal.managedObjectContext;
        
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription* entity = [LSFractal entityDescriptionForContext: fractalContext];
        [fetchRequest setEntity: entity];
        [fetchRequest setFetchBatchSize: 20];
        NSSortDescriptor* nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];
        NSSortDescriptor* catSortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"category" ascending: YES];
        NSArray* sortDescriptors = @[catSortDescriptor, nameSortDescriptor];
        [fetchRequest setSortDescriptors: sortDescriptors];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest managedObjectContext: fractalContext sectionNameKeyPath: @"category" cacheName: nil];

        _fetchedResultsController.delegate = self;
        
        NSError* error = nil;
        
        if (![_fetchedResultsController performFetch: &error]) {
            NSLog(@"Fetched Results Error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return _fetchedResultsController;
}

#pragma mark - NSFetchedResultsControllerDelegate conformance -
-(void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.fractalCollectionView reloadData];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)table numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

-(UIImage*) placeHolderImageSized: (CGSize)size background: (UIColor*) uiColor {
    if (self.cachedPlaceholderImage && CGSizeEqualToSize(self.cachedPlaceholderImage.size, size)) {
        return self.cachedPlaceholderImage;
    } else {
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        CGRect viewRect = CGRectMake(0, 0, size.width, size.height);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(context);
        [uiColor setFill];
        CGContextFillRect(context, viewRect);
        CGContextRestoreGState(context);
        
        UIImage* thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.cachedPlaceholderImage = thumbnail;
        return thumbnail;
    }
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"FractalLibraryListCell";
    
    MBCollectionFractalCell *cell = (MBCollectionFractalCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//    }

    
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSManagedObjectID* objectID = managedObject.objectID;
    NSAssert(objectID, @"Fractal objectID should not be nil. Maybe it wasn't saved?");
    
    LSFractal* cellFractal = nil;
    if ([managedObject isKindOfClass: [LSFractal class]]) {
        cellFractal = (LSFractal*)managedObject;
    }
    
    NSAssert(cellFractal, @"Managed object should be a fractal.");
    
    // Configure the cell with data from the managed object.
    cell.textLabel.text = cellFractal.name;
    cell.detailTextLabel.text = cellFractal.descriptor;
    
    LSFractalRenderer* generator = (self.fractalToThumbnailGenerators)[objectID];
    
    CGSize thumbnailSize = [self cachedThumbnailSizeForCell: cell];
    
    UIColor* thumbNailBackground = [UIColor colorWithWhite: 1.0 alpha: 0.8];
    
    if (generator.image && [cellFractal.levelUnchanged boolValue] && [cellFractal.rulesUnchanged boolValue]) {
        cell.imageView.image = generator.image;
    } else {
        if (!generator) {
            // No generator yet
            generator = [LSFractalRenderer newRendererForFractal: cellFractal];
            generator.name = cellFractal.name;
            generator.imageView = cell.imageView;
            generator.flipY = YES;
            generator.margin = 10.0;
            generator.showOrigin = NO;
            generator.autoscale = YES;
#pragma message "TODO move generateLevelData to a privateQueue in case of large levels or just limit level?"
            
            (self.fractalToThumbnailGenerators)[objectID] = generator;
        }
        [cellFractal generateLevelData];
        generator.levelData = cellFractal.levelNRulesCache;
        
        NSBlockOperation* operation = generator.operation;
        
        // if the operation exists and is finished
        //      remove and queue a new operation
        // if the operation exists and is not finished
        //      let finish
        // if no operation exists
        //      queue new operation
        
        if (operation && operation.isFinished) {
            generator.operation = nil;
            operation = nil;
        }
        
        if (!operation) {
            operation = [NSBlockOperation new];
            generator.operation = operation;
            
            [operation addExecutionBlock: ^{
                //code
                if (!generator.operation.isCancelled) {
                    [generator generateImage];
                    
                    if (generator.imageView && generator.image) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [[(MBCollectionFractalCell*)[collectionView cellForItemAtIndexPath: indexPath] imageView] setImage: generator.image];
                        }];
                    }
                }
            }];
            [self.privateQueue addOperation: operation];
        }
    
        cell.imageView.image = [self placeHolderImageSized: thumbnailSize background: thumbNailBackground];
    }
    
    MBImmutableCellBackgroundView* newBackground =  [MBImmutableCellBackgroundView new];
    newBackground.readOnlyView = [cellFractal.isImmutable boolValue];
    cell.backgroundView = newBackground;
    
    return cell;
}

- (UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    MBCollectionFractalSupplementaryLabel* rView = [collectionView dequeueReusableSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                                                                                      withReuseIdentifier: kSupplementaryHeaderCellIdentifier
                                                                                             forIndexPath: indexPath];
    
    rView.textLabel.text = [[self.fetchedResultsController sections][indexPath.section] name];

    return rView;
}

#pragma mark - UICollectionViewDelegate
-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedFractal = (LSFractal*)managedObject;
}
-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSManagedObjectID* objectID = managedObject.objectID;
    
    NSOperation* operation = (self.fractalToGeneratorOperations)[objectID];
    if (operation) {
        [operation cancel];
        [self.fractalToGeneratorOperations removeObjectForKey: objectID];
    }
}

#pragma mark - State handling

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.fractalCollectionView reloadData];
    
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initControls];
}
-(void)viewDidAppear:(BOOL)animated {
    [self.fractalCollectionView reloadData];
    NSIndexPath* selectIndex = [self.fetchedResultsController indexPathForObject: self.fractal];
    [self.fractalCollectionView selectItemAtIndexPath: selectIndex animated: animated scrollPosition: UICollectionViewScrollPositionTop];
    [super viewDidAppear:animated];
}
-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    [_privateQueue cancelAllOperations];
}
- (void)viewDidUnload
{
//    [self setMainFractalView:nil];
    [self setFractalCollectionView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
