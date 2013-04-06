//
//  MBLSFractalLevelNView.h
//  LandscaperDemo
//
//  Created by Taun Chapman on 03/10/12.
//  Copyright (c) 2012 MOEDAE LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MBLSFractalLevelNView : UIView

@property (weak, nonatomic) IBOutlet UIView*        fractalView;
@property (weak, nonatomic) IBOutlet UIView*        sliderContainerView;
@property (weak, nonatomic) IBOutlet UIView*        hudViewBackground;

@property (weak, nonatomic) IBOutlet UISlider*      slider;
@property (weak, nonatomic) IBOutlet UILabel*       hudLabel;
@property (weak, nonatomic) IBOutlet UILabel*       hudText1;
@property (weak, nonatomic) IBOutlet UILabel*       hudText2;

@end
