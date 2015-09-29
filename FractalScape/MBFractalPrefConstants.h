//
//  MBFractalPrefConstants.h
//  FractalScape
//
//  Created by Taun Chapman on 02/11/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#ifndef FractalScape_MBFractalPrefConstants_h
#define FractalScape_MBFractalPrefConstants_h

static NSString* const  kPrefUseICloudStorage = @"com.moedae.FractalScapes.useICloudStorage";
static NSString* const  kPrefUbiquityIdentityToken = @"com.moedae.FractalScapes.ubiquityIdentityToken";

#pragma message "TODO The MaxNodes should be in something like a plist settings file so it can be easily updated"
#define kLSMaxNodesHiPerf 900000
#define kLSMaxNodesLoPerf 300000

#endif
