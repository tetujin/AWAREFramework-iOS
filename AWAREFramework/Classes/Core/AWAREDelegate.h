//
//  AWAREDelegate.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/2/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <CoreData/CoreData.h>
#import "AWARECore.h"

@interface AWAREDelegate : UIResponder <UIApplicationDelegate, GIDSignInDelegate,  UIAlertViewDelegate>

@property (strong, nonatomic) AWARECore * sharedAWARECore;

@property (strong, nonatomic) UIWindow *window;

// CoreDate
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) NSURL *sqliteModelURL;
@property (strong, nonatomic) NSURL *sqliteFileURL;

- (void)saveContext;



@end
