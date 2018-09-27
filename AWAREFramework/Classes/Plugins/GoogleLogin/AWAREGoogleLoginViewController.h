//
//  AWAREGoogleLoginViewController.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/09/27.
//

#import <UIKit/UIKit.h>
@import GoogleSignIn;
#import "GoogleLogin.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWAREGoogleLoginViewController : UIViewController <GIDSignInUIDelegate, GIDSignInDelegate>

@property GoogleLogin * googleLogin;

@property UILabel  * logLabel;
@property UILabel  * accountIdLabel;
@property UILabel  * nameLabel;
@property UILabel  * emailLabel;
@property UIView   * buttonSpace;
@property UIButton * closeButton;

- (void) puhsedCloseButton:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
