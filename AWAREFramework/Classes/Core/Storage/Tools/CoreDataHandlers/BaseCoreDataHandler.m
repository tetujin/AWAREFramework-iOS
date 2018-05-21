//
//  BaseCoreDataHandler.m
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/05/21.
//

#import "BaseCoreDataHandler.h"
#import <CoreData/CoreData.h>
#import <UserNotifications/UserNotifications.h>

@implementation BaseCoreDataHandler

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize status = _status;
@synthesize sqliteFileURL;

- (instancetype)init{
    self = [super init];
    if(self!= nil){
        self.status = AwareSQLiteStatusUnknown;
        
        // check migration requirement at here
        if (self.sqliteFileURL == nil) {
            self.sqliteFileURL  = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
        }
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:self.sqliteFileURL.path]){
            if ([self isNeedMigration]) {
                self.status = AwareSQLiteStatusNeedNigration;
            }else{
                self.status = AwareSQLiteStatusNormal;
            }
        }else{
            self.status = AwareSQLiteStatusNormal;
        }
        /// @todo if the migration reuqired, aware send notification every 1 hour without mid-night.
    }
    return self;
}

- (BOOL) isNeedMigration {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:self.sqliteFileURL.path]){
        return NO;
    }
    
    NSError * error = nil;
    if (self.sqliteFileURL == nil) {
        self.sqliteFileURL  = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
    }
    NSDictionary *sourceMetaData = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                              URL:self.sqliteFileURL
                                                                                          options:nil
                                                                                            error:&error];
    if (error!=nil) {
        NSLog(@"[CoreDataHandler] error at isNeedMigration: %@, %@", error.debugDescription, error.domain);
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
    
    if (self.sqliteFileURL == nil) {
        self.sqliteFileURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
    }
    // Open the store
    id sourceStore = [migrationPSC addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.sqliteFileURL options:nil error:nil];
    
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


- (BOOL) resetCoreData {
    
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
    
    NSURL * url = [[NSBundle mainBundle] URLForResource:@"AWARE" withExtension:@"momd"];
    
    // NSURL *modelURL = _sqliteModelURL; // [[NSBundle mainBundle] URLForResource:@"AWARE" withExtension:@"momd"];
    //    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    return _managedObjectModel;
}

- (void) overwriteManageObjectModelWithFileURL:(NSURL *)url{
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
}

- (void) overwriteDatabasePathWithFileURL:(NSURL *)url{
    self.sqliteFileURL = url;
}

- (void) overwriteManageObjectModelWithName:(NSString *)name{
    NSURL * modelURL = [[NSBundle mainBundle] URLForResource:name withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (void) overwriteDatabasePathWithName:(NSString *)name{
    NSURL * dbURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:name];
    self.sqliteFileURL = dbURL;
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
    
    if (self.sqliteFileURL == nil) {
        self.sqliteFileURL  = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AWARE.sqlite"];
    }
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.sqliteFileURL options:options error:&error]) {
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


- (bool) deleteLocalStorageWithName:(NSString*) fileName type:(NSString *)type{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * file = [NSString stringWithFormat:@"%@.%@",fileName, type];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:file];
    if ([manager fileExistsAtPath:path]) { // yes
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
        [fileHandle truncateFileAtOffset:0];
        [fileHandle synchronizeFile];
        [fileHandle closeFile];
        return YES;
    }
    return NO;
}


@end

