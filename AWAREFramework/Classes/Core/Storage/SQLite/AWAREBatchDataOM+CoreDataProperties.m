//
//  AWAREBatchDataOM+CoreDataProperties.m
//  
//
//  Created by Yuuki Nishiyama on 2019/12/10.
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
