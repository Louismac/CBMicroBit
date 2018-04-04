//
//  main.cpp
//  MicroBit
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

#include "CBMicroBit.h"
#include <sstream>
#include <string>
#include <iostream>
#include <thread>

using namespace std;

void task1(string msg)
{
    for(int i = 0; i < 100 ; i++)
    {
       cout << "task1 says: " << msg << endl;;
       this_thread::sleep_for(std::chrono::milliseconds(500));
    }
}

int main(int argc, const char * argv[])
{
    int port = 57120;
    bool wekinator = false;
    if(argc >= 2)
    {
        stringstream ss(argv[1]);
        ss >> port;
        cout << "port set to "<< port << endl;
    }
   
    if (argc >= 3)
    {
        string w = "";
        stringstream ss(argv[2]);
        ss >> w;
        wekinator = w == "true";
        cout << "wekinator set to "<< w << endl;
    }
    
    
    //EXAMPLE OF THREADING
    //thread t1(task1, "Hello");
    
    CBMicroBit obj(port,true, wekinator);
    return 0;
}
