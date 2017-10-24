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
const int PORT_NUM = 9109;


struct BLEImpl
{
    BLEBridge *wrapped;
};

BLEcpp::BLEcpp():
impl(new BLEImpl)
{
    impl->wrapped = [[BLEBridge alloc] initWithCallback:^(int x){
        std::cout << "x:" << x << std::endl;
        sendX(x);
    }];
}

void BLEcpp::sendX(int x)
{
    UdpSocket sock;
    sock.connectTo("localhost", PORT_NUM);
    Message msg("/x");
    msg.pushInt32(x);
    PacketWriter pw;
    pw.startBundle().startBundle().addMessage(msg).endBundle().endBundle();
    bool ok = sock.sendPacket(pw.packetData(), pw.packetSize());
    sock.close();
}

