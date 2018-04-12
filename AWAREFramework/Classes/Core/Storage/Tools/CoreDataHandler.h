//
//  CoreDataHandler.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/04/03.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum: NSInteger {
    AwareSQLiteStatusUnknown   = 0,
    AwareSQLiteStatusNormal    = 1,
    AwareSQLiteStatusNeedNigration = 2
} AwareSQLiteStatus;

@interface CoreDataHandler : NSObject


/**
 Migration related methods
 */
@property AwareSQLiteStatus status;

+ (CoreDataHandler * )sharedHandler;

- (BOOL) migrateSQLite;
- (BOOL) backupSQLite;
- (void)sendMigrationRequestReminders;
- (void)stopMigrationRequestReminders;

// CoreDate
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) NSURL *sqliteModelURL;
@property (strong, nonatomic) NSURL *sqliteFileURL;

- (void)saveContext;

@end
