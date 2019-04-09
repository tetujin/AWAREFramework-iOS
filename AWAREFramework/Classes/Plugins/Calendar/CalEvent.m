//
//  CalEvent.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/16/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "CalEvent.h"
#import <CoreData/CoreData.h>
#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import "AWAREUtils.h"

@implementation CalEvent{
    NSString* AWARE_CAL_EVENT_UNKNOWN;
    NSString* AWARE_CAL_EVENT_ORIGINAL;
    NSString* AWARE_CAL_EVENT_UPDATE;
    NSString* AWARE_CAL_EVENT_DELETE;
    NSString* AWARE_CAL_EVENT_ADD;
    
    NSString* CAL_ID;
    NSString* ACCOUNT_NAME;
    NSString* CAL_NAME;
    NSString* OWNER_ACCOUNT;
    NSString* CAL_COLOR;
    
    NSString* EVENT_ID;
    NSString* TITLE;
    NSString* LOCATION;
    NSString* DESCRIPTION;
    NSString* BEGIN;
    NSString* END;
    NSString* ALL_DAY;
    NSString* COLOR;
    NSString* HAS_ALARM;
    NSString* AVAILABILITY;
    NSString* IS_ORGANIZER;
    NSString* EVENT_TIMEZONE;
    NSString* RRULE;
    
    NSString* STATUS;
    NSString* SEEN;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self initObject];
    }
    return self;
}

- (instancetype)initWithEKEvent:(EKEvent *)event eventType:(CalEventType)eventType{
    self = [super init];
    if (self) {
        [self initObject];
        [self setCalendarEvent:event eventType:eventType];
    }
    return self;
}

- (instancetype)initWithEKEvent:(EKEvent *)event{
    self = [super init];
    if (self) {
        [self initObject];
        [self setCalendarEvent:event eventType:CalEventTypeUnknown];
    }
    return self;
}

- (void) initObject {
    AWARE_CAL_EVENT_UNKNOWN = @"unknown";
    AWARE_CAL_EVENT_ORIGINAL = @"original";
    AWARE_CAL_EVENT_UPDATE= @"update";
    AWARE_CAL_EVENT_DELETE = @"delete";
    AWARE_CAL_EVENT_ADD = @"add";
    
    CAL_ID = @"calendar_id";
    ACCOUNT_NAME = @"account_name";
    CAL_NAME = @"calendar_name";
    OWNER_ACCOUNT = @"owner_account";
    CAL_COLOR = @"calendar_color";
    
    EVENT_ID = @"event_id";
    TITLE = @"title";
    LOCATION = @"location";
    DESCRIPTION = @"description";
    BEGIN = @"begin";
    END = @"end";
    ALL_DAY = @"all_day";
    COLOR = @"color";
    HAS_ALARM = @"has_alarm";
    AVAILABILITY = @"availability";
    IS_ORGANIZER = @"is_organizer";
    EVENT_TIMEZONE = @"event_timezone";
    RRULE = @"rrule";
    
    STATUS = @"status";
    SEEN = @"seen";

}

