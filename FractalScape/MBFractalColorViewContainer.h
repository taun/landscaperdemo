//
//  MBFractalColorViewContainer.h
//  FractalScape
//
//  Created by Taun Chapman on 11/11/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FractalControllerProtocol.h"
#import "LSFractal+addons.h"
#import "MBColor+addons.h"
#import "MBLSRuleDragAndDropProtocol.h"
#import "MBColorSourceCollectionViewController.h"

@interface MBFractalColorViewContainer : UIViewController <FractalControllerProtocol, MBLSRuleDragAndDropProtocol, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic,strong) LSFractal          *fractal;
@property (nonatomic,weak) NSUndoManager        *fractalUndoManager;

@property (nonatomic,strong) NSArray            *cachedFractalColors;
@property (nonatomic,assign) BOOL               colorsChanged;

@property (weak, nonatomic) IBOutlet UIView *colorCollectionContainer;
@property (weak, nonatomic) IBOutlet UICollectionView *fractalLineColorsDestinationCollection;
@property (weak, nonatomic) IBOutlet UICollectionView *fractalFillColorsDestinationCollection;
@property (weak, nonatomic) IBOutlet UIImageView *lineColorsTemplateImageView;
@property (weak, nonatomic) IBOutlet UIImageView *fillColorsTemplateImageView;
@property (weak, nonatomic) IBOutlet UIImageView *pageColorTemplateImage;
@property (weak, nonatomic) IBOutlet UIImageView *pageColorDestinationImageView;

-(void)dragDidStartAtSourceCollection: (MBColorSourceCollectionViewController*) collectionViewController withGesture: (UIGestureRecognizer*) gesture;
-(void)dragDidChangeAtSourceCollection: (MBColorSourceCollectionViewController*) collectionViewController withGesture: (UIGestureRecognizer*) gesture;
-(void)dragDidEndAtSourceCollection: (MBColorSourceCollectionViewController*) collectionViewController withGesture: (UIGestureRecognizer*) gesture;
-(void)dragCancelledAtSourceCollection: (MBColorSourceCollectionViewController*) collectionViewController withGesture: (UIGestureRecognizer*) gesture;

@end
