//
//  AWAREGravityOM+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/12/10.
//
//

#import "AWAREGravityOM+CoreDataProperties.h"

@implementation AWAREGravityOM (CoreDataProperties)

+ (NSFetchRequest<AWAREGravityOM *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AWAREGravityOM"];
}

@dynamic accuracy;
@dynamic device_id;
@dynamic double_values_0;
@dynamic double_values_1;
@dynamic double_values_2;
@dynamic label;
@dynamic timestamp;

@end
