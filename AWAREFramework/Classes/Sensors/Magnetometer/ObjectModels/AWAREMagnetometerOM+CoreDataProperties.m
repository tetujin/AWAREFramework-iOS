//
//  AWAREMagnetometerOM+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/12/10.
//
//

#import "AWAREMagnetometerOM+CoreDataProperties.h"

@implementation AWAREMagnetometerOM (CoreDataProperties)

+ (NSFetchRequest<AWAREMagnetometerOM *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AWAREMagnetometerOM"];
}

@dynamic accuracy;
@dynamic device_id;
@dynamic double_values_0;
@dynamic double_values_1;
@dynamic double_values_2;
@dynamic label;
@dynamic timestamp;

@end
