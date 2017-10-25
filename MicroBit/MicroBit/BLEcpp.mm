//
//  MaxObj.cpp
//  HeartRateMonitor
//
//  Created by LouisMcCallum on 23/10/2017.
//  Copyright © 2017 Apple Inc. All rights reserved.
//

#include "BLEcpp.h"
#import "BLEBridge.h"
#import <Foundation/Foundation.h>
#include <iostream>
#include "oscpkt.hh"
#include "udp.hh"
using namespace oscpkt;

struct BLEImpl
{
    BLEBridge *wrapped;
};

BLEcpp::BLEcpp(int port):
impl(new BLEImpl)
{
    portNum = port;
    impl->wrapped = [[BLEBridge alloc] initWithDataCallback:^(NSArray *accData){
        int data[3] = {[accData[0] intValue],[accData[1] intValue],[accData[2] intValue]};
        sendAccData(data);
    } discoveryCallBack:^{
        std::cout << "did Find Micro:bit" << std::endl;
    } andConnectionCallback:^{
        std::cout << "did Connect To Micro:bit" << std::endl;
    }];
}

BLEcpp::~BLEcpp()
{
    std::cout << "destructor called" << std::endl;
    if (impl)
        [impl->wrapped cleanUp];
    delete impl;
}

void BLEcpp::sendAccData(int data[3])
{
    UdpSocket sock;
    sock.connectTo("localhost", portNum);
    Message msg("/acc");
    msg.pushInt32(data[0]);
    msg.pushInt32(data[1]);
    msg.pushInt32(data[2]);
    PacketWriter pw;
    pw.startBundle().startBundle().addMessage(msg).endBundle().endBundle();
    bool ok = sock.sendPacket(pw.packetData(), pw.packetSize());
    if(!ok)
    {
        std::cout << "osc failed to send" << std::endl;
    }
    sock.close();
}

