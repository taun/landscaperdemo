//
//  MBColorCollectionViewController.m
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/06/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBColorCollectionViewController.h"
#import "MBAppDelegate.h"
#import "MBCollectionColorCell.h"

@interface MBColorCollectionViewController ()

@end

@implementation MBColorCollectionViewController

+(NSString*) fractalPropertyKeypath {
    return @"lineColor";
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) initControls {
    // need to set current selection
    // use selectItemAtIndexPath:animated:scrollPosition:
    // need to determine index of selectedFractal
    // perhaps make part of selectedFractal setter?
}
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
        NSEntityDescription* entity = [NSEntityDescription entityForName: @"MBColor" inManagedObjectContext:appContext];
        [fetchRequest setEntity: entity];
        [fetchRequest setFetchBatchSize: 20];
        NSSortDescriptor* redSortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"red" ascending: YES];
        NSSortDescriptor* greenSortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"green" ascending: YES];
        NSSortDescriptor* blueSortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"blue" ascending: YES];
        NSArray* sortDescriptors = @[redSortDescriptor, greenSortDescriptor, blueSortDescriptor];
        [fetchRequest setSortDescriptors: sortDescriptors];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest managedObjectContext: appContext sectionNameKeyPath: nil cacheName: @"strokeColors"];
        
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
    [self.colorCollectionView reloadData];
}
#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)collectionView:(UICollectionView *)table numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

-(UIImage*) thumbnailForColor: (NSManagedObject*) mObject size: (CGSize) size {
    UIImage* thumbnail;
    if ([mObject isKindOfClass: [MBColor class]]) {
        //
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        
        CGRect viewRect = CGRectMake(0, 0, size.width, size.height);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(context);
        MBColor* color = (MBColor*)mObject;
        UIColor* thumbNailBackground = [color asUIColor];
        [thumbNailBackground setFill];
        CGContextFillRect(context, viewRect);
        CGContextRestoreGState(context);
        
        
        thumbnail = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return thumbnail;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"ColorSwatchCell";
    
    MBCollectionColorCell *cell = (MBCollectionColorCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    //    if (cell == nil) {
    //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    //    }
    
    
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    // Configure the cell with data from the managed object.
    cell.imageView.image = [self thumbnailForColor: managedObject size: cell.bounds.size];
    cell.imageView.highlightedImage = cell.imageView.image;
    
    MBColor* currentColor = [self.fractal valueForKey: [[self class] fractalPropertyKeypath]];
    if (currentColor == managedObject) {
        cell.selected = YES;
    }
    
    return cell;
}
#pragma mark - UICollectionViewDelegate
-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    [self.fractal setValue: (MBColor*)managedObject forKey: [[self class] fractalPropertyKeypath]];
    [collectionView selectItemAtIndexPath: indexPath animated: YES scrollPosition:UICollectionViewScrollPositionNone] ;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}
-(void)viewDidAppear:(BOOL)animated {
    NSManagedObject* currentColor = [self.fractal valueForKey: [[self class] fractalPropertyKeypath]];
    NSIndexPath* selectIndex = [self.fetchedResultsController indexPathForObject: currentColor];
    
    [self.colorCollectionView selectItemAtIndexPath: selectIndex animated: animated scrollPosition: UICollectionViewScrollPositionTop];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
