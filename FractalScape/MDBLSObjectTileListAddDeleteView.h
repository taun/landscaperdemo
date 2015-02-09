//
//  MDBLSObjectTileListAddDeleteView.h
//  FractalScape
//
//  Created by Taun Chapman on 02/09/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

@interface MDBLSObjectTileListAddDeleteView : UIView

@property (nonatomic,strong) IBOutlet id        delegate;
@property (weak, nonatomic) IBOutlet UIButton   *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton   *addButton;

- (IBAction)deletePressed:(id)sender;
- (IBAction)addPressed:(id)sender;

@end
