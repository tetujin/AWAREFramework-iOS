//
//  Processor.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
// https://developer.apple.com/library/prerelease/ios/documentation/Cocoa/Reference/Foundation/Classes/NSProcessInfo_Class/index.html#//apple_ref/doc/constant_group/NSProcessInfo_Operating_Systems
//

#import "Processor.h"
#import "EntityProcessor.h"
#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/param.h>
#import <sys/mount.h>
#import <mach/mach.h>
#import <mach/processor_info.h>
#import <mach/mach_host.h>

NSString* const AWARE_PREFERENCES_STATUS_PROCESSOR = @"status_processor";
NSString* const AWARE_PREFERENCES_FREQUENCY_PROCESSOR = @"frequency_processor";

@implementation Processor{
    NSTimer * sensingTimer;
    double sensingInterval;
    int dbWriteInterval;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    AWAREStorage * storage = nil;
    if (dbType == AwareDBTypeJSON) {
        storage = [[JSONStorage alloc] initWithStudy:study sensorName:SENSOR_PROCESSOR];
    }else if(dbType == AwareDBTypeCSV){
        NSArray * header = @[@"timestamp",@"device_id",@"double_last_user",@"double_last_system",@"double_last_idle",@"double_user_load",@"double_system_load",@"double_idle"];
        NSArray * headerTypes  = @[@(CSVTypeReal),@(CSVTypeText),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal),@(CSVTypeReal)];
        storage = [[CSVStorage alloc] initWithStudy:study sensorName:SENSOR_PROCESSOR headerLabels:header headerTypes:headerTypes];
    }else{
        storage = [[SQLiteStorage alloc] initWithStudy:study sensorName:SENSOR_PROCESSOR entityName:NSStringFromClass([EntityProcessor class])
                                        insertCallBack:^(NSDictionary *data, NSManagedObjectContext *childContext, NSString *entity) {
                                            
                                            EntityProcessor* entityProcessor = (EntityProcessor *)[NSEntityDescription
                                                                                                   insertNewObjectForEntityForName:entity
                                                                                                   inManagedObjectContext:childContext];
                                            
                                            entityProcessor.device_id = [data objectForKey:@"device_id"];
                                            entityProcessor.timestamp = [data objectForKey:@"timestamp"];
                                            entityProcessor.double_last_user = [data objectForKey:@"double_last_user"];
                                            entityProcessor.double_last_system = [data objectForKey:@"double_last_system"];
                                            entityProcessor.double_last_idle = [data objectForKey:@"double_last_idle"];
                                            entityProcessor.double_user_load = [data objectForKey:@"double_user_load"];
                                            entityProcessor.double_system_load = [data objectForKey:@"double_system_load"];
                                            entityProcessor.double_idle_load = [data objectForKey:@"double_idle_load"];
                                        }];
    }
    
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PROCESSOR
                             storage:storage];
    if (self) {
        sensingInterval = 10.0f;
        dbWriteInterval = MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND;
    }
    return self;
}


- (void) createTable{
    if ([self isDebug]) {
        NSLog(@"[%@] Create Table", [self getSensorName]);
    }
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "double_last_user real default 0,"
    "double_last_system real default 0,"
    "double_last_idle real default 0,"
    "double_user_load real default 0,"
    "double_system_load real default 0,"
    "double_idle real default 0";
    // "UNIQUE (timestamp,device_id)";
    // [super createTable:query];
    [self.storage createDBTableOnServerWithQuery:query];
}

- (void)setParameters:(NSArray *)parameters{
    if (parameters != nil) {
        // Get a sensing frequency
        double frequency = [self getSensorSetting:parameters withKey:@"frequency_processor"];
        if (frequency != 0) {
            sensingInterval = [self convertMotionSensorFrequecyFromAndroid:frequency];
        }
    }
}

- (BOOL)startSensor{
    if ([self isDebug]) {
        NSLog(@"[%@] Start Processor Sensor", [self getSensorName]);
    }
    
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:sensingInterval
                                                    target:self
                                                  selector:@selector(saveCPUUsage:)
                                                  userInfo:nil
                                                   repeats:YES];
    return YES;
}

