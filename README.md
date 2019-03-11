# CBMicroBit

CBMicroBit is a C++ wrapper around CoreBluetooth to easily connect a BBC Micro:Bit to a computer running OSX over Bluetooth Low Energy and optionally output to localhost over OSC.

On starting, the program will search the Micro:bit, connect and then subscribe to the Accelerometer and Button services. Button and accelerometer data can then be picked up by applications running on OSX that accept OSC (e.g. Max/MSP, Supercollider, Processing).

It can be standalone as a Unix Executable, included in C++ projects or native Objective C apps (Desktop macOSX apps or iOS phone apps).

## To Run

Simply open and run the XCode project (MicroBit.xcodeproj). 

Alternatively, run the unix execitable CBMicroBit 
```
./CBMicroBit
```
from the terminal. Or by double clicking on it.

## The Micro:Bit
We've included two hex files that can just be dragged onto the MicroBit (CBMicrobit.hex and CBMicrobitCombinedSensors.hex, if your Micro:Bit is a newer version ~ after Oct 2018, then it may have a combined IMU sensor, instread of separate accelermeoter, compass etc..., in which case, use the latter) . All it does it advertise the accelerometer, button, thermometer, LED and IO Pin services. 

Important changes to remember to make to the MicrobitConfig.h file (/microbit-samples/yotta_modules/microbit-dal/inc/core/MicroBitConfig.h) if you are building your own /hex file is setting MICROBIT_BLE_OPEN to 1 (this disables pairing) and MICROBIT_SD_GATT_TABLE_SIZE to its maximum, which is  0x700. If this is not done then the services will not appear. 

## OSC Output

The program outputs to localhost:57120 by default. The output port can be set using the first argument of the program

Either edit the scheme in XCode
```
  CBMicrobit -> Edit Scheme -> Arguments -> Arguments Passed on Launch
```

Or in the terminal 
```
  ./CBMicroBit <port>
```
The ouputs are currently 
```
  /acc,<x>,<y>,<z> for the accelerometer
  /buttonA,<state> for button A state
  /buttonB,<state> for button B state
  /pins, <0>,<1>,<2> for IO pins
```

 The Button states are only outputted when they change 

 ```
  0 = off
  1 = press
  2 = longpress
 ```  

The IO Pin service currently sets all pins to inputs (receiving sensor data) and sets all pins to analogue and then outputs the values of pins 0,1 and 2. To have more fined grained control or use pins as outputs, you'll need to change the pinInputs array [CBMicroBitBridge.mm](https://github.com/Louismac/CBMicroBit/blob/master/MicroBit/MicroBit/CBMicroBitBridge.mm)

## Editting the Project

The program is set up to run as a C++ object to be included in C++ projects, however, the internal Objective C code could easily to put into a native macOSX app (see [CBMicroBitBridge.mm](https://github.com/Louismac/CBMicroBit/blob/master/MicroBit/MicroBit/CBMicroBitBridge.mm)). 

In order to get receive the delegate callbacks for CoreBluetooth in a commandline tool (as opposed to an app), its necessary to create an NSRunLoop. This is blocks the main thread so this may have unforseen conseqeunces when included in other C++ projects. I haven't been able to get this to work without doing this or by initiating the BLEcpp object not on the main thread. You can however, execute C++ code on a background thread whilst the Micro:Bit is connecting and receiving data over BLE on the main thread. There is a simple example of this in [main.cpp](https://github.com/Louismac/CBMicroBit/blob/master/MicroBit/MicroBit/main.cpp).

To include the CBMicroBit in a C++ project simply instanitiate the CBMicroBit object, giving the output port and whether you want to OSC the output

```
CBMicroBit ble(<port>,<osc>);
```

Starting a NSRunLoop is not necessary for Desktop macOSX apps or iOS phone apps and so this can be disabled by commenting out

```
#define CPP
```

in [CBMicroBitBridge.mm](https://github.com/Louismac/CBMicroBit/blob/master/MicroBit/MicroBit/CBMicroBitBridge.mm)

You can also change what data is reported by altering the options at the top of [CBMicroBitBridge.mm](https://github.com/Louismac/CBMicroBit/blob/master/MicroBit/MicroBit/CBMicroBitBridge.mm)

```
#define ACCELEROMETER <YES/NO>
#define BUTTON <YES/NO>
#define IO <YES/NO>
```

### Support For Wekinator

You can send the data from the microbit directly to Rebecca Fiebrinks [Wekinator](http://wekinator.org/) machine learning tool by either setting the boolean in [CBMicroBit.mm](https://github.com/Louismac/CBMicroBit/blob/master/MicroBit/MicroBit/CBMicroBit.mm) or by passing the string "true" to as the second argument to the unix executable.

```
./CBMicroBit <port> <wekinator>
```

The data will be sent as an array of 8 floats [accx, accy, accz, buttonA, buttonB, pin1, pin2, pin3].

## Trouble shooting

### My Micro:bit isn't connecting
  Is it connected to another computer or already connected to your computer? The Micro:Bit will only connect to one Central and the program requires it to not be connected to anything when it runs (even your own computer ). You can check whether you are already connected to the Micro:Bit by clicking on the Bluetooth icon in your toolbar. If you are already connected, disconnect. The program should then pick it up again without needing to restart. 

## Contributions

We use the excellent [Oscpkt](http://gruntthepeon.free.fr/oscpkt/) library to output OSC 

## License

This software is distributed under the MIT Licence

Copyright 2017 Louis McCallum

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
