//
//  MBLSReplacementRulesListView.h
//  FractalScape
//
//  Created by Taun Chapman on 11/25/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "LSReplacementRule+addons.h"
#import "LSDrawingRule+addons.h"

#import "MBLSRuleDragAndDropProtocol.h"

IB_DESIGNABLE


/*!
 View to show a vertical list of MBLSReplacementRuleTileView(s).
 */
@interface MBLSReplacementRulesListView : UIView <MBLSRuleDragAndDropProtocol>

@property (nonatomic,strong) NSMutableOrderedSet      *replacementRules;
@property (nonatomic,weak) NSManagedObjectContext       *context;

@property (nonatomic,assign) IBInspectable CGFloat      rowSpacing;
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;

- (IBAction)addSwipeRecognized:(id)sender;
- (IBAction)deleteSwipeRecognized:(id)sender;

- (IBAction)addPressed:(id)sender;
- (IBAction)deletePressed:(id)sender;
@end
