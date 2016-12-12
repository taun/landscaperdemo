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
#import "MDKUICollectionViewFlowLayoutDebug.h"
#import "MDBResizingWidthFlowLayoutDelegate.h"


@interface MDBHelpRulesCollectionViewController ()

@property (nonatomic,strong) NSArray  *drawingRules;

@property (nonatomic,strong) MDBRuleCollectionViewCell      *layoutSizingCell;
@end

@implementation MDBHelpRulesCollectionViewController

static NSString * const reuseIdentifier = @"RuleCollectionViewCell";
static NSString * const reuseIdentifierHeader = @"RulesHeaderCell";


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
    [MDBResizingWidthFlowLayoutDelegate invalidateFlowLayoutAttributesForCollection: self.collectionView];
}

//-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
//{
//    [super viewWillTransitionToSize: size withTransitionCoordinator: coordinator];
//    
//    // Important! need to invalidate before starting rotation animation, otherwise a crash due to cells not being where expected
////    [MDBResizingWidthFlowLayoutDelegate invalidateFlowLayoutAttributesForCollection: self.collectionView];
//
//    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context){
//        //
//        
//    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context){
//        //
//        [MDBResizingWidthFlowLayoutDelegate invalidateFlowLayoutAttributesForCollection: self.collectionView];
//    }];
//    //    subLayer.position = self.fractalView.center;
//}

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

//-(void)viewWillLayoutSubviews
//{
//    [self.collectionView.collectionViewLayout invalidateLayout]; // to resize collectionCells with explanding and contracting splitView
//}

#pragma mark - FlowLayoutDelegate

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    CGFloat colWidth = collectionView.bounds.size.width;
    CGFloat spacing = [(UICollectionViewFlowLayout*)collectionViewLayout minimumInteritemSpacing];
    UIEdgeInsets insets = [(UICollectionViewFlowLayout*)collectionViewLayout sectionInset];
    CGFloat margin = insets.left + insets.right;
    
    CGFloat width = colWidth > 600.0 ? colWidth/2.0 - margin - spacing : colWidth - margin;
    CGFloat height = (320.0-margin)/width * 164;
    
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

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView* headerView = [collectionView dequeueReusableSupplementaryViewOfKind: kind withReuseIdentifier: reuseIdentifierHeader forIndexPath: indexPath];
    
    return headerView;
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
