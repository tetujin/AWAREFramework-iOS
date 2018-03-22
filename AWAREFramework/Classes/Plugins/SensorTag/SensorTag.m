//
//  SensorTag.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 5/27/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "SensorTag.h"
#import "TCQMaker.h"

@implementation SensorTag{
    
    // Acc
    NSString *KEY_TAG_ACCX;
    NSString *KEY_TAG_ACCY;
    NSString *KEY_TAG_ACCZ;
    
    // Gyro
    NSString *KEY_TAG_GYROX;
    NSString *KEY_TAG_GYROY;
    NSString *KEY_TAG_GYROZ;
    
    // Mag
    NSString *KEY_TAG_MAGX;
    NSString *KEY_TAG_MAGY;
    NSString *KEY_TAG_MAGZ;
    
    // Humidity
    NSString *KEY_TAG_HUM;
    
    // Device Temp
    NSString *KEY_TAG_OBJ_TEMP;
    
    // Environmental Tamp
    NSString *KEY_TAG_AMB_TEMP;
    
    // Air-pressure
    NSString *KEY_TAG_BMP;
    
    // Light
    NSString *KEY_TAG_OPIICAL;
    
    
    bool eventState;
    NSString *UUID_KEY;
    NSString *UUID;
    int accRange;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"plugin_sensor_tag"
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
    if(self != nil){
        UUID_KEY = @"CC2650 SensorTag";
        UUID = @"";
        accRange = 0;
        eventState = true;
        accRange = ACC_RANGE_4G;
        // Do any additional setup after loading the view, typically from a nib.
        _myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}

- (void)createTable{
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    [tcqMaker addColumn:@"" type:TCQTypeReal default:@"'0'"];
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    // active sensors
    
    // interval
    
    
    return YES;
}

- (BOOL)stopSensor{
    return YES;
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManagerDidUpdateState");
    if([central state] == CBCentralManagerStatePoweredOff){
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }else if([central state] == CBCentralManagerStatePoweredOn){
        NSLog(@"CoreBluetooth BLE hardware is powered on");
        NSArray *services = @[[CBUUID UUIDWithString:SENSORTAG_SERVICE_UUID]];
        [central scanForPeripheralsWithServices:services options:nil];
    }else if([central state] == CBCentralManagerStateUnauthorized){
        NSLog(@"CoreBluetooth BLE hardware is unauthorized");
    }else if([central state] == CBCentralManagerStateUnknown){
        NSLog(@"CoreBluetooth BLE hardware is unknown");
    }else if([central state] == CBCentralManagerStateUnsupported){
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}




- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered %@", peripheral.name);
    NSLog(@"UUID %@", peripheral.identifier);
    NSLog(@"%@", peripheral);
    _peripheralDevice = peripheral;
    _peripheralDevice.delegate = self;
    [_myCentralManager connectPeripheral:_peripheralDevice options:nil];
    
}



- (void) centralManager:(CBCentralManager *) central
   didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral connected");
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}



- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        NSLog(@"Discoverd serive %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}




- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    int enable = ENABLE_SENSOR_CODE;
    int frequency = 0x0A;//0x64; //Set frequency between 10 to 1000
    NSData *enableData = [NSData dataWithBytes:&enable length: 1];
    NSData *frequencyData = [NSData dataWithBytes:&frequency length: 1];
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"Discovered characteristic %@", characteristic);
        //[_peripheralDevice readValueForCharacteristic:characteristic];
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_HUM_CONF]]){ // humidity
            [peripheral writeValue:enableData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            [peripheral setNotifyValue:YES forCharacteristic:[self getCharateristicWithUUID:UUID_HUM_DATA from:service]];
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_IRT_CONF]]){ // environmental temperature
            [peripheral writeValue:enableData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            [peripheral setNotifyValue:YES forCharacteristic:[self getCharateristicWithUUID:UUID_IRT_DATA from:service]];
        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_OPT_CONF]]){ // device temperature
            [peripheral writeValue:enableData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            [peripheral setNotifyValue:YES forCharacteristic:[self getCharateristicWithUUID:UUID_OPT_DATA from:service]];
        } else if ( [characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_BAR_CONF]]){ // air-pressure
            [peripheral writeValue:enableData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            [peripheral setNotifyValue:YES forCharacteristic:[self getCharateristicWithUUID:UUID_BAR_DATA from:service]];
        } else if ( [characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_MOV_CONF]]){ // motion sensor (acc, gyro, mag)
            // Send 16bit short(unsighed short) to motion sensor for booting
            // Set on/off to the 16bit variable
            // [Ref]
            // http://promamo.com/?p=999
            // http://www.objectivec-iphone.com/introduction/data-type/primitive.html
            // http://www.muryou-tools.com/sinsuu-change.php
            unsigned short e = 0;
            e |= FLAG_ACC_X | FLAG_ACC_Y | FLAG_ACC_Z | FLAG_GYRO_X | FLAG_GYRO_Y | FLAG_GYRO_Z | FLAG_MAG;
            switch (accRange) {
                case ACC_RANGE_2G:
                    break;
                case ACC_RANGE_4G:
                    e |= FLAG_ACC_RANGE_4G;
                    break;
                case ACC_RANGE_8G:
                    e |= FLAG_ACC_RANGE_8G;
                    break;
                case ACC_RANGE_16G:
                    e |= FLAG_ACC_RANGE_16G;
                    break;
                default:
                    break;
            }
            NSLog(@"%d",e);
            NSData *ed = [NSData dataWithBytes:&e length: sizeof(e)];
            [peripheral writeValue:ed forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            [peripheral writeValue:frequencyData forCharacteristic:[self getCharateristicWithUUID:UUID_MOV_PERI from:service] type:CBCharacteristicWriteWithResponse];
            [peripheral setNotifyValue:YES forCharacteristic:[self getCharateristicWithUUID:UUID_MOV_DATA from:service]];
        } else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ID_DATA]]){ // Beep Sound
            int nullBuzzer = 0x00;
            [peripheral writeValue:enableData forCharacteristic:[self getCharateristicWithUUID:UUID_ID_CONF from:service] type:CBCharacteristicWriteWithResponse];
            NSData *nullBuzzerData = [NSData dataWithBytes:&nullBuzzer length: 1];
            [NSThread sleepForTimeInterval:0.5f];
            [peripheral writeValue:nullBuzzerData forCharacteristic:[self getCharateristicWithUUID:UUID_ID_CONF from:service] type:CBCharacteristicWriteWithResponse];
        }
    }
}



- (CBCharacteristic *) getCharateristicWithUUID:(NSString *)uuid from:(CBService *) cbService
{
    for (CBCharacteristic *characteristic in cbService.characteristics) {
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:uuid]]){
            return characteristic;
        }
    }
    return nil;
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_MOV_DATA]]){
        [self getMotionData:characteristic.value];
    } else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_HUM_DATA]]){ // Humidity
        [self getHumidityData:characteristic.value];
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_IRT_DATA]]){ // Temp
        [self getTemperatureData:characteristic.value];
    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_OPT_DATA]]){ // Optical Sensor
        [self getOpticalData:characteristic.value];
    } else if ( [characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_BAR_DATA]]){ // Barometric Pressure Sensor
        [self getBmpData:characteristic.value];
    }
}


// Get temp data
- (void) getTemperatureData:(NSData *)data{
    const Byte *orgBytes = [data bytes];
    uint16_t obj = (orgBytes[1] << 8) +orgBytes[0];
    uint16_t ambience = (orgBytes[3] << 8) + orgBytes[2];
    //    NSLog(@"Obj:%f, Amboence:%f,", sensorTmp007ObjConvert(obj), sensorTmp007AmbConvert(ambience));
    _tagObjTemp = [[NSNumber alloc] initWithFloat:sensorTmp007ObjConvert(obj)];
    _tagAmbTemp = [[NSNumber alloc] initWithFloat:sensorTmp007AmbConvert(ambience)];
    
//    [_objTempLabel setText:[_tagObjTemp stringValue]];
//    [_ambTempLabel setText:[_tagAmbTemp stringValue]];
}


