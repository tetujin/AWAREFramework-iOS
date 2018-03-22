//
//  Contacts.m
//  AWARE
//
//  Created by Paul McCartney on 2016/12/12.
//  Copyright © 2016年 Yuuki NISHIYAMA. All rights reserved.
//

#import "Contacts.h"
#import "AWAREKeys.h"
#import "EntityContact+CoreDataClass.h"

@import Contacts;

NSString * const KEY_PLUGIN_SETTING_CONTACTS_LAST_UPDATE_NSDATE = @"key_plugin_setting_contanct_last_update_date";
NSString * const KEY_PLUGIN_SETTING_CONTACTS_NEXT_UPDATE_DATE = @"key_plugin_setting_contact_next_update_date";
NSString * const KEY_PLUGIN_SETTING_CONTACTS_UPDATE_FREQUENCY_DAY = @"key_plugin_setting_contact_update_frequency_day";

@implementation Contacts{
    NSTimer * timer;
    int aDaySec;
    int checkIntervalSec;
}

- (instancetype) initWithAwareStudy:(AWAREStudy *)study
                             dbType:(AwareDBType)dbType {
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_PLUGIN_CONTACTS
                        dbEntityName:NSStringFromClass([EntityContact class])
                              dbType:AwareDBTypeCoreData];
    if (self) {
        aDaySec = 60*60*24;       // 24 hours
        checkIntervalSec = 60*15; // check a next update every 15 min
        
        NSDate * lastUpdate = [self getLastUpdateDate];
        if(lastUpdate != nil){
            NSString * message= [NSString stringWithFormat:@"Last Update:\n%@",
                                 lastUpdate.debugDescription];
            [self setLatestValue:message];
        }
    }
    return self;
}

/** send create table query */
- (void) createTable {
    
    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
    
    [tcqMaker addColumn:@"name"          type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:@"phone_numbers" type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:@"emails"        type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:@"groups"        type:TCQTypeText default:@"''"];
    [tcqMaker addColumn:@"sync_date"     type:TCQTypeReal default:@"0"];
    
    [super createTable:[tcqMaker getDefaudltTableCreateQuery]];
}

/** start sensor */
- (BOOL)startSensorWithSettings:(NSArray *)settings{

    double frequencyDays = [self getSensorSetting:settings withKey:@"frequency_plugin_contacts"]; // days
    NSLog(@"Update Frequency Date: %f", frequencyDays);
    if( frequencyDays > 0 ){
        [self setUpdateFreqnecyDay:@((int)frequencyDays)];
    } else {
        [self setUpdateFreqnecyDay:@30];
    }
    
    // This timer check the necessity of updating contact list by each 1 hour
    timer = [NSTimer scheduledTimerWithTimeInterval:checkIntervalSec
                                             target:self
                                           selector:@selector(updateContacts)
                                           userInfo:nil
                                            repeats:YES];
    [timer fire];
    
    // check a status of CNAuthorizationStatus
    [self checkStatus];
    
    // This is an initialization. This process should be called just one time when the plugin is activated.
    NSDate * nextUpdate = [self getNextUpdateDate];
    if (nextUpdate == nil) {
        // [self setNextUpdateDateWithDate:[[NSDate alloc] initWithTimeIntervalSinceNow:frequencyDays*aDaySec]];
        NSDate * targetDate = [AWAREUtils getTargetNSDate:[[NSDate alloc] initWithTimeIntervalSinceNow:frequencyDays*aDaySec]
                                                     hour:12
                                                  nextDay:NO];
        NSLog(@"%@",targetDate.debugDescription);
        [self setNextUpdateDateWithDate:targetDate];
    }
    return YES;
}

/** step senspr */
- (BOOL)stopSensor{
    if(timer != nil){
        [timer invalidate];
        timer = nil;
    }
    return YES;
}

