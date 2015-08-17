//
//  MDBHelpRulesCollectionViewController.m
//  FractalScapes
//
//  Created by Taun Chapman on 08/07/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBHelpRulesCollectionViewController.h"
#import "LSDrawingRuleType.h"
#import "MDBRuleCollectionViewCell.h"

@interface MDBHelpRulesCollectionViewController ()

@property (nonatomic,strong) NSArray  *drawingRules;

@property (nonatomic,strong) MDBRuleCollectionViewCell      *layoutSizingCell;
@end

@implementation MDBHelpRulesCollectionViewController

static NSString * const reuseIdentifier = @"RuleCollectionViewCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    _drawingRules = [[LSDrawingRuleType newLSDrawingRuleTypeFromDefaultPListDictionary] rulesAsSortedArray];
    
//    _layoutSizingCell = (MDBRuleCollectionViewCell*)[self.collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath: [NSIndexPath indexPathForRow: 0 inSection: 0]];
//    _layoutSizingCell = [[MDBRuleCollectionViewCell alloc] initWithFrame: CGRectZero];
    
    // Register cell classes
//    [self.collectionView registerClass:[MDBRuleCollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context){
        //
        [self.collectionView.collectionViewLayout invalidateLayout]; // to resize the collection view cells.
//        [self.collectionView reloadData];

    }];
}

-(void)viewWillLayoutSubviews
{
    [self.collectionView.collectionViewLayout invalidateLayout]; // to resize collectionCells with explanding and contracting splitView
}

#pragma mark - FlowLayoutDelegate
//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
//{
//    CGFloat minInset = 2.0;
//    
//    UICollectionViewFlowLayout* layout = (UICollectionViewFlowLayout*)collectionViewLayout;
//    CGFloat itemWidth = layout.itemSize.width;
//    CGFloat rowWidth = collectionView.bounds.size.width - (2*minInset);
//    NSInteger numItems = floorf(rowWidth/itemWidth);
//    CGFloat margins = floorf((rowWidth - (numItems * itemWidth))/(numItems+1.0));
//    //    margins = MAX(margins, 4.0);
//    UIEdgeInsets oldInsets = layout.sectionInset;
//    UIEdgeInsets insets = UIEdgeInsetsMake(oldInsets.top, margins, oldInsets.bottom, margins);
//    return insets;
//    //    return 20.0;
//}
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
//    CGFloat width = self.collectionView.bounds.size.width - 20.0;
//    
//    MDBRuleCollectionViewCell* cell = (MDBRuleCollectionViewCell*)[collectionView cellForItemAtIndexPath: indexPath];
//    cell.cellAutolayoutWidthConstraint.constant = width;
//    
//    
//    UICollectionViewLayoutAttributes* attributes = [cell preferredLayoutAttributesFittingAttributes: [collectionViewLayout layoutAttributesForItemAtIndexPath: indexPath]];
//    
//    return attributes.size;
//    UICollectionViewLayoutAttributes* attributes = [collectionViewLayout layoutAttributesForItemAtIndexPath: indexPath];
    
    CGFloat colWidth = collectionView.bounds.size.width;
    CGFloat spacing = [(UICollectionViewFlowLayout*)collectionViewLayout minimumInteritemSpacing];
    UIEdgeInsets insets = [(UICollectionViewFlowLayout*)collectionViewLayout sectionInset];
    CGFloat margin = insets.left + insets.right;
    
    CGFloat width = colWidth > 600.0 ? colWidth/2.0 - margin - spacing : colWidth - margin;
    CGFloat height = (320.0-margin)/width * 164;
//    self.layoutSizingCell.rule = self.drawingRules[indexPath.row];
    
//    CGSize estimatedSize = CGSizeMake(width, 150.0);
    

//    MDBRuleCollectionViewCell* cell = self.layoutSizingCell;
    
//    cell.frame = CGRectMake(0, 0, width, 150);
//    [cell setNeedsLayout];
//    [cell layoutIfNeeded];
//    CGFloat newHeight = cell.desiredMinHeight;
    
    return CGSizeMake(width, height);
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.drawingRules.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MDBRuleCollectionViewCell *cell = (MDBRuleCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    cell.rule = self.drawingRules[indexPath.row];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
