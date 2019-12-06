//
//  AWAREAccelerometerIndexOM+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/12/05.
//
//

#import "AWAREAccelerometerIndexOM+CoreDataProperties.h"

@implementation AWAREAccelerometerIndexOM (CoreDataProperties)

+ (NSFetchRequest<AWAREAccelerometerIndexOM *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AWAREAccelerometerIndexOM"];
}

@dynamic count;
@dynamic date;
@dynamic synced;
@dynamic timestamp;
@dynamic data;

@end
