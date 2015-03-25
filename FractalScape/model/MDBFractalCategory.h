//
//  MDBFractalCategory.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/02/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;

@interface MDBFractalCategory : NSObject <NSCoding>

@property(nonatomic,copy) NSString*     identifier;
@property(nonatomic,copy) NSString*     name;


+(instancetype)newCategoryIdentifier: (NSString*)identifier name: (NSString*)name;
-(instancetype)initWithIdentifier: (NSString*)identifier name: (NSString*)name;

@end
