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

@property (strong, nonatomic, nullable) NSURL *sqliteFileURL;

@property (readonly, strong, nonatomic, nullable) NSManagedObjectContext * managedObjectContext;
@property (readonly, strong, nonatomic, nullable) NSManagedObjectModel   * managedObjectModel;
@property (readonly, strong, nonatomic, nullable) NSPersistentStoreCoordinator * persistentStoreCoordinator;

- (BOOL) migrateSQLite;
- (BOOL) backupSQLite;
- (void) sendMigrationRequestReminders;
- (void) stopMigrationRequestReminders;

- (void) saveContext;

- (bool) deleteLocalStorageWithName:(NSString* _Nonnull) fileName type:(NSString * _Nonnull)type;

- (void) overwriteManageObjectModelWithFileURL:(NSURL * _Nonnull)url;
- (void) overwriteDatabasePathWithFileURL:(NSURL * _Nonnull)url;

- (void) overwriteManageObjectModelWithName:(NSString * _Nonnull)name;
- (void) overwriteDatabasePathWithName:(NSString * _Nonnull)name;

@end

@interface BaseCoreDataHandler : NSObject <CoreDataHandlerDelegate>

- (instancetype _Nonnull )initWithDBName:(NSString * _Nullable)dbName;

@end
