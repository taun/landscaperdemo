//
//  MDBFractalDocumentProxy.h
//  FractalScapes
//
//  Created by Taun Chapman on 04/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDBFractalDocument.h"

@interface MDBFractalDocumentProxy : NSObject <MDBFractaDocumentProtocol>

@property(nonatomic,strong) LSFractal                       *fractal;
@property(nonatomic,strong) UIImage                         *thumbnail;
@property(nonatomic,readwrite) MDBFractalDocumentLoadResult  loadResult;
@property(nonatomic,readonly) NSString                      *loadResultString;
@property(nonatomic,readonly) NSURL                         *fileURL;

@end
