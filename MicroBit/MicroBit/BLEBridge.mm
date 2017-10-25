//
//  BLEBridge.m
//  HeartRateMonitor
//
//  Created by LouisMcCallum on 23/10/2017.
//  Copyright © 2017 Apple Inc. All rights reserved.
//

#import "BLEBridge.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreBluetooth/CoreBluetooth.h>
#include <iostream>

@class CBCentralManager;

@interface BLEBridge()<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSArray *peripherals;

@property (nonatomic) BLEArrayBlock onAccData;
@property (nonatomic) BLEBlock onPoweringOn;
@property (nonatomic) BLEBlock onConnection;
@property (nonatomic) BLEBlock onFindingMicrobit;

@end

@implementation BLEBridge

- (instancetype) initWithDataCallback:(BLEArrayBlock) dataCallback
                    discoveryCallBack:(BLEBlock) discoveryCallback
                andConnectionCallback:(BLEBlock) connectionCallback
{
    self = [super init];
    if(self)
    {
        std::cout << "init ObjC" << std::endl;
        NSRunLoop *runLoop;
        self.connecting = NO;
        self.connected = NO;
        self.foundMicroBit = NO;
        self.poweredOn = NO;
        @autoreleasepool
        {
            self.onAccData = dataCallback;
            self.onFindingMicrobit = discoveryCallback;
            self.onConnection = connectionCallback;
            dispatch_queue_t q = dispatch_get_main_queue();
            dispatch_async(q, ^{
                std::cout << "making manager" << std::endl;
                self.manager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
                self.manager.delegate = self;
            });
            runLoop = [NSRunLoop currentRunLoop];
            while(([runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]))
            {
            }
        };
    }
    return self;
}

- (void) cleanUp
{
    [self.manager stopScan];
    
    if(self.peripheral)
    {
        [self.manager cancelPeripheralConnection:self.peripheral];
        self.peripheral = nil;
    }
    
    self.manager.delegate = nil;
    self.manager = nil;
}

- (void) startScan
{
    [self.manager scanForPeripheralsWithServices:nil options:nil];
    std::cout << "scanning for peripherals" << std::endl;
}

- (void) stopScan
{
    [self.manager stopScan];
}

#pragma --mark CBCentralManagerDelegate

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self isLECapableHardware];
    std::cout << "Did update state" << std::endl;
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if([aPeripheral name])
    {
        BOOL isMicrobit = [[aPeripheral name] rangeOfString:@"BBC micro:bit"].location != NSNotFound;

        if(isMicrobit && !self.connecting && !self.connected)
        {
            self.connecting = YES;
            const char * name = [[aPeripheral name] UTF8String];
            std::cout << "didDiscoverPeripheral, connecting "<< name << std::endl;
            self.foundMicroBit = YES;
            if(self.onFindingMicrobit)
            {
                self.onFindingMicrobit();
            }
            self.peripheral = aPeripheral;
            [self.manager connectPeripheral:self.peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
        }

    }
}

- (NSArray *) peripherals
{
    return _peripherals;
}

- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %lu - %@", [peripherals count], peripherals);
    NSMutableArray *p = [NSMutableArray new];
    for(CBPeripheral * peripheral in peripherals)
    {
        if([peripheral.name isEqualToString:@"Micro:bit"])
        {
            [self.manager connectPeripheral:peripheral options:nil];
        }
        [p addObject:peripheral.name];
    }
    self.peripherals = [NSArray arrayWithArray:p];
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral
{
    self.connecting = NO;
    self.connected = YES;
    if(self.onConnection)
    {
        self.onConnection();
    }
    std::cout << "didConnectPeripheral" << std::endl;
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    std::cout << "didDisconnectPeripheral" << std::endl;
    self.connected = NO;
    if(self.peripheral )
    {
        [aPeripheral setDelegate:nil];
        aPeripheral = nil;
    }
}

#pragma --mark CBCBPeripheralDelegate

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    std::cout << "didDiscoverServices" << std::endl;
    for (CBService *aService in aPeripheral.services)
    {
        std::cout <<"Service found with UUID: " << [[aService.UUID UUIDString] UTF8String] << std::endl;
        
        [aPeripheral discoverCharacteristics:nil forService:aService];
        
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    std::cout << "didDiscoverCharacteristicsForService" << std::endl;
    for (CBCharacteristic *aChar in service.characteristics)
    {
        std::cout <<"Characteristic: " << [[aChar.UUID UUIDString] UTF8String] << std::endl;
        if([aChar.UUID.UUIDString isEqualToString:@"E95DCA4B-251D-470A-A062-FA1922DFA9A8"])
        {
            [aPeripheral setNotifyValue:YES forCharacteristic:aChar];
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [peripheral readValueForCharacteristic:characteristic];
    NSData *data = characteristic.value;
    const uint8_t *reportData = (const uint8_t *)[data bytes];
    int16_t x = 0;
    int16_t y = 0;
    int16_t z = 0;
    
    x = CFSwapInt16LittleToHost(*(int16_t *)(&reportData[0]));
    y = CFSwapInt16LittleToHost(*(int16_t *)(&reportData[1]));
    z = CFSwapInt16LittleToHost(*(int16_t *)(&reportData[2]));
    
    if(self.onAccData)
    {
        self.onAccData(@[@(x),@(y),@(z)]);
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(!error)
    {
        NSLog(@"notify updated for characteristic %@",[characteristic.UUID UUIDString]);
    }
    else{
        NSLog(@"ERROR updating notify for characteristic %@ : %@",characteristic.UUID, error.localizedDescription);
    }
    
}

- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([self.manager state])
    {
        case CBCentralManagerStateUnsupported:
            std::cout << "The platform/hardware doesn't support Bluetooth Low Energy" << std::endl;
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            std::cout << "The app is not authorized to use Bluetooth Low Energy." << std::endl;
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            std::cout << "Bluetooth is currently powered off." << std::endl;
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            std::cout << "CBCentralManagerStatePoweredOn" << std::endl;
            self.poweredOn = YES;
            if(self.onPoweringOn)
            {
                self.onPoweringOn();
            }
            [self startScan];
            return TRUE;
        case CBCentralManagerStateUnknown:
            std::cout << "CBCentralManagerStateUnknown" << std::endl;
        default:
            return FALSE;
    }
    return NO;
}

@end
