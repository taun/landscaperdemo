//
//  MDBFilterObjectTile.m
//  FractalScapes
//
//  Created by Taun Chapman on 03/30/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MBImageFilter.h"

@implementation MBImageFilter

+(NSSortDescriptor*) sortDescriptor
{
    return  [NSSortDescriptor sortDescriptorWithKey: @"identifier" ascending: YES];
}


@end
