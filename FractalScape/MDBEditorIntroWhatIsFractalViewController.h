//
//  MDBEditorIntroWhatIsFractalViewController.h
//  FractalScapes
//
//  Created by Taun Chapman on 08/17/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import UIKit;
@import WebKit;

@interface MDBEditorIntroWhatIsFractalViewController : UIViewController <WKUIDelegate, WKNavigationDelegate>

@property (nonatomic,strong) IBOutlet WKWebView      *webView;
@property (strong, nonatomic) IBOutlet UIView        *webContainer;
@property (strong, nonatomic) IBInspectable NSString *documentName;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *nextPageButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *prevPageButton;

- (IBAction)nextPage:(UIBarButtonItem *)sender;
- (IBAction)prevPage:(UIBarButtonItem *)sender;
- (IBAction)doneIntro:(UIBarButtonItem *)sender;
- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender;
- (IBAction)swipeRight:(UISwipeGestureRecognizer *)sender;
@end
