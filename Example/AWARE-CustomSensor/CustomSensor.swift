//
//  CustomSensor.swift
//  AWARE-CustomSensor
//
//  Created by Yuuki Nishiyama on 2019/04/03.
//  Copyright © 2019 tetujin. All rights reserved.
//

import UIKit
import AWAREFramework

class CustomSensor: AWARESensor {
    
    public static let sensorName = "CustomSensor"
    var timer:Timer? = nil
    
    
    override convenience init(){
        let study = AWAREStudy.shared()
        let storage = SQLiteStorage.init(study: study,
                                     sensorName: CustomSensor.sensorName,
                                     entityName: "EntityCustomSensor",
                                     dbHandler:  ExternalCoreDataHandler.shared())
        self.init(awareStudy: study, sensorName: CustomSensor.sensorName, storage: storage!)
    }
    
    override convenience init(dbType:AwareDBType) {
        var storage:AWAREStorage? = nil
        let study = AWAREStudy.shared()
        
        if dbType == AwareDBTypeJSON{
            storage = JSONStorage.init(study: study,
                                       sensorName: CustomSensor.sensorName)
        }else if dbType == AwareDBTypeCSV{
            let headers = ["device_id","timestamp","str_value","int_value","real_value","label"]
            let types:Array<NSNumber> = [NSNumber(value: CSVTypeText.rawValue),
                                         NSNumber(value: CSVTypeReal.rawValue),
                                         NSNumber(value: CSVTypeText.rawValue),
                                         NSNumber(value: CSVTypeInteger.rawValue),
                                         NSNumber(value: CSVTypeReal.rawValue),
                                         NSNumber(value: CSVTypeText.rawValue)]
            storage = CSVStorage.init(study: study,
                                      sensorName: CustomSensor.sensorName,
                                      headerLabels: headers,
                                      headerTypes: types)
        }else{
            storage = SQLiteStorage.init(study: study,
                                         sensorName: CustomSensor.sensorName,
                                         entityName: "EntityCustomSensor",
                                         dbHandler:  ExternalCoreDataHandler.shared())
        }
        self.init(awareStudy: study, sensorName: CustomSensor.sensorName, storage: storage!)
    }

    override func createTable() {
        let maker = TCQMaker()
        maker.addColumn("label",     type: TCQTypeText,    default: "''")
        maker.addColumn("str_value",  type: TCQTypeText,    default: "''")
        maker.addColumn("int_value",  type: TCQTypeInteger, default: "0")
        maker.addColumn("real_value", type: TCQTypeReal,    default: "0")
        self.storage?.createDBTableOnServer(with: maker)
    }
    
    override func startSensor() -> Bool {
        if stopSensor() {
            timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { (timer) in
                
                let now = Date().timeIntervalSince1970
                
                var dict = Dictionary<String,Any>()
                dict["label"]      = "hello"
                dict["str_value"]  = "\(now)"
                dict["int_value"]  = Int(now)
                dict["real_value"] = Double(now)
                dict["timestamp"]  = now * 1000.0
                dict["device_id"]  = AWAREStudy.shared().getDeviceId()
                
                self.storage?.saveData(with: dict, buffer: false, saveInMainThread: true)
                
                if let handler = self.getEventHandler(){
                    handler(self, dict)
                }
            })
        }
        return true
    }
    
    override func stopSensor() -> Bool {
        if let t = timer {
            t.invalidate()
            self.timer = nil
        }
        return true
    }
}
