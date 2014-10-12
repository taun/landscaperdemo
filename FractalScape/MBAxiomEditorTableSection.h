//
//  MBAxiomEditorTableSection.h
//  FractalScape
//
//  Created by Taun Chapman on 10/09/14.
//  Copyright (c) 2014 MOEDAE LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, enumTableSections) {
    TableSectionsDescription,
    TableSectionsAxiom,
    TableSectionsReplacement,
    TableSectionsRules
};

@interface MBAxiomEditorTableSection : NSObject

@property (nonatomic,strong) NSString       *title;
@property (nonatomic,assign) BOOL           shouldIndentWhileEditing;
@property (nonatomic,assign) BOOL           canEditRow;
@property (nonatomic,strong) NSMutableArray *data;

+(instancetype) newWithTitle: (NSString*) title;
-(instancetype) initWithTItle: (NSString*) title;

@end