- (void) setCalendarEvent:(EKEvent *)event eventType:(CalEventType)eventType{
    
    if (event == NULL) {
        NSLog(@"Event is null");
        return;
    }
    
    _objectManageId = [(NSManagedObject *)event objectID];
    
    // ekEvent
    _ekEvent = event;
    
    //    @property (nonatomic, strong) IBOutlet NSString* status;
    [self setCalendarEventType:eventType];
    
    // Calendar Id
    _calendarId=event.calendarItemIdentifier;
    if(_calendarId == nil) _calendarId = @"";
    
    // Account Name
    _accountName = event.calendar.source.title;
    if(_accountName == nil) _accountName = @"";
    
//    @property (nonatomic, strong) IBOutlet NSString* calendarName;
    _calendarName = event.calendar.title;
    if(_calendarName == nil) _calendarName = @"";
    
//    @property (nonatomic, strong) IBOutlet NSString* ownerAccount;
    _ownerAccount = event.calendar.source.title;
    if(_ownerAccount == nil) _ownerAccount = @"";
    
//    @property (nonatomic, strong) IBOutlet NSString* calendarColor;
    // CGFloat * components = CGColorGetComponents(event.calendar.CGColor);
    const size_t numComponents = CGColorGetNumberOfComponents(event.calendar.CGColor);
    const CGFloat *components = CGColorGetComponents(event.calendar.CGColor);
    if (numComponents == 4) {
        CGFloat r = components[0];
        CGFloat g = components[1];
        CGFloat b = components[2];
        CGFloat a = components[3];
        _calendarColor = [NSString stringWithFormat:@"%f,%f,%f,%f", r, g, b, a];
    } else {
        CGFloat r = components[0];
        CGFloat g = components[0];
        CGFloat b = components[0];
        CGFloat a = components[1];
        _calendarColor = [NSString stringWithFormat:@"%f,%f,%f,%f", r, g, b, a];
    }
    if (components  == nil) {
        _calendarColor = @"";
    }
    
    _eventId = event.eventIdentifier;
    if(_eventId == nil) _eventId = @"";
    
//    @property (nonatomic, strong) IBOutlet NSString * title;
    _title = event.title;
    if(_title == nil) _title = @"";
    
//    @property (nonatomic, strong) IBOutlet NSString*  location;
    _location = event.location;
    if(_location == nil) _location = @"";
    
//    @property (nonatomic, strong) IBOutlet NSString* description;
    _notes = event.notes;
    if(_notes == nil) _notes = @"";
    
//    @property (nonatomic, strong) IBOutlet NSString* begin;
    _begin = [[AWAREUtils getUnixTimestamp:event.startDate] stringValue];
    if(_begin == nil) _begin = @"";
    
//    @property (nonatomic, strong) IBOutlet NSString* end;
    _end = [[AWAREUtils getUnixTimestamp:event.endDate] stringValue];
    if(_end == nil) _end = @"";
    
//    @property (nonatomic, strong) IBOutlet NSString* allDay;
    _allDay = @(event.allDay);
    if(_allDay == nil) _allDay = @0;
    
//    @property (nonatomic, strong) IBOutlet NSString* color;
    _color = _calendarColor;
    
//    @property (nonatomic, strong) IBOutlet NSString* hasAlarm;
    _hasAlarm = [NSString stringWithFormat:@"%d",event.hasAlarms];
    if(_hasAlarm == nil) _hasAlarm = @"0";
    
//    @property (nonatomic, strong) IBOutlet NSString* availability;
    //    https://developer.android.com/reference/android/provider/CalendarContract.EventsColumns.html#AVAILABILITY
    //    NSString* availability = @"unavailable";
    _availability = @"0";
    switch (event.availability) {
        case EKEventAvailabilityNotSupported:
            // availability = @"not supported";
            _availability = @"-1";
            break;
        case EKEventAvailabilityBusy:
            //            availability = @"busy";
            _availability = @"0";
            break;
        case EKEventAvailabilityFree:
            //            availability = @"free";
            _availability = @"1";
            break;
        case EKEventAvailabilityTentative:
            //            availability = @"tentative";
            _availability = @"2";
            break;
        case EKEventAvailabilityUnavailable:
            //            availability = @"unavailable";
            _availability = @"-1";
        default:
            break;
    }
    
//    @property (nonatomic, strong) IBOutlet NSString* isOganizer;
    // https://developer.android.com/reference/android/provider/CalendarContract.EventsColumns.html#IS_ORGANIZER
    _isOganizer = event.organizer.description;
    if(_isOganizer == nil) _isOganizer = @"1";

    
//    @property (nonatomic, strong) IBOutlet NSString* eventTimezone;
    _eventTimezone = event.timeZone.description;
    if(_eventTimezone == nil) _eventTimezone = @"";
    
//    @property (nonatomic, strong) IBOutlet NSString* rrule;
    _rrule = event.recurrenceRules.description;
    if(_rrule == nil) _rrule = @"";
    
//    @property (nonatomic, strong) IBOutlet NSString* seen;
    //@"none";
    _seen = @"-1";
    // https://developer.android.com/reference/android/provider/CalendarContract.EventsColumns.html#STATUS
    switch (event.status) {
        case EKEventStatusCanceled:
            //            status = @"canceled";
            _seen = @"2";
            break;
        case EKEventStatusConfirmed:
            //            status = @"confirmed";
            _seen = @"1";
            break;
        case EKEventStatusNone:
            //            status = @"none";
            _seen = @"-1";
            break;
        case EKEventStatusTentative:
            //            status = @"tentative";
            _seen = @"0";
            break;
        default:
            break;
    }
}

