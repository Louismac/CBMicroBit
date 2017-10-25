# CBMicroBit

CBMicroBit is a C++ wrapper around CoreBluetooth to easily connect a BBC Micro:Bit to a computer running OSX over Bluetooth Low Energy and output to localhost over OSC.

On starting, the program will search the Micro:bit, connect and then subscribe to the Accelerometer and Button services. 

# To Run

Simply open and run the XCode project (MicroBit.xcodeproj). 

Alternatively, run the unix execitable CBMicroBit (./CBMicroBit) from the terminal. 

# OSC Output

The program outputs to localhost:9109 by default. The output port can be set using the first argument of the program

Either edit the scheme in XCode
  CBMicrobit > Edit Scheme > Arguments > Arguments Passed on Launch

Or in the terminal 
  ./CBMicroBit <port>
  
The ouputs are currently 
  /acc,<x>,<y>,<z> for the accelerometer
  /buttonA,<state> for button A state
  /buttonB,<state> for button B state
 
 The Button states are only outputted when they change 
  0 = off
  1 = press
  2 = longpress
  

# The Micro:Bit
We've included a hex file (CBMicrobit.hex) that can just be dragged onto the MicroBit. All it does it advertise the accelerometer, button, thermometer, LED and IO Pin services. 

Important changes to remember to make to the MicrobitConfig.h file if you are building your own project with C++ is setting MICROBIT_BLE_OPEN to 1 (this disables pairing) and MICROBIT_SD_GATT_TABLE_SIZE to its maximum, which is  0x700. If this is not done then the services will not appear.  

# Contributions

We use the excellent OscpPk library to output OSC http://gruntthepeon.free.fr/oscpkt/

# License

This software is distributed under the MIT Licence

Copyright 2017 Louis McCallum

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
