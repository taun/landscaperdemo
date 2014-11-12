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

-(void) initControls {
    // need to set current selection
    // use selectItemAtIndexPath:animated:scrollPosition:
    // need to determine index of selectedFractal
    // perhaps make part of selectedFractal setter?
}

- (IBAction)collectionLongPress:(UILongPressGestureRecognizer*)sender {
    CGPoint touchPoint = [sender locationInView: self.collectionView];

    MBColor* color;

    if (sender.state == UIGestureRecognizerStateBegan) {
         NSIndexPath* cellIndexPath = [self.collectionView indexPathForItemAtPoint: touchPoint];
        MBCollectionColorCell* selectedCell = (MBCollectionColorCell*)[self.collectionView cellForItemAtIndexPath: cellIndexPath];
        color = selectedCell.co
    }
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
        
        _libraryColorsFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest managedObjectContext: appContext sectionNameKeyPath: @"category.name" cacheName: @"colorLibraryCache"];
        
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
    
    static NSString *CellIdentifier = @"ColorSwatchCell";
    
    MBCollectionColorCell *cell = (MBCollectionColorCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    
    //    if (cell == nil) {
    //        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    //    }
    UIImageView* strongCellImageView = cell.imageView;
    MBColor* managedObjectColor;
    
    managedObjectColor = (MBColor*)[self.libraryColorsFetchedResultsController objectAtIndexPath: indexPath];
    
    strongCellImageView.image = [managedObjectColor thumbnailImageSize: cell.bounds.size];
    strongCellImageView.highlightedImage = strongCellImageView.image;
        
    return cell;
}
#pragma mark - UICollectionViewDelegate
-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
