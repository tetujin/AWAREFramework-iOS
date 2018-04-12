//
//  CoreDataHandler.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/03.
//

#import "CoreDataHandler.h"
#import <UserNotifications/UserNotifications.h>

static CoreDataHandler * sharedHandler;

@implementation CoreDataHandler

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize status = _status;

+ (CoreDataHandler * )sharedHandler {
    @synchronized(self){
        if (!sharedHandler){
            sharedHandler = [[CoreDataHandler alloc] init];
        }
    }
    return sharedHandler;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedHandler == nil) {
            sharedHandler= [super allocWithZone:zone];
            return sharedHandler; // 初回のallocationで代入して返す
        }
    }
    return nil;
}

- (instancetype)init{
    self = [super init];
    if(self!= nil){
        self.status = AwareSQLiteStatusUnknown;
        // check migration requirement at here
        if ([self isNeedMigration]) {
            self.status = AwareSQLiteStatusNeedNigration;
        }else{
            self.status = AwareSQLiteStatusNormal;
        }
        // if the migration reuqired, aware send notification every 1 hour without mid-night.
    }
    return self;
}

- (BOOL) isNeedMigration {
    NSError * error = nil;
    // NSURL * url = _sqliteModelURL = [[NSBundle mainBundle] URLForResource:@"AWARE" withExtension:@"momd"];
    if (_sqliteFileURL == nil) {
        _sqliteFileURL  = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
    }
    NSDictionary *sourceMetaData = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                              URL:_sqliteFileURL
                                                                                          options:nil
                                                                                            error:&error];
    if (error!=nil) {
        NSLog(@"[CoreDataHandler] error at isNeedMigration: %@", error.debugDescription);
    }
    BOOL isCompatible = [self.managedObjectModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetaData];
    if (isCompatible) {
        return NO;
    }else{
        return YES;
    }
}


- (BOOL) migrateSQLite{
    NSPersistentStoreCoordinator * coordinator = [self persistentStoreCoordinator];
    if (coordinator!=nil) {
        self.status = AwareSQLiteStatusNormal;
        [self deleteBackupSQLite];
        return YES;
    }
    [self stopMigrationRequestReminders];
    return NO;
}

/*! Creates a backup of the Local store
 
 @return Returns YES of file was migrated or NO if not.
 */
- (BOOL) backupSQLite {
    // Lets use the existing PSC
    NSPersistentStoreCoordinator *migrationPSC = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    
    if (_sqliteFileURL == nil) {
        _sqliteFileURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
    }
    // Open the store
    id sourceStore = [migrationPSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:_sqliteFileURL options:nil error:nil];
    
    if (!sourceStore) {
        
        NSLog(@" failed to add old store");
        migrationPSC = nil;
        return FALSE;
    } else {
        NSLog(@" Successfully added store to migrate");
        
        NSError *error;
//        NSURL *backupStoreURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"AWARE_%@.sqlite",[NSDate new].debugDescription]];
        NSURL *backupStoreURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE-bkp.sqlite"];
        NSLog(@" About to migrate the store...");
        id migrationSuccess = [migrationPSC migratePersistentStore:sourceStore toURL:backupStoreURL options:nil withType:NSSQLiteStoreType error:&error];
        
        if (migrationSuccess) {
            NSLog(@"store successfully backed up");
            migrationPSC = nil;
            // Now reset the backup preference
            // [[NSUserDefaults standardUserDefaults] setBool:NO forKey:_makeBackupPreferenceKey];
            // [[NSUserDefaults standardUserDefaults] synchronize];
            return TRUE;
        }
        else {
            NSLog(@"Failed to backup store: %@, %@", error, error.userInfo);
            migrationPSC = nil;
            return FALSE;
        }
    }
    migrationPSC = nil;
    return FALSE;
}


- (BOOL)resetCoreData{
    for(NSPersistentStore * store in self.managedObjectContext.persistentStoreCoordinator.persistentStores){
        NSError * error = nil;
        bool isRemoved = [self.managedObjectContext.persistentStoreCoordinator removePersistentStore:store error:&error];
        if (error !=nil) NSLog(@"%@",error.debugDescription);
        if (!isRemoved) {
            return NO;
        }
    }
    return YES;
}


- (void) deleteBackupSQLite{
    NSURL *storeURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"AWARE-bkp.sqlite"];
    NSPersistentStoreCoordinator *storeCoodinator = [self.managedObjectContext persistentStoreCoordinator];
    NSPersistentStore  *store = [storeCoodinator persistentStoreForURL:storeURL];
    NSError *error;
    [storeCoodinator removePersistentStore:store error:&error];
    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
    
    // Add new PersistentStore
    [storeCoodinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
    
    // Reset NSFetchedResultController
    [NSFetchedResultsController deleteCacheWithName:@"Root"];
}



- (void)sendMigrationRequestReminders{
    UNMutableNotificationContent * context = [[UNMutableNotificationContent alloc] init];
    context.title = @"AWARE client needs to migrate your storage ASAP";
    context.body  = @"Please open the app and conduct the migration. This reminder will stop after finish the migration.";
    context.badge = @1;
    context.sound = [UNNotificationSound defaultSound];
    
    UNNotificationTrigger * trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    
    NSString * requestId = @"aware.qlite.migration.request.reminder";
    
    [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:@[requestId]];
    [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:@[requestId]];
    
    UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:requestId content:context trigger:trigger];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error!=nil) {
            NSLog(@"[CoreDataHandler] %@", error.debugDescription);
        }
    }];
    
    for (int h=8; h<21; h=h+2) {
        NSDateComponents * components = [[NSDateComponents alloc] init];
        components.hour = h;
        UNNotificationTrigger * timeTrigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:YES];
        UNNotificationRequest * timeRequest = [UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"%@.%d",requestId,h] content:context trigger:timeTrigger];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:timeRequest withCompletionHandler:^(NSError * _Nullable error) {
            if (error!=nil) {
                NSLog(@"[CoreDataHandler] %@", error.debugDescription);
            }
        }];
    }
}


- (void)stopMigrationRequestReminders{
    NSString * requestId = @"aware.qlite.migration.request.reminder";
    NSMutableArray * notificationIds = [[NSMutableArray alloc] init];
    [notificationIds addObject:requestId];
    for (int h=8; h<21; h=h+2) {
        NSString * timeReminderId = [NSString stringWithFormat:@"%@.%d",requestId,h];
        [notificationIds addObject:timeReminderId];
    }
    [[UNUserNotificationCenter currentNotificationCenter] removePendingNotificationRequestsWithIdentifiers:notificationIds];
    [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:notificationIds];
}


- (NSURL *)applicationDocumentsDirectory {
    // NSLog(@"%@",[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory  inDomains:NSUserDomainMask] lastObject]);
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    if (_sqliteModelURL == nil) {
        _sqliteModelURL = [[NSBundle mainBundle] URLForResource:@"AWARE" withExtension:@"momd"];
    }
    // NSURL *modelURL = _sqliteModelURL; // [[NSBundle mainBundle] URLForResource:@"AWARE" withExtension:@"momd"];
    //    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:_sqliteModelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    // NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    
    /*********** options  ***********/
    NSDictionary *options = nil;
    if ([self isNeedMigration]) {
        options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                                 nil];
    }
    
    if (_sqliteFileURL == nil) {
        _sqliteFileURL  = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
    }
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:_sqliteFileURL options:options error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            // abort();
        }
    }
}


@end