- (void)setCalendarEventType:(CalEventType)eventType {
    switch (eventType) {
        case CalEventTypeUnknown:
            _status = AWARE_CAL_EVENT_UNKNOWN;
            break;
        case CalEventTypeOriginal:
            _status = AWARE_CAL_EVENT_ORIGINAL;
            break;
        case CalEventTypeUpdate:
            _status = AWARE_CAL_EVENT_UPDATE;
            break;
        case CalEventTypeDelete:
            _status = AWARE_CAL_EVENT_DELETE;
            break;
        case CalEventTypeAdd:
            _status = AWARE_CAL_EVENT_ADD;
            break;
        default:
            _status = AWARE_CAL_EVENT_UNKNOWN;
            break;
    }
}


- (NSString *) getCreateTableQuery {
    NSMutableString* query = [[NSMutableString alloc] init];
    [query appendFormat:@"_id integer primary key autoincrement,"];
    [query appendFormat:@"timestamp real default 0,"];
    [query appendFormat:@"device_id text default '',"];
    
    [query appendFormat:@"%@ text default '',", CAL_ID];
    [query appendFormat:@"%@ text default '',", ACCOUNT_NAME];
    [query appendFormat:@"%@ text default '',", CAL_NAME];
    [query appendFormat:@"%@ text default '',", OWNER_ACCOUNT];
    [query appendFormat:@"%@ text default '',", CAL_COLOR];
    
    [query appendFormat:@"%@ text default '',", EVENT_ID];
    [query appendFormat:@"%@ text default '',", TITLE];
    [query appendFormat:@"%@ text default '',", LOCATION];
    [query appendFormat:@"%@ text default '',", DESCRIPTION];
    [query appendFormat:@"%@ text default '',", BEGIN];
    [query appendFormat:@"%@ text default '',", END];
    [query appendFormat:@"%@ integer default 0,", ALL_DAY];
    [query appendFormat:@"%@ text default '',", COLOR];
    [query appendFormat:@"%@ text default '',", HAS_ALARM];
    [query appendFormat:@"%@ text default '',", AVAILABILITY];
    [query appendFormat:@"%@ text default '',", IS_ORGANIZER];
    [query appendFormat:@"%@ text default '',", EVENT_TIMEZONE];
    [query appendFormat:@"%@ text default '',", RRULE];
    
    [query appendFormat:@"%@ text default '',", STATUS];
    [query appendFormat:@"%@ text default '',", SEEN];
    
    // [query appendString:@"UNIQUE (timestamp,device_id)"];
    
    return query;
}

-(NSMutableDictionary *)getCalEventAsDictionaryWithDeviceId:(NSString *)deviceId
                                                  timestamp:(NSNumber *)unixtime {
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:deviceId forKey:@"device_id"];
    
//    [query appendFormat:@"%@ text default '',", CAL_ID];
    [dic setObject:_calendarId forKey:CAL_ID];
    if(_calendarId == nil) [dic setObject:@"" forKey:CAL_ID];
        
//    [query appendFormat:@"%@ text default '',", ACCOUNT_NAME];
    if(_accountName == nil){
        [dic setObject:@"" forKey:ACCOUNT_NAME];
    }else{
        if ([AWAREUtils validateEmailWithString:_accountName]) {
            [dic setObject:[AWAREUtils sha1:_accountName] forKey:ACCOUNT_NAME];
        }else{
            [dic setObject:_accountName forKey:ACCOUNT_NAME];
        }
    }
    
//    [query appendFormat:@"%@ text default '',", CAL_NAME];
//    [dic setObject:_calendarName forKey:CAL_NAME];
    if(_calendarName == nil){
        [dic setObject:@"" forKey:CAL_NAME];
    }else{
        if ([AWAREUtils validateEmailWithString:_calendarName]) {
            [dic setObject:[AWAREUtils sha1:_calendarName] forKey:CAL_NAME];
        }else{
            [dic setObject:_calendarName forKey:CAL_NAME];
        }
    }
    
