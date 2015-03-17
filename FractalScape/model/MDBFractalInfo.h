//
//  MDBFractalInfo.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/04/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
#import "MDBFractalDocument.h"
#import "LSFractal.h"
#import "MDBFractalCategory.h"

@interface MDBFractalInfo : NSObject

@property(nonatomic,copy,readonly) NSString             *identifier;
@property(nonatomic,copy,readonly) NSString             *name;
@property(nonatomic,copy,readonly) NSString             *descriptor;
@property(nonatomic,strong,readonly) MDBFractalCategory  *category;
@property(nonatomic,strong,readonly) UIImage            *thumbnail;
@property (nonatomic,strong,readonly) NSURL             *URL;

- (instancetype)initWithURL:(NSURL *)URL;
- (void)fetchInfoWithCompletionHandler:(void (^)(void))completionHandler;

@end
