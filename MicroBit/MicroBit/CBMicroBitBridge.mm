//
//  CBMicroBitBridge.mm
//
// Copyright 2017 Louis McCallum
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
// and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial
// portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

#import "CBMicroBitBridge.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreBluetooth/CoreBluetooth.h>
#include <iostream>

#define MICROBIT_NAME @"BBC micro:bit"

/*Full Bluetooth profile at
 https://lancaster-university.github.io/microbit-docs/resources/bluetooth/bluetooth_profile.html
 */

#define ACCELEROMETER_CHARACTERISTIC_UUID @"E95DCA4B-251D-470A-A062-FA1922DFA9A8"
#define ACCELEROMETER_SERVICE_UUID @"E95D0753-251D-470A-A062-FA1922DFA9A8"
#define BUTTON_SERVICE_UUID @"E95D9882-251D-470A-A062-FA1922DFA9A8"
#define BUTTONA_CHARACTERISTIC_UUID @"E95DDA90-251D-470A-A062-FA1922DFA9A8"
#define BUTTONB_CHARACTERISTIC_UUID @"E95DDA91-251D-470A-A062-FA1922DFA9A8"
#define IO_SERVICE_UUID @"E95D127B-251D-470A-A062-FA1922DFA9A8"
#define IODATA_CHARACTERSTIC_UUID @"E95D8D00-251D-470A-A062-FA1922DFA9A8"
#define LED_SERVICE_UUID @"E95DD91D-251D-470A-A062-FA1922DFA9A8"
#define LEDTEXT_CHARACTERISTIC_UUID @"E95D93EE-251D-470A-A062-FA1922DFA9A8"

#define ACCELEROMETER YES
#define BUTTON YES
#define LED NO
#define IO NO

#define CPP

@class CBCentralManager;

@interface CBMicroBitBridge()<CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSArray *peripherals;

@property (nonatomic) BLEArrayBlock onData;
@property (nonatomic) BLEBlock onPoweringOn;
@property (nonatomic) BLEBlock onConnection;
@property (nonatomic) BLEBlock onFindingMicrobit;

@property (nonatomic, assign) NSUInteger prevButtonA;
@property (nonatomic, assign) NSUInteger prevButtonB;

@end

@implementation CBMicroBitBridge

- (instancetype) initWithDataCallback:(BLEArrayBlock) dataCallback
                    discoveryCallBack:(BLEBlock) discoveryCallback
                andConnectionCallback:(BLEBlock) connectionCallback
{
    self = [super init];
    if(self)
    {
        std::cout << "init ObjC" << std::endl;
        self.connecting = NO;
        self.connected = NO;
        self.foundMicroBit = NO;
        self.poweredOn = NO;
        self.prevButtonA = 3;
        self.prevButtonB = 3;
        @autoreleasepool
        {
            self.onData = dataCallback;
            self.onFindingMicrobit = discoveryCallback;
            self.onConnection = connectionCallback;
            dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
            dispatch_async(q, ^{
                std::cout << "making manager" << std::endl;
                self.manager = [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
                self.manager.delegate = self;
            });
#ifdef CPP
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            while(([runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]))
            {
            }
#endif
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
        BOOL isMicrobit = [[aPeripheral name] rangeOfString:MICROBIT_NAME].location != NSNotFound;

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
        
        if([[aService.UUID UUIDString] isEqualToString:ACCELEROMETER_SERVICE_UUID] && ACCELEROMETER)
        {
            [aPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:ACCELEROMETER_CHARACTERISTIC_UUID]] forService:aService];
        }
        if([[aService.UUID UUIDString] isEqualToString:BUTTON_SERVICE_UUID] && BUTTON)
        {
            [aPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:BUTTONA_CHARACTERISTIC_UUID],[CBUUID UUIDWithString:BUTTONB_CHARACTERISTIC_UUID]] forService:aService];
        }
        if([[aService.UUID UUIDString] isEqualToString:LED_SERVICE_UUID] && LED)
        {
            [aPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:LEDTEXT_CHARACTERISTIC_UUID]] forService:aService];
        }
        if([[aService.UUID UUIDString] isEqualToString:IO_SERVICE_UUID] && IO)
        {
            [aPeripheral discoverCharacteristics:@[[CBUUID UUIDWithString:IODATA_CHARACTERSTIC_UUID]] forService:aService];
        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    std::cout << "didDiscoverCharacteristicsForService" << std::endl;
    for (CBCharacteristic *aChar in service.characteristics)
    {
        std::cout <<"Characteristic: " << [[aChar.UUID UUIDString] UTF8String] << std::endl;
        if([aChar.UUID.UUIDString isEqualToString:ACCELEROMETER_CHARACTERISTIC_UUID]
           || [aChar.UUID.UUIDString isEqualToString:BUTTONA_CHARACTERISTIC_UUID]
           || [aChar.UUID.UUIDString isEqualToString:BUTTONB_CHARACTERISTIC_UUID])
        {
            [aPeripheral setNotifyValue:YES forCharacteristic:aChar];
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if([characteristic.UUID.UUIDString isEqualToString:ACCELEROMETER_CHARACTERISTIC_UUID])
    {
        [peripheral readValueForCharacteristic:characteristic];
        NSData *data = characteristic.value;
        const uint16_t *reportData = (const uint16_t *)[data bytes];
        int16_t x = 0;
        int16_t y = 0;
        int16_t z = 0;
        
        x = CFSwapInt16LittleToHost(*(int16_t *)(&reportData[0]));
        y = CFSwapInt16LittleToHost(*(int16_t *)(&reportData[1]));
        z = CFSwapInt16LittleToHost(*(int16_t *)(&reportData[2]));
        
        //std::cout << "x:" << x << " y:" << y << " z:" << z << std::endl;
        
        if(self.onData)
        {
            self.onData(@[@"accelerometer",@(x),@(y),@(z)]);
        }
    }
    else if ([characteristic.UUID.UUIDString isEqualToString:BUTTONA_CHARACTERISTIC_UUID]
             || [characteristic.UUID.UUIDString isEqualToString:BUTTONB_CHARACTERISTIC_UUID])
    {
        [peripheral readValueForCharacteristic:characteristic];
        NSData *data = characteristic.value;
        const uint8_t *bytes = (const uint8_t *)[data bytes]; 
        int state = bytes[0];
       
        BOOL buttonA = [characteristic.UUID.UUIDString isEqualToString:BUTTONA_CHARACTERISTIC_UUID];
        BOOL send;
        NSString *tag;
        
        if(buttonA)
        {
            tag = @"buttonA";
            send = state != self.prevButtonA;
            self.prevButtonA = state;
        }
        else
        {
            tag = @"buttonB";
            send = state != self.prevButtonB;
            self.prevButtonB = state;
        }
        
        if(self.onData && send)
        {
            std::cout << "state:" << state << std::endl;
            self.onData(@[tag,@(state)]);
        }
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
