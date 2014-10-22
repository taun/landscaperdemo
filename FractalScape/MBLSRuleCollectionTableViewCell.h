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

@property (nonatomic,weak) NSMutableOrderedSet                              *rules;
@property (nonatomic,weak) id                                               notifyObject;
@property (nonatomic,strong) NSString                                       *notifyPath;
@property (nonatomic,assign) BOOL                                           isReadOnly;
@property (nonatomic,assign) CGFloat                                        itemSize;
@property (nonatomic,assign) CGFloat                                        itemMargin;

@property (nonatomic,weak) IBOutlet MDKUICollectionViewScrollContentSized<MBLSRuleDragAndDropProtocol>  *collectionView;

@property (nonatomic,strong) MBRuleCollectionDataSource                     *rulesSource;
@property (nonatomic,weak) UIView                                           *lastEnteredView;
@property (nonatomic,strong) NSIndexPath                                    *lastIndexPath;

@end
