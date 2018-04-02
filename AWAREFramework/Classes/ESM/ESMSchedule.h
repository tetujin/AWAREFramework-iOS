//
//  ESMSchedule.h
//  AWAREFramework
//
//  Created by Yuuki Nishiyama on 2018/03/27.
//

#import <Foundation/Foundation.h>
#import "ESMItem.h"

@interface ESMSchedule : NSObject

@property (nonatomic) NSString *scheduleId;
@property (nonatomic) NSNumber *expirationThreshold;
@property (nonatomic) NSDate   *startDate;
@property (nonatomic) NSDate   *endDate;
@property (nonatomic) NSString *noitificationBody;
@property (nonatomic) NSString *notificationTitle;
@property (nonatomic) NSArray  *fireHours;
@property (nonatomic) NSArray  *context;
@property (nonatomic) NSNumber *interface;
@property (nonatomic) NSNumber *randomizeEsm;
@property (nonatomic) NSNumber *randomizeSchedule;
@property (nonatomic) NSNumber *temporary;
@property (readonly)  NSArray  *esms;

- (void)addESMs:(NSArray <ESMItem *> *)esmItems;
- (void)addESM:(ESMItem *)esmItem;

@end
///////////////////
