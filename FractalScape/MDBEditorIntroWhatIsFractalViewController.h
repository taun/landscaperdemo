//
//  MDBEditorIntroWhatIsFractalViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 08/17/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;
@import WebKit;

@interface MDBEditorIntroWhatIsFractalViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic,strong) IBOutlet WKWebView      *webView;
@property (strong, nonatomic) IBOutlet UIView        *webContainer;
@property (strong, nonatomic) IBInspectable NSString *documentName;

@end
