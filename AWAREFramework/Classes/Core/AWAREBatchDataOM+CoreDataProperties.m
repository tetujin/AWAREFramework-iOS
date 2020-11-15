//
//  AWAREBatchDataOM+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2020/10/26.
//
//

#import "AWAREBatchDataOM+CoreDataProperties.h"

@implementation AWAREBatchDataOM (CoreDataProperties)

+ (NSFetchRequest<AWAREBatchDataOM *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"AWAREBatchDataOM"];
}

@dynamic batch_data;
@dynamic count;
@dynamic timestamp;

@end
