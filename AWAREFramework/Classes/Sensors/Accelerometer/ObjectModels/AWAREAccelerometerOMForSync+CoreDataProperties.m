//
//  AWAREAccelerometerOMForSync+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/12/06.
//
//

#import "AWAREAccelerometerOMForSync+CoreDataProperties.h"

@implementation AWAREAccelerometerOMForSync (CoreDataProperties)

+ (NSFetchRequest<AWAREAccelerometerOMForSync *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AWAREAccelerometerOMForSync"];
}

@dynamic count;
@dynamic timestamp;
@dynamic batch_data;
@dynamic date;

@end
