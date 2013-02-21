//
//  MBFractalLibraryViewController.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 12/23/11.
//  Copyright (c) 2011 MOEDAE LLC. All rights reserved.
//

#import "MBAppDelegate.h"
#import "MBFractalLibraryViewController.h"
#import "MBLSFractalViewController.h"
#import "LSFractal+addons.h"
#import "LSFractalGenerator.h"

#import <QuartzCore/QuartzCore.h>

#include "Model/QuartzHelpers.h"

#include <math.h>

@interface MBFractalLibraryViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController*   fetchedResultsController;

-(NSManagedObjectContext*)         appManagedObjectContext;

@end

@implementation MBFractalLibraryViewController


#pragma mark - custom getters -

-(NSManagedObjectContext*) appManagedObjectContext {
    
    UIApplication* app = [UIApplication sharedApplication];
    MBAppDelegate* appDelegate = [app delegate];
    NSManagedObjectContext* appContext = appDelegate.managedObjectContext;
    
    return appContext;
}

-(NSFetchedResultsController*) fetchedResultsController {
    if (_fetchedResultsController == nil) {
        // instantiate
        NSManagedObjectContext* appContext = [self appManagedObjectContext];
        
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription* entity = [NSEntityDescription entityForName: @"LSFractal" inManagedObjectContext:appContext];
        [fetchRequest setEntity: entity];
        [fetchRequest setFetchBatchSize: 20];
        NSSortDescriptor* nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];
        NSSortDescriptor* catSortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"category" ascending: YES];
        NSArray* sortDescriptors = @[catSortDescriptor, nameSortDescriptor];
        [fetchRequest setSortDescriptors: sortDescriptors];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest managedObjectContext: appContext sectionNameKeyPath: @"category" cacheName: @"root"];

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
    [self.fractalTableView reloadData];
}

#pragma mark - Table Delegate and Data Source -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

-(UIImage*) thumbnailForFractal: (NSManagedObject*) mObject size: (CGSize) size {
    UIImage* thumbnail;
    if ([mObject isKindOfClass: [LSFractal class]]) {
        //
        CGSize newSize = CGSizeMake(86, 86);
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
        LSFractalGenerator* generator = [[LSFractalGenerator alloc] init];
        generator.fractal = (LSFractal*) mObject;
        
        CGRect viewRect = CGRectMake(0, 0, newSize.width, newSize.height);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(context);
        UIColor* thumbNailBackground = [UIColor colorWithWhite: 1.0 alpha: 0.8];
        [thumbNailBackground setFill];
        CGContextFillRect(context, viewRect);
        CGContextRestoreGState(context);
        
        [generator drawInBounds: viewRect
                    withContext: context
                        flipped: NO];
        
        thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return thumbnail;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"FractalLibraryListCell";
    
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//    }

    
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    // Configure the cell with data from the managed object.
    cell.textLabel.text = [managedObject valueForKey: @"name"];
    cell.detailTextLabel.text = [managedObject valueForKey: @"descriptor"];
    cell.imageView.image = [self thumbnailForFractal: managedObject size: cell.imageView.bounds.size];
    cell.imageView.highlightedImage = cell.imageView.image;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section { 
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo name];
}

//TODO change to cache section view?
- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    // Change rect to ??
    CGRect tableBounds = tableView.bounds;
    UIView* customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableBounds.size.width-20.0, 44.0)];
	
	// create the button object
    CGRect headerLabelFrame = customView.bounds;
    headerLabelFrame.origin.x += 35.0;
    headerLabelFrame.size.width -= 35.0;
    CGRectInset(headerLabelFrame, 0.0, 5.0);
    
	UILabel * headerLabel = [[UILabel alloc] initWithFrame: headerLabelFrame];
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.opaque = NO;
	headerLabel.textColor = [UIColor colorWithWhite: 0.1 alpha: 1.0];
	headerLabel.highlightedTextColor = [UIColor whiteColor];
    headerLabel.shadowColor = [UIColor colorWithWhite: 0.7 alpha: 0.9];
    headerLabel.shadowOffset = CGSizeMake(0.0, 1.0);
	headerLabel.font = [UIFont boldSystemFontOfSize:20];
    
	// If you want to align the header text as centered
	// headerLabel.frame = CGRectMake(150.0, 0.0, 300.0, 44.0);
    
	headerLabel.text = [[self.fetchedResultsController sections][section] name];
	[customView addSubview:headerLabel];
    
	return customView;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return UITableViewAutomaticDimension;
}


#pragma mark - Seque Handling -
-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: @"FractalEditorSegue"]) {
        MBLSFractalViewController* viewer = segue.destinationViewController;
        LSFractal* passedFractal = nil;

        // pass the selected fractal
        NSIndexPath* indexPath = [self.fractalTableView indexPathForSelectedRow];
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
        viewer.currentFractal = passedFractal;        
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
    self.fractalTableView.backgroundView = nil;
    
    [self.fractalTableView reloadData];
    
//    [self addVonKochSnowFlakeLayerPosition: CGPointMake(50, 50) maxDimension: 300];
//    [self addBush1LayerPosition: CGPointMake(350, 50) maxDimension: 300];
//    [self addVonKochIslandLayerPosition: CGPointMake(75, 250) maxDimension: 300];
//    [self addVonKochSquaresLayerPosition: CGPointMake(175, 450) maxDimension: 300];
}

- (void)viewDidUnload
{
//    [self setMainFractalView:nil];
    [self setFractalTableView:nil];
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
