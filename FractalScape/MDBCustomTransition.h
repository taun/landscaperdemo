//  Created by Taun Chapman on 03/28/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

@import Foundation;
@import UIKit;


@interface MDBCustomTransition : NSObject <UIViewControllerAnimatedTransitioning>

@end

@interface MDBZoomPushTransition : MDBCustomTransition

@end

@interface MDBZoomPopTransition : MDBCustomTransition

@end

@interface MDBZoomPushBounceTransition : MDBCustomTransition

@end

@interface MDBZoomPopBounceTransition : MDBCustomTransition

@end