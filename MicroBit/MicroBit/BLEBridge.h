//
//  BLEBridge.h
//  HeartRateMonitor
//
//  Created by LouisMcCallum on 23/10/2017.
//  Copyright © 2017 Apple Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BLEBridge : NSObject

typedef void(^BLEBlock)(void);
typedef void(^BLEIntBlock)(int);
typedef void(^BLEArrayBlock)(NSArray *);

- (instancetype) initWithDataCallback:(BLEArrayBlock) dataCallback
                    discoveryCallBack:(BLEBlock) discoveryCallback
                andConnectionCallback:(BLEBlock) connectionCallback;

- (void) startScan;
- (NSArray *) peripherals;
- (void) cleanUp;

@property (nonatomic, assign) BOOL connecting;
@property (nonatomic, assign) BOOL connected;
@property (nonatomic, assign) BOOL poweredOn;
@property (nonatomic, assign) BOOL foundMicroBit;

@end
