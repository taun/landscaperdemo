//
//  MDBFractalDocumentCloudCoordinator.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/05/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
#import "MDBFractalDocumentCoordinator.h"

@interface MDBFractalDocumentCloudCoordinator : NSObject <MDBFractalDocumentCoordinator>

- (instancetype)initWithPathExtension:(NSString *)pathExtension;

- (instancetype)initWithLastPathComponent:(NSString *)lastPathComponent;

@end
