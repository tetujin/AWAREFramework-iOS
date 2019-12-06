//
//  AWAREAccelerometerOM+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/12/05.
//
//

#import "AWAREAccelerometerOM+CoreDataProperties.h"

@implementation AWAREAccelerometerOM (CoreDataProperties)

+ (NSFetchRequest<AWAREAccelerometerOM *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AWAREAccelerometerOM"];
}

@dynamic accuracy;
@dynamic device_id;
@dynamic double_values_0;
@dynamic double_values_1;
@dynamic double_values_2;
@dynamic label;
@dynamic timestamp;
@dynamic index;

@end
