//
//  MDBFractalInfo.h
//  FractalScapes
//
//  Created by Taun Chapman on 03/04/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;

@class MDBFractalDocument;
@class LSFractal;

@interface MDBFractalInfo : NSObject

@property(nonatomic,copy,readonly) NSString             *identifier;
@property(nonatomic,strong,readonly) NSURL              *URL;
@property(nonatomic,strong) NSDate                      *changeDate;
@property(nonatomic,strong,readonly) MDBFractalDocument *document;

+ (instancetype)newFractalInfoWithURL: (NSURL*)url forFractal: (LSFractal*)fractal documentDelegate: (id)delegate;
- (instancetype)initWithURL:(NSURL *)URL;
- (void)fetchDocumentWithCompletionHandler:(void (^)(void))completionHandler;
- (void)unCacheDocument;
@end
