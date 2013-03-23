//
//  MBFractalLibraryViewController.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBAppDelegate.h"
#import "MBFractalLibraryViewController.h"
#import "LSFractalGenerator.h"

#import "MBCollectionFractalCell.h"
#import "MBCollectionFractalSupplementaryLabel.h"
#import "MBColorCellSelectBackgroundView.h"

#import <QuartzCore/QuartzCore.h>

#include "Model/QuartzHelpers.h"

#include <math.h>

static NSString *kSupplementaryHeaderCellIdentifier = @"FractalLibraryCollectionHeader";

@interface MBFractalLibraryViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController*   fetchedResultsController;

@property (nonatomic,strong) NSMutableDictionary*           fractalToThumbnailGenerators;
@property (nonatomic,strong) NSOperationQueue*              privateQueue;
@property (nonatomic,strong) NSMutableDictionary*           fractalToGeneratorOperations;

-(void) initControls;
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
    if (_fetchedResultsController == nil) {
        // instantiate
        NSManagedObjectContext* fractalContext = self.fractal.managedObjectContext;
        
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription* entity = [NSEntityDescription entityForName: @"LSFractal" inManagedObjectContext: fractalContext];
        [fetchRequest setEntity: entity];
        [fetchRequest setFetchBatchSize: 20];
        NSSortDescriptor* nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];
        NSSortDescriptor* catSortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"category" ascending: YES];
        NSArray* sortDescriptors = @[catSortDescriptor, nameSortDescriptor];
        [fetchRequest setSortDescriptors: sortDescriptors];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest managedObjectContext: fractalContext sectionNameKeyPath: @"category" cacheName: @"root"];

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

//-(UIImage*) thumbnailForFractal: (NSManagedObject*) mObject size: (CGSize) size {
//    UIImage* thumbnail;
//    if ([mObject isKindOfClass: [LSFractal class]]) {
//        //
//        LSFractalGenerator* generator = [[LSFractalGenerator alloc] init];
//        generator.fractal = (LSFractal*) mObject;
//        
//        UIColor* thumbNailBackground = [UIColor colorWithWhite: 1.0 alpha: 0.8];
//        
//        thumbnail = [generator generateImageSize: size withBackground: thumbNailBackground.CGColor];
//    }
//    return thumbnail;
//}
-(UIImage*) placeHolderImageSized: (CGSize)size background: (UIColor*) uiColor {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGRect viewRect = CGRectMake(0, 0, size.width, size.height);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    [uiColor setFill];
    CGContextFillRect(context, viewRect);
    CGContextRestoreGState(context);
        
    UIImage* thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return thumbnail;
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
    
    // Configure the cell with data from the managed object.
    cell.textLabel.text = [managedObject valueForKey: @"name"];
    cell.detailTextLabel.text = [managedObject valueForKey: @"descriptor"];
    
    LSFractalGenerator* generator = [self.fractalToThumbnailGenerators objectForKey: managedObject.objectID];
    
    CGSize thumbnailSize = [cell.imageView systemLayoutSizeFittingSize: UILayoutFittingExpandedSize];

    [cell.imageView sizeToFit];
    thumbnailSize = cell.imageView.bounds.size;
    thumbnailSize = [cell.imageView sizeThatFits: cell.bounds.size];

    CGSize imageFrameSize = [cell.imageFrame systemLayoutSizeFittingSize: UILayoutFittingExpandedSize];
    [cell.imageFrame sizeToFit];
    imageFrameSize = cell.imageFrame.bounds.size;
    
    UIColor* thumbNailBackground = [UIColor colorWithWhite: 1.0 alpha: 0.8];
    
    if ([generator hasImageSize: thumbnailSize]) {
        cell.imageView.image = [generator generateImageSize: thumbnailSize withBackground: thumbNailBackground];
    } else {
        if (!generator) {
            // No generator yet
            generator = [[LSFractalGenerator alloc] init];
            generator.fractal = (LSFractal*) managedObject;
            [self.fractalToThumbnailGenerators setObject: generator forKey: objectID];
        }
            
        NSOperation* operation = [self.fractalToGeneratorOperations objectForKey: objectID];
        
        // if the operation exists and is finished
        //      remove and queue a new operation
        // if the operation exists and is not finished
        //      let finish
        // if no operation exists
        //      queue new operation
        
        if (operation && operation.isFinished) {
            [self.fractalToGeneratorOperations removeObjectForKey: objectID];
            operation = nil;
        }
        
        if (!operation) {
            operation = [NSBlockOperation blockOperationWithBlock:^{
                //code
                UIImage* fractalImage = [generator generateImageSize: thumbnailSize withBackground: thumbNailBackground];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    //code
                    [[(MBCollectionFractalCell*)[collectionView cellForItemAtIndexPath: indexPath] imageView] setImage: fractalImage];
                }];
            }];
            [self.fractalToGeneratorOperations setObject: operation forKey: objectID];
            [self.privateQueue addOperation: operation];
        }
    
        cell.imageView.image = [self placeHolderImageSized: thumbnailSize background: thumbNailBackground];
    }
    