// Get light data
- (void) getOpticalData:(NSData *)data {
    const Byte *orgBytes = [data bytes];
    uint16_t rawData = (orgBytes[3] << 24) + (orgBytes[2] << 16) + (orgBytes[1] << 8) +orgBytes[0];
    //    NSLog(@"%f", sensorOpt3001Convert(rawData ));
    _tagOptical = [[NSNumber alloc] initWithFloat:sensorOpt3001Convert(rawData)];
//    [_opticalLabel setText:[_tagOptical stringValue]];
}

// Get ait-pressure data
- (void) getBmpData:(NSData *)data{
    const Byte *orgBytes = [data bytes];
    int32_t press = (orgBytes[5] << 16) + (orgBytes[4] << 8) +orgBytes[3];
    //    NSLog(@"%f", calcBmp280(press));
    //    int16_t press = (orgBytes[3] << 8) + orgBytes[2];
    _tagBmp = [[NSNumber alloc] initWithFloat:calcBmp280(press)];
//    [_bmpLabel setText:[_tagBmp stringValue]];
}


// Get humidity data
- (void) getHumidityData:(NSData *)data{
    const Byte *orgBytes = [data bytes];
    //    int16_t temp =(orgBytes[1] << 8) + orgBytes[0];
    int16_t hum = (orgBytes[3] << 8) + orgBytes[2];
    //    sensorHdc1000Convert(temp, hum, tempFloat, humFloat);
    //    NSLog(@"%f C, %f  RH", sensorHdc1000TempConvert(temp), sensorHdc1000HumConvert(hum));
    _tagHum = [[NSNumber alloc] initWithFloat:sensorHdc1000HumConvert(hum)];
//    [_humLabel setText:[_tagHum stringValue]];
}

// Get motion sensor data (Acc, Gryo, Mag)
- (void) getMotionData:(NSData *) data
{
    // http://processors.wiki.ti.com/index.php/CC2650_SensorTag_User's_Guide#Movement_Sensor
    const Byte *orgBytes = [data bytes];
    int16_t gyroX = (orgBytes[1] << 8) + orgBytes[0];
    int16_t gyroY = (orgBytes[3] << 8) + orgBytes[2];
    int16_t gyroZ = (orgBytes[5] << 8) + orgBytes[4];
    int16_t accX  = (orgBytes[7] << 8) + orgBytes[6];
    int16_t accY  = (orgBytes[9] << 8) + orgBytes[8];
    int16_t accZ  = (orgBytes[11] << 8) + orgBytes[10];
    int16_t magX  = (orgBytes[13] << 8) + orgBytes[12];
    int16_t magY  = (orgBytes[15] << 8) + orgBytes[14];
    int16_t magZ  = (orgBytes[17] << 8) + orgBytes[16];
    
    NSLog(@"%f %f %f", sensorMpu9250GyroConvert(gyroX),sensorMpu9250GyroConvert(gyroY),sensorMpu9250GyroConvert(gyroZ));
    //    NSLog(@"%f %f %f", sensorMpu9250AccConvert(accX, accRange),sensorMpu9250AccConvert(accY, accRange),sensorMpu9250AccConvert(accZ, accRange));
    //    NSLog(@"%f %f %f", sensorMpu9250MagConvert(magX),sensorMpu9250MagConvert(magY),sensorMpu9250MagConvert(magZ));
    _tagGyroX = [[NSNumber alloc] initWithFloat:sensorMpu9250GyroConvert(gyroX)];
    _tagGyroY = [[NSNumber alloc] initWithFloat:sensorMpu9250GyroConvert(gyroY)];
    _tagGyroZ = [[NSNumber alloc] initWithFloat:sensorMpu9250GyroConvert(gyroZ)];
    
    _tagAccX = [[NSNumber alloc] initWithFloat:sensorMpu9250AccConvert(accX, accRange)];
    _tagAccY = [[NSNumber alloc] initWithFloat:sensorMpu9250AccConvert(accY, accRange)];
    _tagAccZ = [[NSNumber alloc] initWithFloat:sensorMpu9250AccConvert(accZ, accRange)];
    
    _tagMagX = [[NSNumber alloc] initWithFloat:sensorMpu9250MagConvert(magX)];
    _tagMagY = [[NSNumber alloc] initWithFloat:sensorMpu9250MagConvert(magY)];
    _tagMagZ = [[NSNumber alloc] initWithFloat:sensorMpu9250MagConvert(magZ)];
    
    // -- Label --
//    [_gyroxLabel setText:[_tagGyroX stringValue]];
//    [_gyroyLabel setText:[_tagGyroY stringValue]];
//    [_gyrozLabel setText:[_tagGyroZ stringValue]];
//    
//    [_accxLabel setText:[_tagAccX stringValue]];
//    [_accyLabel setText:[_tagAccY stringValue]];
//    [_acczLabel setText:[_tagAccZ stringValue]];
//    
//    [_magxLabel setText:[_tagMagX stringValue]];
//    [_magyLabel setText:[_tagMagY stringValue]];
//    [_magzLabel setText:[_tagMagZ stringValue]];
    
}


