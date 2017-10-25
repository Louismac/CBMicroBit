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
    sendPort = port;
    impl->wrapped = [[BLEBridge alloc] initWithDataCallback:^(NSArray *data){
        std::string service = [data[0] UTF8String];
        if(service == "accelerometer")
        {
            int accData[3] = {[data[1] intValue],[data[2] intValue],[data[3] intValue]};
            sendAccData(accData);
        }
        else if (service == "buttonA")
        {
            int state = [data[1] intValue];
            sendButtonData(true, state);
        }
        else if (service == "buttonB")
        {
            int state = [data[1] intValue];
            sendButtonData(false, state);
        }
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

void BLEcpp::sendButtonData(bool buttonA, int state)
{
    UdpSocket sock;
    sock.connectTo("localhost", sendPort);
    Message msg(buttonA ? "buttonA":"buttonB");
    msg.pushInt32(state);
    PacketWriter pw;
    pw.startBundle().startBundle().addMessage(msg).endBundle().endBundle();
    bool ok = sock.sendPacket(pw.packetData(), pw.packetSize());
    if(!ok)
    {
        std::cout << "osc failed to send" << std::endl;
    }
    sock.close();
}

void BLEcpp::sendAccData(int data[3])
{
    UdpSocket sock;
    sock.connectTo("localhost", sendPort);
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

/*
void BLEcpp::runServer() {
    UdpSocket sock;
    sock.bindTo(receivePort);
    if (!sock.isOk()) {
        std::cout << "Error opening port " << receivePort << ": " << sock.errorMessage() << std::endl;
    } else {
        std::cout << "Server started, will listen to packets on port " << receivePort << std::endl;
        PacketReader pr;
        PacketWriter pw;
        while (sock.isOk()) {
            if (sock.receiveNextPacket(30)) {
                pr.init(sock.packetData(), sock.packetSize());
                oscpkt::Message *msg;
                while (pr.isOk() && (msg = pr.popMessage()) != 0) {
                    int iarg;
                    if (msg->match("/LED").popInt32(iarg).isOkNoMoreArgs()) {
                        std::cout << "Server: received /LED " << iarg << " from " << sock.packetOrigin() << "\n";
                    } else {
                        std::cout << "Server: unhandled message: " << "\n";
                    }
                }
            }
        }
    }
}
*/

