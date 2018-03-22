//
//  EntityCall+CoreDataProperties.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 6/5/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "EntityCall.h"

NS_ASSUME_NONNULL_BEGIN

@interface EntityCall (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *timestamp;
@property (nullable, nonatomic, retain) NSString *device_id;
@property (nullable, nonatomic, retain) NSNumber *call_type;
@property (nullable, nonatomic, retain) NSNumber *call_duration;
@property (nullable, nonatomic, retain) NSString *trace;

@end

NS_ASSUME_NONNULL_END