- (void) saveCPUUsage:(id)sender{
    // Get a CPU usage
    float cpuUsageFloat = [Processor getCpuUsage];
    NSNumber *appCpuUsage = [NSNumber numberWithFloat:cpuUsageFloat];
    NSNumber *idleCpuUsage = [NSNumber numberWithFloat:(100.0f-cpuUsageFloat)];

    // Save sensor data to the local database.
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:unixtime forKey:@"timestamp"];
    [dict setObject:[self getDeviceId] forKey:@"device_id"];
    [dict setObject:appCpuUsage forKey:@"double_last_user"]; //double
    [dict setObject:@0 forKey:@"double_last_system"]; //double
    [dict setObject:idleCpuUsage forKey:@"double_last_idle"]; //double
    [dict setObject:@0 forKey:@"double_user_load"];//double
    [dict setObject:@0 forKey:@"double_system_load"]; //double
    [dict setObject:@0 forKey:@"double_idle_load"]; //double
    [self setLatestValue:[NSString stringWithFormat:@"%@ %%",appCpuUsage]];
    [self.storage saveDataWithDictionary:dict buffer:NO saveInMainThread:NO];
    [self setLatestData:dict];
    
    SensorEventHandler handler = [self getSensorEventHandler];
    if (handler!=nil) {
        handler(self, dict);
    }
    
    malloc(cpuUsageFloat);
}

- (BOOL)stopSensor{
    [sensingTimer invalidate];
    return YES;
}



////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////



+ (float) getDeviceCpuUsage{
    
    float userTotalCpuUsage = 0;
    
    processor_info_array_t _cpuInfo, _prevCPUInfo = nil;
    mach_msg_type_number_t _numCPUInfo, _numPrevCPUInfo = 0;
    unsigned _numCPUs;
    NSLock *_cpuUsageLock;
    
    int _mib[2U] = { CTL_HW, HW_NCPU };
    size_t _sizeOfNumCPUs = sizeof(_numCPUs);
    int _status = sysctl(_mib, 2U, &_numCPUs, &_sizeOfNumCPUs, NULL, 0U);
    if(_status)
        _numCPUs = 1;
    
    _cpuUsageLock = [[NSLock alloc] init];
    
    natural_t _numCPUsU = 0U;
    kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &_numCPUsU, &_cpuInfo, &_numCPUInfo);
    if(err == KERN_SUCCESS) {
        [_cpuUsageLock lock];
        
        for(unsigned i = 0U; i < _numCPUs; ++i) {
            Float32 _inUse, _total;
            if(_prevCPUInfo) {
                _inUse = (
                          (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
                          + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
                          + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
                          );
                _total = _inUse + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
            } else {
                _inUse = _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
                _total = _inUse + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
            }
            
            NSLog(@"Core : %u, Usage: %.2f%%", i, _inUse / _total * 100.f);
            userTotalCpuUsage = userTotalCpuUsage + (_inUse / _total * 100.f); // TODO
        }
        userTotalCpuUsage = userTotalCpuUsage/_numCPUs; //TODO
        
        [_cpuUsageLock unlock];
        
        if(_prevCPUInfo) {
            size_t prevCpuInfoSize = sizeof(integer_t) * _numPrevCPUInfo;
            vm_deallocate(mach_task_self(), (vm_address_t)_prevCPUInfo, prevCpuInfoSize);
        }
        
        _prevCPUInfo = _cpuInfo;
        _numPrevCPUInfo = _numCPUInfo;
        
        _cpuInfo = nil;
        _numCPUInfo = 0U;
    } else {
        NSLog(@"Error!");
    }
    return userTotalCpuUsage;
}

+ (float) getCpuUsage{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
//    NSLog(@"%ld, %ld, %f", tot_sec, tot_usec, tot_cpu);
//    NSString* value = [NSString stringWithFormat:@""];
    
    return tot_cpu;
}

+ (long) getMemory {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    long memoryUsage = 0;
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"Memory in use (in bytes): %lu", info.resident_size);
        memoryUsage = info.resident_size;
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
    return memoryUsage;
}


@end
