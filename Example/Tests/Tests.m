//
//  AWAREFrameworkTests.m
//  AWAREFrameworkTests
//
//  Created by tetujin on 03/22/2018.
//  Copyright (c) 2018 tetujin. All rights reserved.
//

@import XCTest;
@import AWAREFramework;

@interface Tests : XCTestCase{
    int count;
    AWARECore * core;
    AWAREStudy * study;
    AWARESensorManager * sensorManager;
    ESMScheduleManager * esmManager;
}

@end

@implementation Tests

- (void)setUp
{
//    [sensorManager removeAllFilesFromDocumentRoot];
//    CoreDataHandler * dbHandler = [CoreDataHandler sharedHandler];
//    [dbHandler deleteLocalStorageWithName:@"AWARE" type:@"sqlite"];
    
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    core      = [AWARECore sharedCore];
    study      = [AWAREStudy sharedStudy];
    sensorManager = [AWARESensorManager sharedSensorManager];
    esmManager = [ESMScheduleManager sharedESMScheduleManager];
    [study setCleanOldDataType:cleanOldDataTypeAlways];

    
    [study setStudyURL:@"https://api.awareframework.com/index.php/webservice/index/1749/ITrUqPkbcSNM"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void) testAccelerometer {
    Accelerometer * sensor = [[Accelerometer alloc] init];
    BOOL startState = [sensor startSensor];
    XCTAssertTrue(startState);
    XCTAssertEqual(sensor.sensingInterval, MOTION_SENSOR_DEFAULT_SENSING_INTERVAL_SECOND);
    XCTAssertEqual(sensor.savingInterval,  MOTION_SENSOR_DEFAULT_DB_WRITE_INTERVAL_SECOND);
    BOOL stopState = [sensor stopSensor];
    XCTAssert(stopState);
    
    //// config test ////
    [sensor setSensingIntervalWithSecond:1];
    XCTAssertEqual(sensor.sensingInterval, 1);
    
    [sensor setSensingIntervalWithHz:10];
    XCTAssertEqual(sensor.sensingInterval, 1.0/10.0);
    
    [sensor setSavingIntervalWithMinute:1];
    XCTAssertEqual(sensor.savingInterval, 60);
    
    [sensor setSavingIntervalWithSecond:30];
    XCTAssertEqual(sensor.savingInterval, 30);
    
    
    /////////// Parameter Test ////////////////
    
    NSArray * settings = @[
                           @{@"setting":@"status_accelerometer",    @"value":@"true"},
                           @{@"setting":@"frequency_accelerometer", @"value":@200000},
                           @{@"setting":@"threshold_accelerometer", @"value":@1}
                           ];
    [sensor setParameters:settings];
    XCTAssertEqual(sensor.sensingInterval, 200000.0/1000000.0);
    XCTAssertEqual(sensor.threshold, 1);
    
    /// storage test: SQLite ///
    sensor = [[Accelerometer alloc] initWithDBType:AwareDBTypeSQLite];
    XCTAssertNotNil(sensor.storage);
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"SensingTestBlock"];
    [sensor setSensingIntervalWithHz:5];
    [sensor startSensor];
    count = 0;
    [sensor setSensorEventHandler:^(AWARESensor *sensor, NSDictionary *data) {
        count++;
        NSLog(@"%d",count);
    }];
    
    [NSTimer scheduledTimerWithTimeInterval:1 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [expectation fulfill];
        [sensor stopSensor];
        XCTAssertEqual(count, 5);
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"has error.");
    }];
    
    /// storage test:JSON ///
    sensor = [[Accelerometer alloc] initWithDBType:AwareDBTypeJSON];
    XCTAssertNotNil(sensor.storage);
    
    /// storage test:CSV ///
    sensor = [[Accelerometer alloc] initWithDBType:AwareDBTypeCSV];
    XCTAssertNotNil(sensor.storage);

    /// talbe test ////
    sensor = [[Accelerometer alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
    [sensor.storage setTableCreatecallBack:^(bool result, NSData *data, NSError *error) {
        NSLog(@"result: %d", result);
        XCTAssertNil(error);
        if(data!=nil){
            NSString * text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@",text);
        }
        XCTAssertTrue(result);
    }];
    [sensor createTable];
    
    ////// Sync /////
    sensor = [[Accelerometer alloc] initWithAwareStudy:study dbType:AwareDBTypeSQLite];
    // sensor.storage.saveInterval = 0;
    NSArray * dataset = [self getDataset];
    sensor.storage.saveInterval = 0;
    [sensor.storage setDebug:YES];
    [sensor.storage saveDataWithArray:dataset buffer:NO saveInMainThread:YES];
    XCTestExpectation *syncExpectation = [self expectationWithDescription:@"DBSyncTestBlock"];

    [NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [sensor.storage startSyncStorageWithCallBack:^(NSString *name, double progress, NSError * _Nullable error) {
            if (progress == 1) {
                [syncExpectation fulfill];
                XCTAssertEqual(progress, 1);
            }
            NSLog(@"[%@] %f", name, progress);
            if(error!=nil){
                NSLog(@"%@",error.debugDescription);
            }
            // XCTAssertNil(error);
        }];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        // XCTAssertNil(error, @"has error.");
    }];
    
    
    ///////// sub-thread test /////
    dataset = [self getDataset];
    sensor.storage.saveInterval = 0;
    [sensor.storage saveDataWithArray:dataset buffer:NO saveInMainThread:NO];
    XCTestExpectation *syncExpectation2 = [self expectationWithDescription:@"DBSyncTestBlock2"];

    [NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [sensor.storage startSyncStorageWithCallBack:^(NSString *name, double progress, NSError * _Nullable error) {
            if (progress == 1) {
                XCTAssertEqual(progress, 1);
                [syncExpectation2 fulfill];
            }
            NSLog(@"[%@] %f", name, progress);
            if(error!=nil){
                NSLog(@"%@",error.debugDescription);
            }
            // XCTAssertNil(error);
        }];
    }];

    [self waitForExpectationsWithTimeout:30 handler:^(NSError * _Nullable error) {
        // XCTAssertNil(error, @"has error.");
    }];
    
}

- (NSArray * ) getDataset {
    NSMutableArray * dataset = [[NSMutableArray alloc] init];
    for (int i=0; i<10000; i++) {
        [dataset addObject:@{
                             @"device_id":[study getDeviceId],
                             @"timestamp":[AWAREUtils getUnixTimestamp:[NSDate new]],
                             @"double_values_0":@0,
                             @"double_values_1":@0,
                             @"double_values_2":@0,
                             @"accuracy":@0,
                             @"label":@""
                             }];
    }
    return dataset;
}

@end

