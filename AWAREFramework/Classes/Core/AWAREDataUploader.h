//
//  AWAREDataUploader.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/7/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocalFileStorageHelper.h"
#import "AWAREUploader.h"
#import "AWAREStudy.h"

@interface AWAREDataUploader : AWAREUploader <AWAREDataUploaderDelegate,NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

- (instancetype) initWithLocalStorage:(LocalFileStorageHelper *)localStorage
                       withAwareStudy:(AWAREStudy *) study;

@end
