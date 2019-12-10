//
//  AWARERotationOM+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/12/10.
//
//

#import "AWARERotationOM+CoreDataProperties.h"

@implementation AWARERotationOM (CoreDataProperties)

+ (NSFetchRequest<AWARERotationOM *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AWARERotationOM"];
}

@dynamic accuracy;
@dynamic device_id;
@dynamic double_values_0;
@dynamic double_values_1;
@dynamic double_values_2;
@dynamic label;
@dynamic timestamp;
@dynamic double_values_3;

@end
