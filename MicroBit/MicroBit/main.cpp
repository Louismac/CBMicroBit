//
//  main.m
//  MicroBit
//
//  Created by LouisMcCallum on 23/10/2017.
//  Copyright © 2017 LouisMcCallum. All rights reserved.
//

#include "BLEcpp.h"
#include <sstream>

int main(int argc, const char * argv[])
{
    int port = 9109;
    if(argc == 2)
    {
        std::stringstream ss(argv[1]);
        ss >> port;
    }
    BLEcpp obj(port);
    return 0;
}
