//
//  MaxObj.hpp
//  HeartRateMonitor
//
//  Created by LouisMcCallum on 23/10/2017.
//  Copyright © 2017 Apple Inc. All rights reserved.
//

#include <stdio.h>
#include <vector>

struct BLEImpl;

class BLEcpp
{
public:
    BLEcpp(int port);
    ~BLEcpp();
    BLEImpl* impl;
private:
    int sendPort;
    int receivePort = 8000;
    void runServer();
    void sendAccData(int data[3]);
    void sendButtonData(bool buttonA, int state);
};
