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
    void sendAccData(int data[3]);
private:
    int portNum;
};
