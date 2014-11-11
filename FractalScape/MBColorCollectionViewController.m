//
//  MBColorCollectionViewController.m
//  FractalScape
//
//  Created by Taun Chapman on 03/06/13.
//  Copyright (c) 2013 MOEDAE LLC. All rights reserved.
//

#import "MBColorCollectionViewController.h"
#import "MBAppDelegate.h"
#import "MBCollectionColorCell.h"
#import "MBColor+addons.h"
#import "NSManagedObject+Shortcuts.h"


#import "MBCollectionFractalSupplementaryLabel.h" // from Library collectionView
static NSString *kSupplementaryHeaderCellIdentifier = @"ColorsHeader";

@interface MBColorCollectionViewController ()

@end

@implementation MBColorCollectionViewController

+(NSString*) fractalPropertyKeypath {
    return @"lineColors";
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _colorsChanged = YES;
    }
    return self;
}
-(NSArray*)cachedFractalColors {
    if (!_cachedFractalColors || self.colorsChanged) {
        NSSet* colors = [self.fractal valueForKey: [[self class] fractalPropertyKeypath]];
        NSSortDescriptor* indexSort = [NSSortDescriptor sortDescriptorWithKey: @"index" ascending: YES];
        _cachedFractalColors = [colors sortedArrayUsingDescriptors: @[indexSort]];
    }
    return _cachedFractalColors;
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
-(NSFetchedResultsController*) libraryColorsFetchedResultsController {
    if (_libraryColorsFetchedResultsController == nil) {
        // instantiate
        NSManagedObjectContext* appContext = [self appManagedObjectContext];
        
        NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription* entity = [MBColor entityDescriptionForContext: appContext];
        [fetchRequest setEntity: entity];
        [fetchRequest setFetchBatchSize: 40];
        
        NSSortDescriptor* category = [NSSortDescriptor sortDescriptorWithKey: @"category.identifier" ascending: YES];
        NSSortDescriptor* index = [NSSortDescriptor sortDescriptorWithKey: @"index" ascending: YES];
        NSArray* sortDescriptors = @[category, index];
        [fetchRequest setSortDescriptors: sortDescriptors];
        
        NSPredicate* filterPredicate = [NSPredicate predicateWithFormat: @"category != NIL"];
        [fetchRequest setPredicate: filterPredicate];
        
        _libraryColorsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest managedObjectContext: appContext sectionNameKeyPath: @"category.name" cacheName: [[self class]fractalPropertyKeypath]];
        
        _libraryColorsFetchedResultsController.delegate = self;
        
        NSError* error = nil;
        
        if (![_libraryColorsFetchedResultsController performFetch: &error]) {
            NSLog(@"Fetched Results Error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return _libraryColorsFetchedResultsController;
}
#pragma mark - NSFetchedResultsControllerDelegate conformance -
-(void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.colorCollectionView reloadData];
}
#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [[self.libraryColorsFetchedResultsController sections] count]+1;
}

- (NSInteger)collectionView:(UICollectionView *)table numberOfItemsInSection:(NSInteger)section {
    if (section == 0) {
        return self.cachedFractalColors.count;
    } else {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.libraryColorsFetchedResultsController sections][section-1];
        return [sectionInfo numberOfObjects];
    }
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
- (UICollectionReusableView*) collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    MBCollectionFractalSupplementaryLabel* rView = [collectionView dequeueReusableSupplementaryViewOfKind: UICollectionElementKindSectionHeader
                                                                                      withReuseIdentifier: kSupplementaryHeaderCellIdentifier
                                                                                             forIndexPath: indexPath];
    
    if (indexPath.section == 0) {
        rView.textLabel.text = @"Fractal Colors in order of use";
    } else {
        rView.textLabel.text = [[self.libraryColorsFetchedResultsController sections][indexPath.section-1] name];
    }
    
    return rView;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"ColorSwatchCell";
    
    MBCollectionColorCell *cell = (MBCollectionColorCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    //    if (cell == nil) {
    //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    //    }
    UIImageView* strongCellImageView = cell.imageView;
    NSManagedObject* managedObjectColor;
    
    if (indexPath.section == 0) {
        managedObjectColor = self.cachedFractalColors[indexPath.row];
    } else {
        NSIndexPath* adjustedPath = [NSIndexPath indexPathForRow: indexPath.row inSection: indexPath.section-1];
        managedObjectColor = [self.libraryColorsFetchedResultsController objectAtIndexPath: adjustedPath];
    }
    
    strongCellImageView.image = [self thumbnailForColor: managedObjectColor size: cell.bounds.size];
    strongCellImageView.highlightedImage = strongCellImageView.image;
    
//    MBColor* currentColor = [self.fractal valueForKey: [[self class] fractalPropertyKeypath]];
//    if (currentColor == managedObject) {
//        cell.selected = YES;
//    }
    
    return cell;
}
#pragma mark - UICollectionViewDelegate
-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//    NSManagedObject *managedObject = [self.libraryColorsFetchedResultsController objectAtIndexPath:indexPath];
//    [self.fractal setValue: (MBColor*)managedObject forKey: [[self class] fractalPropertyKeypath]];
//    [collectionView selectItemAtIndexPath: indexPath animated: YES scrollPosition:UICollectionViewScrollPositionNone] ;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}
-(void)viewDidAppear:(BOOL)animated {
//    NSManagedObject* currentColor = [self.fractal valueForKey: [[self class] fractalPropertyKeypath]];
//    NSIndexPath* selectIndex = [self.libraryColorsFetchedResultsController indexPathForObject: currentColor];
    
//    [self.colorCollectionView selectItemAtIndexPath: selectIndex animated: animated scrollPosition: UICollectionViewScrollPositionTop];
    [super viewDidAppear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
