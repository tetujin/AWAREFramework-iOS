//
//  AWAREBarometerOM+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/12/10.
//
//

#import "AWAREBarometerOM+CoreDataProperties.h"

@implementation AWAREBarometerOM (CoreDataProperties)

+ (NSFetchRequest<AWAREBarometerOM *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AWAREBarometerOM"];
}

@dynamic device_id;
@dynamic double_values_0;
@dynamic label;
@dynamic timestamp;
@dynamic accuracy;

@end