-(void)checkStatus{
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    switch (status) {
        case CNAuthorizationStatusNotDetermined:
        case CNAuthorizationStatusRestricted:
        {
            CNContactStore *store = [CNContactStore new];
            [store requestAccessForEntityType:CNEntityTypeContacts
                            completionHandler:^(BOOL granted, NSError * _Nullable error) {
                                if (granted) {
                                    // Available
                                    [self getContacts];
                                } else {
                                    // Reject
                                }
                            }];
        }
            break;
            
        case CNAuthorizationStatusDenied:
            // Reject
            break;
            
        case CNAuthorizationStatusAuthorized:
            // Available
            // [self getContacts];
            break;
            
        default:
            break;
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) updateContacts {
    NSDate * nextUpateDate = [self getNextUpdateDate];
    NSDate * now = [NSDate new];
    if (nextUpateDate != nil) {
        if (nextUpateDate.timeIntervalSince1970 < now.timeIntervalSince1970) {
            [self getContacts];
            NSNumber * frequencyDays = [self getUpdateFrequencyDay];
            if(frequencyDays != nil){
                ////////////////// MAIN ////////////////
                // [self setNextUpdateDateWithDate:[[NSDate alloc] initWithTimeIntervalSinceNow:frequencyDays.intValue*aDaySec]];
                NSNumber * updateFrequencyDate = [self getUpdateFrequencyDay];
                int frequency = frequencyDays.intValue;
                if (updateFrequencyDate != nil) {
                    frequency = updateFrequencyDate.intValue;
                }
                NSDate * targetDate = [AWAREUtils getTargetNSDate:[[NSDate alloc] initWithTimeIntervalSinceNow:frequency * aDaySec]
                                                             hour:12
                                                          nextDay:NO];
                NSLog(@"%@",targetDate.debugDescription);
                [self setNextUpdateDateWithDate:targetDate];
                ////////////////// TEST ////////////////
                // [self setNextUpdateDateWithDate:[[NSDate alloc] initWithTimeIntervalSinceNow:frequencyDays.intValue*60]];
                if ([self isDebug]) [AWAREUtils sendLocalNotificationForMessage:@"contact update" soundFlag:YES];
                ////////////////////////////////////////
            }
        }
    }
}

- (void) getContacts {
    CNContactStore *store = [CNContactStore new];
    NSError *error;
    CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactGivenNameKey,
                                                                                          CNContactMiddleNameKey,
                                                                                          CNContactFamilyNameKey,
                                                                                          CNContactPhoneNumbersKey,
                                                                                          CNContactEmailAddressesKey]];
    NSMutableArray *people = @[].mutableCopy;
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    BOOL success = [store enumerateContactsWithFetchRequest:request error:&error
                                                 usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
                                                     [people addObject:contact];
                                                 }];
    
    if (success) {
        [self setBufferSize:(int)people.count-1];
        for (CNContact * contact in people) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
            NSString *name = [NSString stringWithFormat:@"%@ %@", contact.givenName ,contact.familyName];
            //////////////////// timestamp //////////////////
            [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:@"timestamp"];
            //////////////////// device_id //////////////////
            [dict setObject:[self getDeviceId] forKey:@"device_id"];
            //////////////////// name //////////////////
            [dict setObject:name forKey:@"name"];
            //////////////////// phone_numbers //////////////////
            NSMutableArray * phoneNumbers = [[NSMutableArray alloc] init];
            if (contact.phoneNumbers.count != 0){
                for (CNLabeledValue *label in contact.phoneNumbers) {
                    NSMutableDictionary * phoneRow = [[NSMutableDictionary alloc] init];
                    CNPhoneNumber *phoneNumber = label.value;
                    // Phone number labels
                    NSString * s = phoneNumber.stringValue;
                    if (s != nil) {
                        [phoneRow setObject:s forKey:@"number"];
                        [phoneNumbers addObject:phoneRow];
                    }
                }
                
                [dict setObject:[self jsonStringWithArray:phoneNumbers prettyPrint:NO] forKey:@"phone_numbers"];
            }else{
                [dict setObject:@"[]" forKey:@"phone_numbers"];
            }
            //////////////////// emails //////////////////
            NSMutableArray * emails = [[NSMutableArray alloc] init];
            if (contact.emailAddresses.count != 0){
                NSMutableDictionary * emailRow = [[NSMutableDictionary alloc] init];
                for (CNLabeledValue * label in contact.emailAddresses) {
                    NSString * email = label.value;
                    if(email != nil){
                        [emailRow setObject:email forKey:@"email"];
                        [emails addObject:emailRow];
                    }
                }
                // NSLog(@"%@", emailRow.description);
                [dict setObject:[self jsonStringWithArray:emails prettyPrint:NO] forKey:@"emails"];
            }else{
                [dict setObject:@"[]" forKey:@"emails"];
            }
            ////////////////////// groups //////////////////
            [dict setObject:@"[]" forKey:@"groups"];
            //////////////////// sync_date //////////////////
            [dict setObject:unixtime forKey:@"sync_date"];
            
            [self saveData:dict];
        }
        
        // [self setBufferSize:0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if([AWAREUtils isForeground]){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                message:[NSString stringWithFormat:@"Saved %ld contacts", people.count]
                                                               delegate:nil
                                                      cancelButtonTitle:@"Close"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            NSDate * now = [NSDate new];
            [self setLastUpdateDateWithDate:now];
            
            NSString * message= [NSString stringWithFormat:@"Last Update:\n%@",now.debugDescription];
            [self setLatestValue:message];
        
            // [self performSelector:@selector(syncAwareDBInBackground) withObject:nil afterDelay:5];
        });
        
    } else {
        NSLog(@"%s %@",__func__, error);
    }
}


