//
//  AWAREDelegate.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h>

#import "AWARECore.h"
#import "CoreDataHandler.h"

@interface AWAREDelegate : UIResponder <UIApplicationDelegate, GIDSignInDelegate,  UIAlertViewDelegate>
@property (strong, nonatomic) AWARECore * sharedAWARECore;
@property (strong, nonatomic) CoreDataHandler * sharedCoreDataHandler;
@property (strong, nonatomic) UIWindow *window;

@end
