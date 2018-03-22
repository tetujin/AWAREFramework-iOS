//
//  EntityCalendar+CoreDataProperties.h
//  
//
//  Created by Yuuki Nishiyama on 2017/12/28.
//
//

#import "EntityCalendar+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface EntityCalendar (CoreDataProperties)

+ (NSFetchRequest<EntityCalendar *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *account_name;
@property (nullable, nonatomic, copy) NSString *begin;
@property (nullable, nonatomic, copy) NSString *calendar_description;
@property (nullable, nonatomic, copy) NSString *calendar_id;
@property (nullable, nonatomic, copy) NSString *calendar_name;
@property (nullable, nonatomic, copy) NSString *device_id;
@property (nullable, nonatomic, copy) NSString *end;
@property (nullable, nonatomic, copy) NSString *event_id;
@property (nullable, nonatomic, copy) NSString *location;
@property (nullable, nonatomic, copy) NSString *owner_account;
@property (nullable, nonatomic, copy) NSString *status;
@property (nullable, nonatomic, copy) NSNumber *timestamp;
@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, copy) NSNumber *all_day;
@property (nullable, nonatomic, copy) NSString *note;

@end

NS_ASSUME_NONNULL_END
