//
//  BLEBridge.h
//  HeartRateMonitor
//
//  Created by LouisMcCallum on 23/10/2017.
//  Copyright © 2017 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BLEBridge : NSObject

- (void) startScan;
- (NSArray *) peripherals;
typedef void(^BLEBlock)(void);
typedef void(^BLEIntBlock)(int);
- (instancetype) initWithCallback:(BLEIntBlock) callback;
@property (nonatomic) BLEIntBlock onXData;
@property (nonatomic) BLEBlock onPoweringOn;
@property (nonatomic) BLEBlock onConnection;
@property (nonatomic) BLEBlock onFindingMicrobit;
@property (nonatomic, assign) BOOL connecting;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) BOOL poweredOn;
@property (nonatomic, assign) BOOL foundMicroBit;

@end
