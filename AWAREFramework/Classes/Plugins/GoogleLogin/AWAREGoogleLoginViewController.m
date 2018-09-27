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
    // Do any additional setup after loading the view from its nib.
    
    // TODO (developer) Configure the sign-in button look/feel
    
    [GIDSignIn sharedInstance].uiDelegate = self;
    [GIDSignIn sharedInstance].delegate = self;
    
    // Uncomment to automatically sign in the user.
    //[[GIDSignIn sharedInstance] signInSilently];
    
    UIView * backscreen = [[UIView alloc] initWithFrame:self.view.frame];
    [backscreen setBackgroundColor:[UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1]];
    [self.view addSubview:backscreen];
    
    GIDSignInButton * button = [[GIDSignInButton alloc] initWithFrame:CGRectMake(0, 0, 230, 48)];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    NSLayoutConstraint *loginButtonCenterConstraint = [NSLayoutConstraint constraintWithItem:button
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1
                                                                    constant:0];
    NSLayoutConstraint *loginButtonBottomConstraint = [NSLayoutConstraint constraintWithItem:button
                                                                                   attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:-100];
    [self.view addSubview:button];
    [self.view addConstraint:loginButtonCenterConstraint];
    [self.view addConstraint:loginButtonBottomConstraint];
    
    ///////////////////////////
    
    _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    [_nameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    _nameLabel.textAlignment = NSTextAlignmentCenter;
    _nameLabel.text = @"Name";
    NSLayoutConstraint *nameLabelYConstraint = [NSLayoutConstraint constraintWithItem:_nameLabel
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.view
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1
                                                                    constant:0];
    NSLayoutConstraint *nameLabelXConstraint = [NSLayoutConstraint constraintWithItem:_nameLabel
                                                                            attribute:NSLayoutAttributeCenterX
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.view
                                                                            attribute:NSLayoutAttributeCenterX
                                                                           multiplier:1
                                                                             constant:0];
    [self.view addSubview:_nameLabel];
    [self.view addConstraint:nameLabelYConstraint];
    [self.view addConstraint:nameLabelXConstraint];
    
    ///////////////////////////
    
    _accountIdLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    [_accountIdLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    _accountIdLabel.textAlignment = NSTextAlignmentCenter;
    _accountIdLabel.text = @"Account ID";
    NSLayoutConstraint *accountLabelBottomConstraint = [NSLayoutConstraint constraintWithItem:_accountIdLabel
                                                                            attribute:NSLayoutAttributeCenterY
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:_nameLabel
                                                                            attribute:NSLayoutAttributeCenterY
                                                                           multiplier:1
                                                                             constant:-60];
    NSLayoutConstraint *accountLabelXConstraint = [NSLayoutConstraint constraintWithItem:_accountIdLabel
                                                                            attribute:NSLayoutAttributeCenterX
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.view
                                                                            attribute:NSLayoutAttributeCenterX
                                                                           multiplier:1
                                                                             constant:0];
    [self.view addSubview:_accountIdLabel];
    [self.view addConstraint:accountLabelBottomConstraint];
    [self.view addConstraint:accountLabelXConstraint];
    
    ////////////////////////////
    _emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    [ _emailLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
     _emailLabel.textAlignment = NSTextAlignmentCenter;
     _emailLabel.text = @"Email";
    NSLayoutConstraint * emailLabelBottomConstraint = [NSLayoutConstraint constraintWithItem: _emailLabel
                                                                                    attribute:NSLayoutAttributeCenterY
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:_nameLabel
                                                                                    attribute:NSLayoutAttributeCenterY
                                                                                   multiplier:1
                                                                                     constant:60];
    NSLayoutConstraint * emailLabelXConstraint = [NSLayoutConstraint constraintWithItem: _emailLabel
                                                                               attribute:NSLayoutAttributeCenterX
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:self.view
                                                                               attribute:NSLayoutAttributeCenterX
                                                                              multiplier:1
                                                                                constant:0];
    [self.view addSubview:_emailLabel];
    [self.view addConstraint:emailLabelBottomConstraint];
    [self.view addConstraint:emailLabelXConstraint];
    
    ///////////////////////////////
    _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 230, 48)];
    [_closeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_closeButton setTitle:@"Close" forState:UIControlStateNormal];
    [_closeButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(puhsedCloseButton:) forControlEvents:UIControlEventTouchUpInside];
    
    NSLayoutConstraint *closeButtonCenterConstraint = [NSLayoutConstraint constraintWithItem:_closeButton
                                                                                   attribute:NSLayoutAttributeCenterX
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:self.view
                                                                                   attribute:NSLayoutAttributeCenterX
                                                                                  multiplier:1
                                                                                    constant:0];
    NSLayoutConstraint *closeButtonBottomConstraint = [NSLayoutConstraint constraintWithItem:_closeButton
                                                                                   attribute:NSLayoutAttributeBottom
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:button
                                                                                   attribute:NSLayoutAttributeBottom multiplier:1 constant:50];
    [self.view addSubview:_closeButton];
    [self.view addConstraint:closeButtonCenterConstraint];
    [self.view addConstraint:closeButtonBottomConstraint];

    ///////////////////////////////
    _logLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 230, 48)];
    [_logLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_logLabel setText:@"Push 'Sign in' to Login Your Account!"];
    [_logLabel setTextColor:[UIColor grayColor]];
    
    NSLayoutConstraint *logLabelCenterConstraint = [NSLayoutConstraint constraintWithItem:_logLabel
                                                                                   attribute:NSLayoutAttributeCenterX
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:self.view
                                                                                   attribute:NSLayoutAttributeCenterX
                                                                                  multiplier:1
                                                                                    constant:0];
    NSLayoutConstraint *logLabelBottomConstraint = [NSLayoutConstraint constraintWithItem:_logLabel
                                                                                   attribute:NSLayoutAttributeBottom
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:self.accountIdLabel
                                                                                   attribute:NSLayoutAttributeBottom multiplier:1 constant:-120];
    [self.view addSubview:_logLabel];
    [self.view addConstraint:logLabelCenterConstraint];
    [self.view addConstraint:logLabelBottomConstraint];
    
    [self showUserInfo];
}

- (void) puhsedCloseButton:(UIButton *)button{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) showUserInfo{
    if ([GoogleLogin getGoogleUserId]!=nil) {
        _accountIdLabel.text = [GoogleLogin getGoogleUserId];
    }

    if ([GoogleLogin getGoogleUserName]!=nil) {
        _nameLabel.text = [GoogleLogin getGoogleUserName];
    }

    if ([GoogleLogin getGoogleUserEmail]!=nil) {
        _emailLabel.text = [GoogleLogin getGoogleUserEmail];
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
    _logLabel.text = @"Dismiss the 'Sign in with Google'";
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Retrieving user information
- (void)signIn:(GIDSignIn *)signIn
     didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    if (_googleLogin!=nil) {
        _logLabel.text = @"Login Success!";
        [_googleLogin setGoogleAccountWithUserId:user.userID
                                            name:user.profile.name
                                           email:user.profile.email];
    }else{
        _logLabel.text = @"Login Error";
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
