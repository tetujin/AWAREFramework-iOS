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
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    AWAREDelegate * delegate = (AWAREDelegate *)[UIApplication sharedApplication].delegate;
    core = delegate.sharedAWARECore;
    study = core.sharedAwareStudy;
    sensorManager = core.sharedSensorManager;
    esmManager = core.sharedESMManager;
    
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
                           @{@"setting":@"status_accelerometer", @"value":@"true"},
                           @{@"setting":@"frequency_accelerometer", @"value":@200000},
                           @{@"setting":@"threshold_accelerometer",@"value":@1}
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
    double now = [NSDate new].timeIntervalSince1970;
    NSMutableArray * dataset = [[NSMutableArray alloc] init];
    for (int i=0; i<100; i++) {
        [dataset addObject:@{
                             @"device_id":[study getDeviceId],
                             @"timestamp":@(now+i),
                             @"double_values_0":@0,
                             @"double_values_1":@0,
                             @"double_values_2":@0,
                             @"accuracy":@0,
                             @"label":@""
                             }];
    }
    sensor.storage.saveInterval = 0;
    [sensor.storage saveDataWithArray:dataset buffer:NO saveInMainThread:YES];
    XCTestExpectation *syncExpectation = [self expectationWithDescription:@"DBSyncTestBlock"];
    
    [NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer * _Nonnull timer) {
        [sensor.storage startSyncStorageWithCallBack:^(NSString *name, double progress, NSError * _Nullable error) {
            [syncExpectation fulfill];
            if(error!=nil){
                NSLog(@"%@",error.debugDescription);
            }
            XCTAssertNil(error);
            XCTAssertEqual(progress, 1);
        }];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"has error.");
    }];
    
}

@end