float sensorTmp007ObjConvert(uint16_t rawObjTemp)
{
    const float SCALE_LSB = 0.03125;
    float t;
    int it;
    
    it = (int)((rawObjTemp) >> 2);
    t = ((float)(it)) * SCALE_LSB;
    return t;
}

float sensorTmp007AmbConvert(uint16_t rawAmbTemp)
{
    const float SCALE_LSB = 0.03125;
    float t;
    int it;
    
    it = (int)((rawAmbTemp) >> 2);
    t = (float)it;
    return t * SCALE_LSB;
}


float sensorOpt3001Convert(uint16_t rawData)
{
    uint16_t e, m;
    
    m = rawData & 0x0FFF;
    e = (rawData & 0xF000) >> 12;
    
    return m * (0.01 * pow(2.0,e));
}

float calcBmp280(uint32_t rawValue)
{
    return rawValue / 100.0f;
}

float sensorHdc1000HumConvert(uint16_t rawHum)
{
    //-- calculate relative humidity [%RH]
    return ((double)rawHum / 65536)*100;
}

float sensorHdc1000TempConvert(uint16_t rawTemp)
{
    //-- calculate temperature [°C]
    return ((double)(int16_t)rawTemp / 65536)*165 - 40;
}



float sensorMpu9250GyroConvert(int16_t data)
{
    //-- calculate rotation, unit deg/s, range -250, +250
    return (data * 1.0) / (65536 / 500);
}

float sensorMpu9250AccConvert(int16_t rawData, int accRange)
{
    float v = 0.0;
    
    switch (accRange){
        case ACC_RANGE_2G:
            //-- calculate acceleration, unit G, range -2, +2
            v = (rawData * 1.0) / (32768/2);
            break;
            
        case ACC_RANGE_4G:
            //-- calculate acceleration, unit G, range -4, +4
            v = (rawData * 1.0) / (32768/4);
            break;
            
        case ACC_RANGE_8G:
            //-- calculate acceleration, unit G, range -8, +8
            v = (rawData * 1.0) / (32768/8);
            break;
            
        case ACC_RANGE_16G:
            //-- calculate acceleration, unit G, range -16, +16
            v = (rawData * 1.0) / (32768/16);
            break;
    }
    
    return v;
}


float sensorMpu9250MagConvert(int16_t data)
{
    //-- calculate magnetism, unit uT, range +-4900
    return 1.0 * data;
}


@end
