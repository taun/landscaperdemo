//
//  MBFractalPrefConstants.h
//  FractalScape
//
//  Created by Taun Chapman on 02/11/15.
//  Copyright (c) 2015 MOEDAE LLC. All rights reserved.
//

#ifndef FractalScape_MBFractalPrefConstants_h
#define FractalScape_MBFractalPrefConstants_h

static NSString*  kPrefLastEditedFractalURI = @"lastEditedFractalURI";
static NSString*  kPrefFullScreenState = @"fullScreenState";
static NSString*  kPrefShowPerformanceData = @"showPerformanceData";
static NSString*  kPrefParalaxOff = @"paralaxOff";
static NSString*  kPrefShowHelpTips = @"showEditHelp";

#pragma message "TODO The MaxNodes should be in something like a plist settings file so it can be easily updated"
#define kLSMaxNodesHiPerf 900000
#define kLSMaxNodesLoPerf 400000

#endif
