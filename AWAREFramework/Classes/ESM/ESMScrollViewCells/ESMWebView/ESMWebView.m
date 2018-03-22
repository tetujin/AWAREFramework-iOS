//
//  ESMWebView.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/14.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "ESMWebView.h"

@implementation ESMWebView{
    UIWebView * webView;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (instancetype)initWithFrame:(CGRect)frame esm:(EntityESM *)esm{
    self = [super initWithFrame:frame esm:esm];
    
    if(self != nil){
        [self addWebPageElement:esm withFrame:frame];
    }
    return self;
}



- (void) addWebPageElement:(EntityESM *)esm withFrame:(CGRect) frame {
    
    webView = [[UIWebView alloc] initWithFrame:CGRectMake(20,
                                                        0,
                                                        frame.size.width-40,
                                                        self.mainView.frame.size.height*3)];
    self.mainView.frame = CGRectMake(self.mainView.frame.origin.x,
                                     self.mainView.frame.origin.y,
                                     self.mainView.frame.size.width,
                                     webView.frame.size.height);
    webView.delegate = self;
    
    [self.mainView addSubview:webView];
    
    NSString *path = esm.esm_url;
    NSURL *url = [NSURL URLWithString:path];
    NSURLRequest *req = [NSURLRequest requestWithURL:url];
    [webView loadRequest:req];
    
    [self refreshSizeOfRootView];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    
}

- (NSNumber *)getESMState{
    return @2;
}


@end
