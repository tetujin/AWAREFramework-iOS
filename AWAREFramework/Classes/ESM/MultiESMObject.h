//
//  MultiESMObject.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/23/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "SingleESMObject.h"

@interface MultiESMObject : SingleESMObject
-(instancetype)initWithEsmText:(NSString*) esmText;
//- (NSDictionary *) getEsmAsDictionary;

@property (strong, nonatomic) IBOutlet NSMutableArray * esms;
@property (strong, nonatomic) IBOutlet NSString * esmStr;

@end