//    cell.imageView.highlightedImage = cell.imageView.image;
    
    cell.selectedBackgroundView = [MBColorCellSelectBackgroundView new];
    
    if (self.fractal == managedObject) {
        cell.selected = YES;
    }
    
    return cell;
}

- (UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    
//    MBCollectionFractalSupplementaryLabel* rView = [collectionView dequeueReusableCellWithReuseIdentifier: SupplementaryCellIdentifier forIndexPath: indexPath];
    MBCollectionFractalSupplementaryLabel* rView = [collectionView dequeueReusableSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                                                                                      withReuseIdentifier: kSupplementaryHeaderCellIdentifier
                                                                                             forIndexPath: indexPath];
    
    rView.textLabel.text = [[[self.fetchedResultsController sections] objectAtIndex: indexPath.section] name];

    return rView;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { 
//    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
//    return [sectionInfo name];
//}

//TODO change to cache section view?
//- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    
//    // Change rect to ??
//    CGRect tableBounds = tableView.bounds;
//    UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableBounds.size.width-20.0, 44.0)];
//	
//	// create the button object
//    CGRect headerLabelFrame = customView.bounds;
//    headerLabelFrame.origin.x += 35.0;
//    headerLabelFrame.size.width -= 35.0;
//    CGRectInset(headerLabelFrame, 0.0, 5.0);
//    
//	UILabel * headerLabel = [[UILabel alloc] initWithFrame: headerLabelFrame];
//	headerLabel.backgroundColor = [UIColor clearColor];
//	headerLabel.opaque = NO;
//	headerLabel.textColor = [UIColor colorWithWhite: 0.1 alpha: 1.0];
//	headerLabel.highlightedTextColor = [UIColor whiteColor];
//    headerLabel.shadowColor = [UIColor colorWithWhite: 0.7 alpha: 0.9];
//    headerLabel.shadowOffset = CGSizeMake(0.0, 1.0);
//	headerLabel.font = [UIFont boldSystemFontOfSize:20];
//    
//	// If you want to align the header text as centered
//	// headerLabel.frame = CGRectMake(150.0, 0.0, 300.0, 44.0);
//    
//	headerLabel.text = [[self.fetchedResultsController sections][section] name];
//	[customView addSubview:headerLabel];
//    
//	return customView;
//}

//- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    return UITableViewAutomaticDimension;
//}

#pragma mark - UICollectionViewDelegate
-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    self.selectedFractal = (LSFractal*)managedObject;
    
    NSLog(@"Selected item: %@", indexPath);
}
-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSManagedObjectID* objectID = managedObject.objectID;
    
//    NSOperation* operation = [self.fractalToGeneratorOperations objectForKey: objectID];
//    if (operation) {
//        [operation cancel];
//        [self.fractalToGeneratorOperations removeObjectForKey: objectID];
//    }
}
#pragma mark - Seque Handling -
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: @"FractalEditorSegue"]) {
        UIViewController<FractalControllerProtocol>* viewer = segue.destinationViewController;
        LSFractal* passedFractal = nil;

        // pass the selected fractal
        NSIndexPath* indexPath;
        NSArray* indexPaths = [self.fractalCollectionView indexPathsForSelectedItems];
        if (indexPaths.count > 0) {
            indexPath = [indexPaths objectAtIndex: 0];
        }
        
        NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];

        if ([managedObject isKindOfClass:[LSFractal class]]) {

            LSFractal* fractal = (LSFractal*) managedObject;
            
            if ([fractal.isImmutable boolValue]) {
                passedFractal = [fractal mutableCopy];
                NSError *error;
                if (![passedFractal.managedObjectContext save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                }
            } else {
                passedFractal = fractal;
            }
        }
        viewer.fractal = passedFractal;        
    }
}

