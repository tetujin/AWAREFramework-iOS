//
//  AWAREGoogleLoginViewController.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/09/27.
//

#import "AWAREGoogleLoginViewController.h"

@interface AWAREGoogleLoginViewController ()

@end

@implementation AWAREGoogleLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [GIDSignIn sharedInstance].delegate = self;
    
    [GIDSignIn sharedInstance].presentingViewController = self;
    [[GIDSignIn sharedInstance] restorePreviousSignIn];
    
    // Uncomment to automatically sign in the user.
    //[[GIDSignIn sharedInstance] signInSilently];
    
    _backgroundView = [[UIView alloc] initWithFrame:self.view.frame];
    [_backgroundView setBackgroundColor:[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1]];
    [self.view addSubview:_backgroundView];
    
    _googleLoginButton = [[GIDSignInButton alloc] initWithFrame:CGRectMake(0, 0, 312, 48)];
    [_googleLoginButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_googleLoginButton setStyle:kGIDSignInButtonStyleWide];
    _googleLoginButtonCenterConstraint = [NSLayoutConstraint constraintWithItem:_googleLoginButton
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1
                                                                    constant:0];
    _googleLoginButtonBottomConstraint = [NSLayoutConstraint constraintWithItem:_googleLoginButton
                                                                                   attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:-200];
    [self.view addSubview:_googleLoginButton];
    [self.view addConstraint:_googleLoginButtonCenterConstraint];
    [self.view addConstraint:_googleLoginButtonBottomConstraint];
    
    ///////////////////////////
    
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    [_nameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _nameLabel.text = @"Name";
    _nameLabelYConstraint = [NSLayoutConstraint constraintWithItem:_nameLabel
                                                           attribute:NSLayoutAttributeCenterY
                                                           relatedBy:NSLayoutRelationEqual
                                                              toItem:self.view
                                                           attribute:NSLayoutAttributeCenterY
                                                          multiplier:1
                                                            constant:0];
    _nameLabelXConstraint = [NSLayoutConstraint constraintWithItem:_nameLabel
                                                            attribute:NSLayoutAttributeCenterX
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:self.view
                                                            attribute:NSLayoutAttributeCenterX
                                                           multiplier:1
                                                             constant:0];
    [self.view addSubview:_nameLabel];
    [self.view addConstraint:_nameLabelYConstraint];
    [self.view addConstraint:_nameLabelXConstraint];
    
    ////////////
    _phonenumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    [_phonenumberLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    _phonenumberLabel.textAlignment = NSTextAlignmentCenter;
    _phonenumberLabel.text = @"Phone Number";
    _phonenumberLabelYConstraint = [NSLayoutConstraint constraintWithItem:_phonenumberLabel
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_nameLabel
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1
                                                                 constant:-40];
    _phonenumberLabelXConstraint = [NSLayoutConstraint constraintWithItem:_phonenumberLabel
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self.view
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1
                                                                 constant:0];
    
    ///////////////////////////
    
    [self.view addSubview:_phonenumberLabel];
    [self.view addConstraint:_phonenumberLabelYConstraint];
    [self.view addConstraint:_phonenumberLabelXConstraint];
    
    ////////////////////////////
    _emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    [ _emailLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
     _emailLabel.textAlignment = NSTextAlignmentCenter;
     _emailLabel.text = @"Email";
    _emailLabelYConstraint = [NSLayoutConstraint constraintWithItem: _emailLabel
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_nameLabel
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1
                                                         constant:40];
    _emailLabelXConstraint = [NSLayoutConstraint constraintWithItem: _emailLabel
                                                                               attribute:NSLayoutAttributeCenterX
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.view
                                                                               attribute:NSLayoutAttributeCenterX
                                                                              multiplier:1
                                                                                constant:0];
    [self.view addSubview:_emailLabel];
    [self.view addConstraint:_emailLabelYConstraint];
    [self.view addConstraint:_emailLabelXConstraint];
    
    
    ///////////////////////////////
    _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 230, 48)];
    [_closeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_closeButton setTitle:@"Close" forState:UIControlStateNormal];
    [_closeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(puhsedCloseButton:) forControlEvents:UIControlEventTouchUpInside];
    
    _closeButtonCenterConstraint = [NSLayoutConstraint constraintWithItem:_closeButton
                                                                                   attribute:NSLayoutAttributeCenterX
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:self.view
                                                                                   attribute:NSLayoutAttributeCenterX
                                                                                  multiplier:1
                                                                                    constant:0];
    _closeButtonYConstraint = [NSLayoutConstraint constraintWithItem:_closeButton
                                                                                   attribute:NSLayoutAttributeBottom
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:_googleLoginButton
                                                                                   attribute:NSLayoutAttributeBottom multiplier:1 constant:50];
    [self.view addSubview:_closeButton];
    [self.view addConstraint:_closeButtonCenterConstraint];
    [self.view addConstraint:_closeButtonYConstraint];

    ///////////////////////////////
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 230, 48)];
    [_messageLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_messageLabel setNumberOfLines:2];
    [_messageLabel setText:@" Push 'Sign in with Google' \n to Login Your Account! "];
    [_messageLabel setTextColor:[UIColor grayColor]];
    [_messageLabel setTextAlignment:NSTextAlignmentCenter];
    
    _messageLabelCenterConstraint = [NSLayoutConstraint constraintWithItem:_messageLabel
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.view
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1
                                                                constant:0];
    _messageLabelYConstraint = [NSLayoutConstraint constraintWithItem:_messageLabel
                                                               attribute:NSLayoutAttributeBottom
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.phonenumberLabel
                                                               attribute:NSLayoutAttributeBottom multiplier:1 constant:-120];
    [self.view addSubview:_messageLabel];
    [self.view addConstraint:_messageLabelCenterConstraint];
    [self.view addConstraint:_messageLabelYConstraint];
    
    [self showUserInfo];
}

