//
//  Memory.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/23/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "Memory.h"
#import "EntityMemory.h"

#import <mach/mach.h>
#import <mach/mach_host.h>

@implementation Memory {
    NSTimer * sensingTimer;
    NSString * KEY_MEMORY_TIMESTAMP;
    NSString * KEY_MEMORY_DEVICE_ID;
    NSString * KEY_MEMORY_USED;
    NSString * KEY_MEMORY_FREE;
    NSString * KEY_MEMORY_TOTAL;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    
    KEY_MEMORY_TIMESTAMP = @"timestamp";
    KEY_MEMORY_DEVICE_ID = @"device_id";
    KEY_MEMORY_USED = @"mem_used";
    KEY_MEMORY_FREE = @"mem_free";
    KEY_MEMORY_TOTAL = @"mem_total";
    
    AWAREStorage * storage = nil;
    
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:@"memory"];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[KEY_MEMORY_TIMESTAMP, KEY_MEMORY_DEVICE_ID, KEY_MEMORY_USED, KEY_MEMORY_FREE, KEY_MEMORY_TOTAL];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:@"memory" headerLabels:header headerTypes:headerTypes];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:@"memory" entityName:NSStringFromClass([EntityMemory class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            EntityMemory * memoryEntity = (EntityMemory *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                                                                inManagedObjectContext:childContext];
                                            memoryEntity.device_id = [data objectForKey:@"device_id"];
                                            memoryEntity.timestamp = [data objectForKey:@"timestamp"];
                                            memoryEntity.mem_used  = [data objectForKey:@"mem_used"];
                                            memoryEntity.mem_free  = [data objectForKey:@"mem_free"];
                                            memoryEntity.mem_total = [data objectForKey:@"mem_total"];
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:@"memory"
                             storage:storage];
    if (self) {
        _intervalSec = 60*5;
    }
    return self;
}

- (void) createTable{
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_MEMORY_TIMESTAMP]];
    [query appendString:[NSString stringWithFormat:@"%@ text default '',", KEY_MEMORY_DEVICE_ID]];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,",KEY_MEMORY_USED]];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_MEMORY_FREE]];
    [query appendString:[NSString stringWithFormat:@"%@ real default 0,", KEY_MEMORY_TOTAL]];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{

}

- (BOOL)startSensor{
    return [self startSensorWithInterval:_intervalSec];
}

- (BOOL) startSensorWithInterval:(double)interval{
    // start sensor
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                    target:self
                                                  selector:@selector(saveMemoryUsage)
                                                  userInfo:nil
                                                   repeats:YES];
    [self setSensingState:YES];
    return YES;
}

- (BOOL)stopSensor{
    if (sensingTimer != nil) {
        [sensingTimer invalidate];
        sensingTimer = nil;
    }
    if (self.storage != nil) {
        [self.storage saveBufferDataInMainThread:YES];
    }
    [self setSensingState:NO];
    return YES;
}


- (void) saveMemoryUsage {
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    
    vm_statistics_data_t vm_stat;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
    }
    
    /* Stats in bytes */
//    natural_t
    double mem_used = (vm_stat.active_count +
                          vm_stat.inactive_count +
                          vm_stat.wire_count) * pagesize;
    double mem_free = vm_stat.free_count * pagesize *10;
    mem_used =  mem_used/1000/1000/1000;
    mem_free =  mem_free/1000/1000/1000;
    double mem_total = mem_used + mem_free;
    
    if ([self isDebug]) {
        NSLog(@"used: %f free: %f total: %f", mem_used, mem_free, mem_total);
    }
    
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    [query setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_MEMORY_TIMESTAMP];
    [query setObject:[self getDeviceId] forKey:KEY_MEMORY_DEVICE_ID];
    [query setObject:[NSNumber numberWithDouble:mem_used] forKey:KEY_MEMORY_USED];
    [query setObject:[NSNumber numberWithDouble:mem_free] forKey:KEY_MEMORY_FREE];
    [query setObject:[NSNumber numberWithDouble:mem_total] forKey:KEY_MEMORY_TOTAL];
    [self.storage saveDataWithDictionary:query buffer:NO saveInMainThread:YES];

    if ([self isDebug]) {
        // [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"used: %f free: %f total: %f", mem_used, mem_free, mem_total] soundFlag:NO];
    }
    
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, query);
    }
 
}

@end