#pragma mark - State handling -

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    UIImage* background = [UIImage imageNamed: @"interstices"];
//    UIColor* backgroundColor = [UIColor colorWithPatternImage: background];
//    
//    self.view.layer.backgroundColor = backgroundColor.CGColor;
    
//    self.view.layer.backgroundColor = GetCGPatternFromUIImage(background);
    
//    MainFractalView.layer.opaque = NO;
//    MainFractalView.opaque = NO;
//    MainFractalView.backgroundColor = [UIColor colorWithWhite: 1.0 alpha: 0.0];
//    MainFractalView.alpha = 0.0;
//    [MainFractalView setNeedsDisplay];
//    [MainFractalView.layer setNeedsDisplay];
        
    // Allow the grouped table to have a clear background.
//    self.fractalCollectionView.backgroundView = nil;
    
//    [self.fractalCollectionView registerClass: [MBCollectionFractalSupplementaryLabel class]
//       forSupplementaryViewOfKind: UICollectionElementKindSectionHeader
//              withReuseIdentifier: kSupplementaryHeaderCellIdentifier];
    
    [self.fractalCollectionView reloadData];
    
//    [self addVonKochSnowFlakeLayerPosition: CGPointMake(50, 50) maxDimension: 300];
//    [self addBush1LayerPosition: CGPointMake(350, 50) maxDimension: 300];
//    [self addVonKochIslandLayerPosition: CGPointMake(75, 250) maxDimension: 300];
//    [self addVonKochSquaresLayerPosition: CGPointMake(175, 450) maxDimension: 300];
}
-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initControls];
}
-(void)viewDidAppear:(BOOL)animated {
    NSIndexPath* selectIndex = [self.fetchedResultsController indexPathForObject: self.fractal];
    [self.fractalCollectionView selectItemAtIndexPath: selectIndex animated: animated scrollPosition: UICollectionViewScrollPositionTop];

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

//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    [self.navigationController setToolbarHidden: YES animated: YES];
//}

//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:animated];
//}

//- (void)viewWillDisappear:(BOOL)animated
//{
//	[super viewWillDisappear:animated];
//}

//- (void)viewDidDisappear:(BOOL)animated
//{
//	[super viewDidDisappear:animated];
//}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}
//#pragma mark - View lifecycle
//
//-(MBLSFractal*) newVonKochSnowFlake {
//    CGColorRef lineColor = CreateDeviceRGBColor(0.0f, 0.3f, 1.0f, 1.0f);
//    
//    MBLSFractal* fractal = [[MBLSFractal alloc] init];
//    fractal.lineColor = lineColor;
//    fractal.lineWidth = 2.0f;
//    CGColorRelease(lineColor);
//    
//    fractal.axiom = @"F++F++F";
//    fractal.turningAngle = M_PI/(3.0f);
//    fractal.lineLength = 10.0;
//    [fractal addProductionRuleReplaceString: @"F" withString: @"F-F++F-F"];
//    [fractal addProductionRuleReplaceString: @"+" withString: @"+"];
//    [fractal addProductionRuleReplaceString: @"-" withString: @"-"];
//    fractal.levels = 0;
////    if (MainFractalView.layer.contentsAreFlipped) {
////        fractal.currentTransform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
////    }
//    return fractal;
//}
//
//-(MBLSFractal*) newVonKochIsland {
//    CGColorRef lineColor = CreateDeviceRGBColor(0.0f, 0.3f, 1.0f, 1.0f);
//    
//    MBLSFractal* fractal = [[MBLSFractal alloc] init];
//    fractal.lineColor = lineColor;
//    fractal.lineWidth = 2.0f;
//    CGColorRelease(lineColor);
//    
//    fractal.axiom = @"F+F+F+F";
//    fractal.turningAngle = M_PI/(2.0f);
//    fractal.lineLength = 10.0;
//    [fractal addProductionRuleReplaceString: @"F" withString: @"F+F-F-FF+F+F-F"];
//    [fractal addProductionRuleReplaceString: @"+" withString: @"+"];
//    [fractal addProductionRuleReplaceString: @"-" withString: @"-"];
//    fractal.levels = 0;
//    return fractal;
//}
//
//-(MBLSFractal*) newVonKochSquares {
//    CGColorRef lineColor = CreateDeviceRGBColor(0.0f, 0.3f, 1.0f, 1.0f);
//    
//    MBLSFractal* fractal = [[MBLSFractal alloc] init];
//    fractal.lineColor = lineColor;
//    fractal.lineWidth = 2.0f;
//    CGColorRelease(lineColor);
//    
//    fractal.axiom = @"F+F+F+F";
//    fractal.turningAngle = M_PI/(2.0f);
//    fractal.lineLength = 10.0;
//    [fractal addProductionRuleReplaceString: @"F" withString: @"FF+F-F+F+FF"];
//    [fractal addProductionRuleReplaceString: @"+" withString: @"+"];
//    [fractal addProductionRuleReplaceString: @"-" withString: @"-"];
//    fractal.levels = 0;
//    return fractal;
//}
//
//-(MBLSFractal*) newBush1 {
//    CGColorRef lineColor = CreateDeviceRGBColor(0.0f, 0.3f, 1.0f, 1.0f);
//    
//    MBLSFractal* fractal = [[MBLSFractal alloc] init];
//    fractal.lineColor = lineColor;
//    fractal.lineWidth = 2.0f;
//    CGColorRelease(lineColor);
//    
//    fractal.axiom = @"F";
//    fractal.turningAngle = M_PI/(7.0f);
//    fractal.lineLength = 10.0;
//    [fractal setInitialTransform: CGAffineTransformMakeRotation(-M_PI_2)];
//    [fractal addProductionRuleReplaceString: @"F" withString: @"F[+F]F[-F]F"];
//    [fractal addProductionRuleReplaceString: @"+" withString: @"+"];
//    [fractal addProductionRuleReplaceString: @"-" withString: @"-"];
//    [fractal addProductionRuleReplaceString: @"[" withString: @"["];
//    [fractal addProductionRuleReplaceString: @"]" withString: @"]"];
//    fractal.levels = 0;
//    return fractal;
//}
//
//-(void) addVonKochSnowFlakeLayerPosition: (CGPoint) position  maxDimension: (double) size {
//    // It is important to create the fractal before the layer so the layer bounds aspect can use the fractal bounds
//    // It is assumed fractal bounds aspect will not change significantly with varying levels]
//    // A different axiom or rules is a different fractal and probably requires a new layer.
//    
//    // create the fractal
//    MBLSFractal* fractal = [self newVonKochSnowFlake];
//    fractal.levels = 4;
//    fractal.fill = NO;
//    [fractal generateProduct];
//    [fractal generatePaths];
//
//    
//    // create a fractal layer
//    MBFractalLayer* fractalLayer = [[MBFractalLayer alloc] init];
//    
//    // anchorPoint traditional lower left corner
//    //    fractalLayer.anchorPoint = CGPointMake(0.0f, 1.0f);    
//    // position based on lower left corner
//    fractalLayer.position = position;
//    
//    CGSize unitBox = [fractal unitBox];
//    fractalLayer.bounds = CGRectMake(0.0f, 0.0f, unitBox.width*size, unitBox.height*size);
//    fractalLayer.borderWidth = 0.0;
//    fractalLayer.masksToBounds = NO;
//    
//    fractalLayer.fractal = fractal;
//    
//    [MainFractalView.layer addSublayer: fractalLayer];
//    [fractalLayer setNeedsDisplay];
//}
//
///*
// position is bottom left corner
// */
//-(void) addVonKochIslandLayerPosition: (CGPoint) position maxDimension: (double) size {
//    
//    CGColorRef fillColor = CreateDeviceRGBColor(0.0f, 0.4f, 0.5f, 0.8f);
//    CGColorRef lineColor = CreateDeviceRGBColor(1.0f, 0.8f, 0.0f, 1.0f);
//
//    // create the fractal
//    MBLSFractal* fractal = [self newVonKochIsland];
//    fractal.levels = 2;
//    fractal.stroke = YES;
//    fractal.lineColor = lineColor;
//    CGColorRelease(lineColor);
//    fractal.fill = YES;
//    fractal.fillColor = fillColor;
//    CGColorRelease(fillColor);
//    [fractal generateProduct];
//    [fractal generatePaths];
//    
//    
//    // create a fractal layer
//    MBFractalLayer* fractalLayer = [[MBFractalLayer alloc] init];
//    
//    // anchorPoint traditional lower left corner
//    //    fractalLayer.anchorPoint = CGPointMake(0.0f, 1.0f);    
//    // position based on lower left corner
//    fractalLayer.position = position;
//    
//    CGSize unitBox = [fractal unitBox];
//    fractalLayer.bounds = CGRectMake(0.0f, 0.0f, unitBox.width*size, unitBox.height*size);
//
//    fractalLayer.fractal = fractal;
//    
//    [MainFractalView.layer addSublayer: fractalLayer];
//    [fractalLayer setNeedsDisplay];
//}
//
//-(void) addVonKochSquaresLayerPosition: (CGPoint) position maxDimension: (double) size {
//    
//    CGColorRef fillColor = CreateDeviceRGBColor(0.0f, 0.8f, 1.0f, 0.8f);
//    CGColorRef lineColor = CreateDeviceRGBColor(1.0f, 0.8f, 0.0f, 1.0f);
//    
//    // create the fractal
//    MBLSFractal* fractal = [self newVonKochSquares];
//    fractal.levels = 3;
//    fractal.stroke = YES;
//    fractal.lineColor = lineColor;
//    CGColorRelease(lineColor);
//    fractal.fill = YES;
//    fractal.fillColor = fillColor;
//    CGColorRelease(fillColor);
//    [fractal generateProduct];
//    [fractal generatePaths];
//    
//    
//    // create a fractal layer
//    MBFractalLayer* fractalLayer = [[MBFractalLayer alloc] init];
//    
//    // anchorPoint traditional lower left corner
//    //    fractalLayer.anchorPoint = CGPointMake(0.0f, 1.0f);    
//    // position based on lower left corner
//    fractalLayer.position = position;
//    
//    CGSize unitBox = [fractal unitBox];
//    fractalLayer.bounds = CGRectMake(0.0f, 0.0f, unitBox.width*size, unitBox.height*size);
//    
//    fractalLayer.fractal = fractal;
//    
//    [MainFractalView.layer addSublayer: fractalLayer];
//    [fractalLayer setNeedsDisplay];
//}
//
//-(void) addBush1LayerPosition: (CGPoint) position maxDimension: (double) size {
//    
//    CGColorRef fillColor = CreateDeviceRGBColor(0.0f, 0.8f, 1.0f, 0.8f);
//    CGColorRef lineColor = CreateDeviceRGBColor(1.0f, 0.8f, 0.0f, 1.0f);
//    
//    // create the fractal
//    MBLSFractal* fractal = [self newBush1];
//    fractal.levels = 3;
//    fractal.stroke = YES;
//    fractal.lineColor = lineColor;
//    CGColorRelease(lineColor);
//    fractal.fill = NO;
//    fractal.fillColor = fillColor;
//    CGColorRelease(fillColor);
//    [fractal generateProduct];
//    [fractal generatePaths];
//    
//    
//    // create a fractal layer
//    MBFractalLayer* fractalLayer = [[MBFractalLayer alloc] init];
//    
//    // anchorPoint traditional lower left corner
//    //    fractalLayer.anchorPoint = CGPointMake(0.0f, 1.0f);    
//    // position based on lower left corner
//    fractalLayer.position = position;
//    
//    CGSize unitBox = [fractal unitBox];
//    fractalLayer.bounds = CGRectMake(0.0f, 0.0f, unitBox.width*size, unitBox.height*size);
//    
//    fractalLayer.fractal = fractal;
//    
//    [MainFractalView.layer addSublayer: fractalLayer];
//    [fractalLayer setNeedsDisplay];
//}
//

@end
