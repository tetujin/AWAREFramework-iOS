//
//  EntityDebug+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityDebug.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityDebug (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSString *event;
@property (nullable, nonatomic, retain) NSNumber *type;
@property (nullable, nonatomic, retain) NSString *label;
@property (nullable, nonatomic, retain) NSString *network;
@property (nullable, nonatomic, retain) NSString *device;
@property (nullable, nonatomic, retain) NSString *os;
@property (nullable, nonatomic, retain) NSString *app_version;
@property (nullable, nonatomic, retain) NSNumber *battery;
@property (nullable, nonatomic, retain) NSNumber *battery_state;

@end

NS_ASSUME_NONNULL_END
