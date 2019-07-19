//
//  Tests.swift
//  Tests
//
//  Created by Yuuki Nishiyama on 2019/04/04.
//  Copyright © 2019 tetujin. All rights reserved.
//

import XCTest
import AWAREFramework

class Tests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // CoreDataHandler.shared().deleteLocalStorage(withName: "AWARE", type: "sqlite")
        
        AWARECore.shared()
        AWAREStudy.shared()
        AWARESensorManager.shared()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testJoinStudy(){
        let expectation = XCTestExpectation(description: "join study expectation")
        let url = "https://api.awareframework.com/index.php/webservice/index/2434/fRPjS3sVf5R4"
        AWAREStudy.shared().join(withURL: url) { (settings, status, error) in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }
    
    func testIOSESM(){
        let study = AWAREStudy.shared()
        let iOSESM = IOSESM(awareStudy: study)
        let expectation = XCTestExpectation(description: "iOS ESM")
        iOSESM.startSensor(withURL: "https://www.ht.sfc.keio.ac.jp/~tetujin/esm/test_4.json") {
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (notificationRequests) in
                for notification in notificationRequests {
                    print(notification.identifier)
                }
                if(notificationRequests.count == 6){
                    expectation.fulfill()
                }
            })
        }
        self.wait(for: [expectation], timeout: 10)
    }
    
    func testSetStudyURL(){
        // set url
        let url = "https://api.awareframework.com/index.php/webservice/index/2434/fRPjS3sVf5R4"
        let study = AWAREStudy.shared()
        study.setStudyURL(url)
        
        // init sensor
        let battery = Battery(awareStudy: study)
        battery.intervalSecond = 1
        battery.startSensor()
        
        // sensing
        let expectation = XCTestExpectation(description: "battery expectation")
        battery.setSensorEventHandler { (sensor, data) in
            if let d = data {
                print(d)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 10)
        
        // sync test
        let syncExpectation = XCTestExpectation(description: "battery sync expectation")
        battery.storage?.startSyncStorage(callBack: { (sensor, progress, error) in
            print(sensor,progress)
            if progress == 1 {
                syncExpectation.fulfill()
            }
        })
        wait(for: [syncExpectation], timeout: 10)
    }
    
    func testLimitedDataFetch(){
        
//        let acc = Accelerometer()
//
//        var array = Array<Dictionary<String,Any>>()
//        for i in 0...999 {
//            var dict = Dictionary<String,Any>()
//            dict.updateValue(AWAREUtils.getUnixTimestamp(Date().addingTimeInterval(TimeInterval(i))), forKey: "timestamp")
//            dict.updateValue(AWAREStudy.shared().getDeviceId(), forKey: "device_id")
//            dict.updateValue(0, forKey: "double_values_0")
//            dict.updateValue(1, forKey: "double_values_1")
//            dict.updateValue(2, forKey: "double_values_2")
//            dict.updateValue(3, forKey: "accuracy")
//            dict.updateValue("\(i)", forKey: "label")
//            array.append(dict)
//        }
//        print(array.count)
//        acc.storage?.saveData(with: array, buffer: false, saveInMainThread: true)
//        let expectation = XCTestExpectation(description: "test")
//        acc.storage?.fetchData(from: Date().addingTimeInterval(-1*60*60*24), to: Date().addingTimeInterval(1000), limit: 10, all: false, handler: { (name, data, from, to, isEnd, error) in
//            print(name, data!.count)
//            if(isEnd){
//                print("done")
//                DispatchQueue.main.async {
//                    expectation.fulfill()
//                }
//            }else{
//                print("continue")
//
//            }
//        })
//        wait(for: [expectation], timeout: 10)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
