//
//  MBLSRuleCollectionTableViewCell.h
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBXibAutolayoutTableCell.h"
#import <MDUiKit/MDUiKit.h>
#import "MBLSRuleDragAndDropProtocol.h"
#import "MBRuleCollectionDataSource.h"

@interface MBLSRuleCollectionTableViewCell : UITableViewCell <MBLSRuleDragAndDropProtocol>

/*!
 Fractal rules
 */
@property (nonatomic,weak) NSMutableOrderedSet                              *rules;
/*!
 Property needed for manual wrapping of willChangeValueForKey: and didChangeValueForKey:
 */
@property (nonatomic,weak) id                                               notifyObject;
/*!
 Property needed for manual wrapping of willChangeValueForKey: and didChangeValueForKey:
 */
@property (nonatomic,strong) NSString                                       *notifyPath;
/*!
 For drag and drop. If isReadOnly, rules can only be dragged from the cell. No re-ordering or accepting drops.
 */
@property (nonatomic,assign) BOOL                                           isReadOnly;
/*!
 Passed to the embedded UICollectionView layout.
 */
@property (nonatomic,assign) CGFloat                                        itemSize;
/*!
 Passed to the embedded UICollectionView layout.
 */
@property (nonatomic,assign) CGFloat                                        itemMargin;
/*!
 The embedded MDKUICollectionViewScrollContentSized
 */
@property (nonatomic,weak) IBOutlet MDKUICollectionViewScrollContentSized<MBLSRuleDragAndDropProtocol>  *collectionView;
/*!
 DataSource for the embedded MDKUICollectionViewScrollContentSized
 */
@property (nonatomic,strong) MBRuleCollectionDataSource                     *rulesSource;

@property (nonatomic,strong) NSLayoutConstraint                             *currentWidthConstraint;
@property (nonatomic,strong) NSLayoutConstraint                             *currentHeightConstraint;
@end
