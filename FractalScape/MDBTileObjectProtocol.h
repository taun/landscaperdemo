//
//  MDBTileObjectProtocol.h
//  FractalScape
//
//  Created by Taun Chapman on 12/03/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MDBTileObjectProtocol <NSObject>

@property (nonatomic,readonly) BOOL   isDefaultObject;
-(UIImage*) asImage;
-(instancetype) mutableCopy;

@end