//////////////////////////////////////////////////////////////////

- (NSDate *) getLastUpdateDate{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate * date = [userDefaults objectForKey:KEY_PLUGIN_SETTING_CONTACTS_LAST_UPDATE_NSDATE];
    if(date != nil){
        return date;
    }else{
        return nil;
    }
}

- (void) setLastUpdateDateWithDate:(NSDate *)date{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:date forKey:KEY_PLUGIN_SETTING_CONTACTS_LAST_UPDATE_NSDATE];
    [userDefaults synchronize];
}

////////////////////////////////////////////////////////////

- (NSDate *) getNextUpdateDate {
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate * date = [userDefaults objectForKey:KEY_PLUGIN_SETTING_CONTACTS_NEXT_UPDATE_DATE];
    return date;
}

- (void) setNextUpdateDateWithDate:(NSDate *)date{
    NSLog(@"Next Update: %@", date);
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:date forKey:KEY_PLUGIN_SETTING_CONTACTS_NEXT_UPDATE_DATE];
    [userDefaults synchronize];
}

///////////////////////////////////////////////////////////////////

- (NSNumber *) getUpdateFrequencyDay{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber * day = [userDefaults objectForKey:KEY_PLUGIN_SETTING_CONTACTS_UPDATE_FREQUENCY_DAY];
    if(day != nil){
        return day;
    }else{
        return nil;
    }
}

- (void) setUpdateFreqnecyDay:(NSNumber *)day{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    
    if(day!=nil){
        [userDefaults setObject:day forKey:KEY_PLUGIN_SETTING_CONTACTS_UPDATE_FREQUENCY_DAY];
    }else{
        [userDefaults removeObjectForKey:KEY_PLUGIN_SETTING_CONTACTS_UPDATE_FREQUENCY_DAY];
    }
    [userDefaults synchronize];
}


/////////////////////////////////////////////////////////////

- (void)insertNewEntityWithData:(NSDictionary *)data
           managedObjectContext:(NSManagedObjectContext *)childContext
                     entityName:(NSString *)entity{
    
    EntityContact * contact = (EntityContact *)[NSEntityDescription insertNewObjectForEntityForName:entity
                                                                             inManagedObjectContext:childContext];
    contact.timestamp = [data objectForKey:@"timestamp"];
    contact.device_id = [data objectForKey:@"device_id"];
    contact.name = [data objectForKey:@"name"];
    contact.phone_numbers = [data objectForKey:@"phone_numbers"];
    contact.emails = [data objectForKey:@"emails"];
    contact.groups = [data objectForKey:@"groups"];
    contact.sync_date = [data objectForKey:@"sync_date"];
}


-(NSString*) jsonStringWithArray:(NSArray *)array prettyPrint:(BOOL) prettyPrint {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array
                                                       options:(NSJSONWritingOptions) (prettyPrint ? NSJSONWritingPrettyPrinted : 0)
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"jsonStringWithArray:prettyPrint: error: %@", error.localizedDescription);
        return @"[]";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}


@end