- (void) puhsedCloseButton:(UIButton *)button{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) showUserInfo{
    if ([GoogleLogin getUserName]!=nil) {
        _nameLabel.text = [GoogleLogin getUserName];
    }

    if ([GoogleLogin getEmail]!=nil) {
        _emailLabel.text = [GoogleLogin getEmail];
    }
    
    if ([GoogleLogin getPhonenumber]!=nil) {
        _phonenumberLabel.text = [GoogleLogin getPhonenumber];
    }

}

- (void)viewDidAppear:(BOOL)animated{
    if (_googleLogin==nil) {
        NSLog(@"Please set a GoogleLogin instance to _googleLogin before move to this page.");
    }
}

// Stop the UIActivityIndicatorView animation that was started when the user
// pressed the Sign In button
- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {
    // [myActi,vityIndicator stopAnimating];
    NSLog(@"%@",signIn.clientID);
}

// Present a view that prompts the user to sign in with Google
- (void)signIn:(GIDSignIn *)signIn
presentViewController:(UIViewController *)viewController {
    // _logLabel.text = @"Present a view that prompts the user to sign in with Google";
    [self presentViewController:viewController animated:YES completion:nil];
}

// Dismiss the "Sign in with Google" view
- (void)signIn:(GIDSignIn *)signIn
dismissViewController:(UIViewController *)viewController {
    _messageLabel.text = @"Dismiss the 'Sign in with Google'";
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Retrieving user information
- (void)signIn:(GIDSignIn *)signIn
     didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    if (_googleLogin!=nil) {
        _messageLabel.text = @"Login Success!";
        [_googleLogin setGoogleAccountWithUserName:user.profile.name
                                             email:user.profile.email
                                       phonenumber:@""
                                           picture:nil];
    }else{
        _messageLabel.text = @"Login Error";
    }
    [self showUserInfo];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