//    [query appendFormat:@"%@ text default '',", OWNER_ACCOUNT];
    if(_ownerAccount == nil) {
        [dic setObject:@"" forKey:OWNER_ACCOUNT];
    }else{
        if ([AWAREUtils validateEmailWithString:_ownerAccount]) {
            [dic setObject:[AWAREUtils sha1:_ownerAccount] forKey:OWNER_ACCOUNT];
        } else {
            [dic setObject:_ownerAccount forKey:OWNER_ACCOUNT];
        }
    }
    
//    [query appendFormat:@"%@ text default '',", CAL_COLOR];
    [dic setObject:_calendarColor forKey:CAL_COLOR];
    if(_calendarColor == nil) [dic setObject:@"" forKey:CAL_COLOR];
//    
//    [query appendFormat:@"%@ text default '',", EVENT_ID];
    [dic setObject:_eventId forKey:EVENT_ID];
    if(_eventId == nil) [dic setObject:@"" forKey:EVENT_ID];
    
//    [query appendFormat:@"%@ text default '',", TITLE];
    [dic setObject:_title forKey:TITLE];
    if(_title == nil) [dic setObject:@"" forKey:TITLE];
    
//    [query appendFormat:@"%@ text default '',", LOCATION];
    [dic setObject:_location forKey:LOCATION];
    if(_location == nil) [dic setObject:@"" forKey:LOCATION];
    
//    [query appendFormat:@"%@ text default '',", DESCRIPTION];
    [dic setObject:_notes forKey:DESCRIPTION];
    if(_notes == nil) [dic setObject:@"" forKey:DESCRIPTION];
    
//    [query appendFormat:@"%@ text default '',", BEGIN];
    [dic setObject:_begin forKey:BEGIN];
    if(_begin == nil) [dic setObject:@"" forKey:BEGIN];
    
//    [query appendFormat:@"%@ text default '',", END];
    [dic setObject:_end forKey:END];
    if(_end == nil) [dic setObject:@"" forKey:END];
    
//    [query appendFormat:@"%@ text default '',", ALL_DAY];

    if(_allDay == nil){
        [dic setObject:@0 forKey:ALL_DAY];
    }else{
        [dic setObject:_allDay forKey:ALL_DAY];
    }
    
//    [query appendFormat:@"%@ text default '',", COLOR];
    [dic setObject:_color forKey:COLOR];
    if(_color == nil) [dic setObject:@"" forKey:COLOR];
    
//    [query appendFormat:@"%@ text default '',", HAS_ALARM];
    [dic setObject:_hasAlarm forKey:HAS_ALARM];
    if(_hasAlarm == nil) [dic setObject:@"" forKey:HAS_ALARM];
    
//    [query appendFormat:@"%@ text default '',", AVAILABILITY];
    [dic setObject:_availability forKey:AVAILABILITY];
    if(_availability == nil) [dic setObject:@"" forKey:AVAILABILITY];
    
//    [query appendFormat:@"%@ text default '',", IS_ORGANIZER];
    [dic setObject:_isOganizer forKey:IS_ORGANIZER];
    if(_isOganizer == nil) [dic setObject:@"" forKey:IS_ORGANIZER];
    
//    [query appendFormat:@"%@ text default '',", EVENT_TIMEZONE];
    [dic setObject:_eventTimezone forKey:EVENT_TIMEZONE];
    if(_eventTimezone == nil) [dic setObject:@"" forKey:EVENT_TIMEZONE];
    
//    [query appendFormat:@"%@ text default '',", RRULE];
    [dic setObject:_rrule forKey:RRULE];
    if(_rrule == nil) [dic setObject:@"" forKey:RRULE];

//    [query appendFormat:@"%@ text default '',", STATUS];
    [dic setObject:_status forKey:STATUS];
    if(_status == nil)[dic setObject:@"" forKey:STATUS];
    
//    [query appendFormat:@"%@ text default '',", SEEN];
    [dic setObject:_seen forKey:SEEN];
    if(_seen == nil) [dic setObject:@"" forKey:SEEN];
    
    return dic;
}


@end
