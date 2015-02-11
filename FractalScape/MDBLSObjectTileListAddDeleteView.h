//
//  MDBLSObjectTileListAddDeleteView.h
//  FractalScape
//
//  Created by Taun Chapman on 02/09/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE

enum MDBLSAddDeleteState {
    MDBLSNeutral = 0,
    MDBLSAdding,
    MDBLSDeleting
};
typedef enum MDBLSAddDeleteState MDBLSAddDeleteState;

@interface MDBLSObjectTileListAddDeleteView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic,strong) IBOutlet id                        delegate;
@property (weak, nonatomic) IBOutlet UIButton                   *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton                   *addButton;

@property (weak, nonatomic) IBOutlet UIView                     *content;
@property (strong, nonatomic) NSLayoutConstraint                *leftConstraint;
@property (strong, nonatomic) NSLayoutConstraint                *rightConstraint;
@property (readonly,nonatomic) MDBLSAddDeleteState               state;

- (IBAction)deletePressed:(id)sender;
- (IBAction)addPressed:(id)sender;

- (IBAction)addSwipeRecognized:(id)sender;
- (IBAction)deleteSwipeRecognized:(id)sender;

-(void) animateClosed: (BOOL)animate;
-(void) animateSlideForAdd;
-(void) animateSlideForDelete;

@end
