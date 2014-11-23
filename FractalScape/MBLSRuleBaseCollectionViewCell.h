//
//  MBLSRuleBaseCollectionViewCell.h
//  FractalScape
//
//  Created by Taun Chapman on 09/29/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LSDrawingRule+addons.h"
#import "MBLSRuleDragAndDropProtocol.h"

/*!
 Add autoloayout, MDKLayerView and MBLSRuleDragAndDropProtocol to a UICollectionView.
 */
@interface MBLSRuleBaseCollectionViewCell : UICollectionViewCell <MBLSRuleDragAndDropProtocol>
/*!
 The object to be stored in the cell. The fact that the actual object is stored in the cell is 
 used to facilitate the MBLSRuleDragAndDropProtocol implementation. It is assumed the cellItem has 
 a method asImage. This assumption needs to be made into a required protocol.
 */
@property (weak,nonatomic) id                       cellItem;
/*!
 The property name customImageView was chosen to avoid other MBLSRuleDragAndDropProtocol implementations from 
 having a name clash with the UITableViewCell's imageView property.
 */
@property (weak,nonatomic) IBOutlet UIImageView     *customImageView;
/*!
 This allows the image set for previewing in IB as the defaultImage.
 If the cellItem is nil, then the defaultImage will be used.
 */
@property (strong,nonatomic) UIImage                *defaultImage;
@end
