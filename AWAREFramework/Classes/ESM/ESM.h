//
//  ESM.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/16/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

/** ESM and WebESM plugin are replaced to iOS ESM ( = IOSESM class) plugin */

#import "AWARESensor.h"

@interface ESM : AWARESensor <AWARESensorDelegate>

// + (BOOL) isAppearedThisSection;
// + (void) setAppearedState:(BOOL)state;

@end
