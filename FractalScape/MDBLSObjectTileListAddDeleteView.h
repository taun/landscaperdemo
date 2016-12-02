//
//  MDBLSObjectTileListAddDeleteView.h
//  FractalScape
//
//  Created by Taun Chapman on 02/09/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;


IB_DESIGNABLE

typedef NS_ENUM(NSUInteger, MDBLSAddDeleteState) {
    MDBLSNeutral = 0,
    MDBLSAdding,
    MDBLSDeleting
};

@interface MDBLSObjectTileListAddDeleteView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic,strong) IBOutlet id                        delegate;
@property (weak, nonatomic) IBOutlet UIButton                   *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton                   *addButton;

@property (weak, nonatomic) IBOutlet UIView                     *content;
@property (strong, nonatomic) NSLayoutConstraint                *leftConstraint;
@property (strong, nonatomic) NSLayoutConstraint                *rightConstraint;
@property (readonly,nonatomic) MDBLSAddDeleteState               state;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deleteControlConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addControlConstraint;

// Properties for subviews
@property (nonatomic,assign) IBInspectable CGFloat      tileWidth;
@property (nonatomic,assign) IBInspectable CGFloat      tileMargin;
@property (nonatomic,assign) IBInspectable BOOL         showTileBorder;
@property (nonatomic,assign) IBInspectable BOOL         showOutline;
@property (nonatomic,assign) IBInspectable BOOL         justify;


- (IBAction)deletePressed:(id)sender;
- (IBAction)addPressed:(id)sender;

- (IBAction)addSwipeRecognized:(id)sender;
- (IBAction)deleteSwipeRecognized:(id)sender;
- (IBAction)tapGestureRecognized:(id)sender;

-(IBAction)deleteButtonEnabled:(BOOL)enabled;

-(void) animateClosed: (BOOL)animate;
-(void) animateSlideForAdd;
-(void) animateSlideForDelete;

-(void) animatePeekaboo;

-(void) startBlinkOutline;
-(void) endBlinkOutline;

@end
