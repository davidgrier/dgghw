# dgghw

**IDL objects for controlling hardware on
UNIX-like operating systems**

IDL is the Interactive Data Language, and is a product of
[Exelis Visual Information Solutions](http://www.exelisvis.com).

dgghw is licensed under the GPLv3.

## What it does

The dgghw objects provide access to devices connected to
computers.

* **DGGhwSerial__define**
The DGGhwSerial object uses native IDL routines to communicate
over a serial port.
This is the base class for communicating with hardware connected
to a computer with a serial cable.  It also can be used to communicate
with USB devices through a USB-to-serial converter.  Some USB devices
actually incorporate such converters and can be accessed with
DGGhwSerial directly.

* **DGGhwPrior__define**: An IDL object that interacts with
Prior Proscan microscope stage controllers.

* **DGGhwIPGLaser__define**: An IDL object for controlling
and monitoring an IPG Laser.

* **DGGhwShutter__define**: An IDL object for interacting with
a Thorlabs SC10 Shutter Controller.

## Usage notes
DGGhwSerial communicates with devices through a device file that
is created dynamically when the device is plugged in.  A typical
device file for a USB-serial interface might be 
/dev/ttyUSB0 or /dev/ttyACM0.
It is up to the user to provide the name of correct device file.
This may be determined by issuing the command dmesg immediately
after plugging in the device and looking for information about
what device file was created dynamically.

It also is up to the user to set up the serial port correctly
so that the computer can communicate with the device.  If the
object cannot communicate with the device "out of the box,"
it may be necessary to investigate the serial port's settings.
An easy way to do this is to run minicom and fiddle with its settings
until everything works.  Once you have a working configuration,
issue the command stty -g to get a computer-readable listing of the
correct settings, and use this to initialize the object. 
