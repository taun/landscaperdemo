//
//  MDBAppModel.h
//  FractalScapes
//
//  Created by Taun Chapman on 04/23/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;

@class MDBDocumentController;


extern NSString *const kMDBFractalScapesFirstLaunchUserDefaultsKey;


@interface MDBAppModel : NSObject

@property(nonatomic,assign,getter=isFirstLaunch) BOOL           firstLaunch;
@property(nonatomic, strong) MDBDocumentController             *documentController;
@property(nonatomic,readonly) BOOL                              allowPremium;

@end
