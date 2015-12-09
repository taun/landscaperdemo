//
//  MDBFractalDocumentProxy.m
//  FractalScapes
//
//  Created by Taun Chapman on 04/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#import "MDBFractalDocumentProxy.h"

@implementation MDBFractalDocumentProxy

-(UIDocumentState)documentState
{
    return UIDocumentStateClosed;
}

-(void)openWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    completionHandler(YES);
}

-(void)closeWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    completionHandler(YES);
}

-(void)saveToURL:(NSURL *)url forSaveOperation:(UIDocumentSaveOperation)saveOperation completionHandler:(void (^)(BOOL))completionHandler
{
    completionHandler(YES);
}

-(void)updateChangeCount:(UIDocumentChangeKind)change
{
    
}

@end
