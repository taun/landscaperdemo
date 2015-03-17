//
//  MBFractalColorViewContainer.h
//  FractalScape
//
//  Created by Taun Chapman on 11/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//


@import Foundation;
@import UIKit;

#import "FractalControllerProtocol.h"
#import "LSFractal.h"
#import "MBColor.h"
#import "MBColorCategory.h"
#import "MBLSRuleDragAndDropProtocol.h"
#import "MDBColorCategoriesListView.h"
#import "MDBColorCategoryListView.h"
#import "MBLSObjectListTileViewer.h"
#import "MDBLSObjectTilesViewBaseController.h"
#import "MDBFractalPageColorTileView.h"

#import "MBFractalPrefConstants.h"


@interface MBFractalColorViewContainer : MDBLSObjectTilesViewBaseController


@property (weak, nonatomic) IBOutlet MBLSObjectListTileViewer       *fillColorsListView;

@property (weak, nonatomic) IBOutlet UIImageView                    *lineColorsTemplateImageView;
@property (weak, nonatomic) IBOutlet UIImageView                    *fillColorsTemplateImageView;
@property (weak, nonatomic) IBOutlet MDBFractalPageColorTileView    *pageColorDestinationTileView;
@property (weak, nonatomic) IBOutlet UIVisualEffectView             *visualEffectView;


- (IBAction)lineColorLongPress:(UILongPressGestureRecognizer *)sender;
- (IBAction)fillColorLongPress:(UILongPressGestureRecognizer *)sender;

- (IBAction)colorSourceTapGesture:(UITapGestureRecognizer *)sender;
- (IBAction)pageColorTapGesture:(UITapGestureRecognizer *)sender;
- (IBAction)lineColorTapGesture:(UITapGestureRecognizer *)sender;
- (IBAction)fillColorTapGesture:(UITapGestureRecognizer *)sender;

@end
