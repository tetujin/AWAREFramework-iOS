//
//  AWAREGoogleLoginViewController.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/09/27.
//

#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import "GoogleLogin.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWAREGoogleLoginViewController : UIViewController <GIDSignInDelegate>

// Google Login Instance
@property GoogleLogin * googleLogin;

// Background View (Gray Color)
@property UIView * backgroundView;

// Google Login SignIn Button
@property GIDSignInButton * googleLoginButton;
@property NSLayoutConstraint * googleLoginButtonCenterConstraint;
@property NSLayoutConstraint * googleLoginButtonBottomConstraint;

// Message Label (Push 'Sign in with Google' to Login Your Account!)
@property UILabel  * messageLabel;
@property NSLayoutConstraint *messageLabelYConstraint;
@property NSLayoutConstraint *messageLabelCenterConstraint;

// Phonenumber Label (Phonenumber)
@property UILabel  * phonenumberLabel;
@property NSLayoutConstraint *phonenumberLabelYConstraint;
@property NSLayoutConstraint *phonenumberLabelXConstraint;

// Name Label (Name)
@property UILabel  * nameLabel;
@property NSLayoutConstraint * nameLabelYConstraint;
@property NSLayoutConstraint * nameLabelXConstraint;

// Email Label (Email)
@property UILabel  * emailLabel;
@property NSLayoutConstraint * emailLabelYConstraint;
@property NSLayoutConstraint * emailLabelXConstraint;

// Close Button (Close)
@property UIButton * closeButton;
@property NSLayoutConstraint * closeButtonCenterConstraint;
@property NSLayoutConstraint * closeButtonYConstraint;

- (void) puhsedCloseButton:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
