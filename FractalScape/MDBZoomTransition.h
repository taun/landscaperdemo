//
//  MDBZoomTransition.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/27/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;


typedef NS_ENUM(NSInteger, AnimationType) {
    AnimationTypePresent = 0,
    AnimationTypeDismiss
};

@interface MDBZoomTransition : NSObject <UIViewControllerAnimatedTransitioning, UINavigationControllerDelegate>

@property(nonatomic,assign)AnimationType       type;

@end
