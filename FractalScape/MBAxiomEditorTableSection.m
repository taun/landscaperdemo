//
//  MBAxiomEditorTableSection.m
//  FractalScape
//
//  Created by Taun Chapman on 10/09/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import "MBAxiomEditorTableSection.h"

@implementation MBAxiomEditorTableSection

+(instancetype) newWithTitle:(NSString *)title {
    return [[[self class] alloc] initWithTItle: title];
}
-(instancetype) initWithTItle:(NSString *)title {
    self = [super init];
    if (self) {
        _title = title;
        [self configureDefaults];
    }
    return self;
}
-(void)configureDefaults {
    _shouldIndentWhileEditing = NO;
    _canEditRow = YES;
}
@end

