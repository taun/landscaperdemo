//  Created by Taun Chapman on 04/01/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "MDBDocumentController.h"


@interface MDBFractalCloudBrowser : UICollectionViewController

@property (nonatomic,strong) MDBDocumentController                          *documentController;

- (IBAction)downloadSelected:(id)sender;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
