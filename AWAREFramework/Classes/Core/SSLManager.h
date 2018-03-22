//
//  SSLManager.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/6/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SSLManager : NSObject

- (bool) installCRTWithAwareHostURL:(NSString *) url;
- (bool) installCRTWithTextOfQRCode:(NSString *) text;


@end
