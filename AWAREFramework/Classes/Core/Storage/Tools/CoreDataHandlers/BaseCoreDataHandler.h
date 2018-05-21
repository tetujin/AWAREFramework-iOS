//
//  BaseCoreDataHandler.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/05/21.
//

#import <Foundation/Foundation.h>

typedef enum: NSInteger {
    AwareSQLiteStatusUnknown   = 0,
    AwareSQLiteStatusNormal    = 1,
    AwareSQLiteStatusNeedNigration = 2
} AwareSQLiteStatus;

///////////////////////////////////////////
/// CoreData Handler Delegate
@protocol CoreDataHandlerDelegate <NSObject>

@property AwareSQLiteStatus status;

@property (strong, nonatomic) NSURL *sqliteFileURL;

@property (readonly, strong, nonatomic) NSManagedObjectContext * managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel   * managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator * persistentStoreCoordinator;

- (BOOL) migrateSQLite;
- (BOOL) backupSQLite;
- (void) sendMigrationRequestReminders;
- (void) stopMigrationRequestReminders;

- (void) saveContext;

- (bool) deleteLocalStorageWithName:(NSString*) fileName type:(NSString *)type;

- (void) overwriteManageObjectModelWithFileURL:(NSURL *)url;
- (void) overwriteDatabasePathWithFileURL:(NSURL *)url;

- (void) overwriteManageObjectModelWithName:(NSString *)name;
- (void) overwriteDatabasePathWithName:(NSString *)name;

@end

@interface BaseCoreDataHandler : NSObject <CoreDataHandlerDelegate>

@end
