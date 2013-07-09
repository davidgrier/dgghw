;+
; NAME:
;    DGGhwPrior
;
; PURPOSE:
;    Object for interacting with a Prior Proscan II or III Microscope Stage
;
; USAGE:
;    a = DGGhwPrior(device)
;
; PROPERTIES:
;    DEVICE:       (IG ) name of the device character file to which the
;        Proscan is attached
;    POSITION:     ( GS) [x,y,z] coordinates [micrometers]
;    X:            ( GS) x position [micrometers]
;    Y:            ( GS) y position [micrometers]
;    Z:            ( GS) z position [micrometers]
;    DX:           (IGS) x step size [micrometers]
;    DY:           (IGS) y step size [micrometers]
;    DZ:           (IGS) z step size [micrometers]
;    SPEED:        (IGS) maximum speed as a percentage from 1 to 100
;    ACCELERATION: (IGS) maximum acceleration as a percentage from 1 to 100
;    SCURVE:       (IGS) S-curve as a percentage from 1 to 100
;
; METHODS:
;    DGGhwPrior::GetProperty
;    DGGhwPrior::SetProperty
;
;    DGGhwPrior::Command(cmd, expect=expect, text=text)
;        Send specificed command to the Proscan and return the result.
;
;        CMD: Command to send to Proscan
;        EXPECT: Some commands result in a expected return value upon
;            success.  Set this to the expected return value.
;        TEXT: (Flag) Some commends yield multiple lines of text.
;            Set this flag to return the full text.
;
;    DGGhwPrior::Clear
;        Clear command queue, reset error conditions and stop all
;        operations.
;
;    DGGhwPrior::SetOrigin
;        Define the current position to be the origin of coordinates
;
;    DGGhwPrior::SetPosition, r
;        Define the current position to have specific coordinates.
;        R: [x, y, z] coordinates [micrometers]
;
;    DGGhwPrior::MoveTo, r, relative=relative
;        Move to the specified position relative to the current
;        origin.
;        R: position of destination: This may be a 1, 2 or 3-element argument
;           Z:       Axial position [micrometers]
;           [X,Y]:   In-plane position [micrometers]
;           [X,Y,Z]: Three-dimensional position [micrometers]
;        RELATIVE: If set, move relative to current position.
;
;    DGGhwPrior::Step, [keyword flags]
;        RIGHT: Move dx along x
;        LEFT:  Move -dx along x
;        UP:    Move dy along y
;        DOWN:  Move -dy along y
;        ZUP:   Move dz along z
;        ZDOWN: Move -dz along z
;
; INHERITS:
;    IDL_Object: permits implicity get and set methods
;    IDLitComponent: properties registered with PROPERTYSHEET widgets
;
; NOTES:
;    1. The user must have read and write permissions for the
;    serial port.  The most security-conscious option is to
;    add the user to the appropriate group (i.e. dialout for
;    the Proscan III), rather than trying to extend the permissions
;    of the device file.
;
;    2. The default device file for a Prior Proscan III is
;    /dev/ttyACM0.
;    This can be discovered by plugging the controller into the 
;    USB bus and taking note of which device file is created,
;    for example with the Unix command
;    tail dmesg
;
; MODIFICATION HISTORY:
; 12/01/2011 Written by David G. Grier, New York University
; 12/06/2011 DGG Cleaned up IDLitComponent code.
; 12/09/2011 DGG added STEP command.
; 02/02/2012 DGG Set communications parameters.
; 05/03/2012 DGG update parameter checking for Init and SetProperty.
; 07/08/2013 DGG updates for Prior Proscan III.  Small code cleanups.
;    Additions to documentation.  Check for timeout on read.
;    Increase timeout to 1 second (!).
;
; Copyright (c) 2011-2013, David G. Grier
;-

;;;;
;
; DGGhwPrior::Speed
;
; Get and set maximum speed as percentage
;
function DGGhwPrior::Speed, value

COMPILE_OPT IDL2, HIDDEN

if n_params() eq 1 then begin
   if (value lt 1) or (value gt 100) then $
      message, 'value must be between 1 and 100', /inf
   str = 'SMS,'+strtrim((value > 1) < 100, 2)
   if ~self.command(str, expect = '0') then $
      message, 'could not set maximum speed', /inf
endif

return, fix(self.command('SMS'))
end

;;;;
;
; DGGhwPrior::Acceleration
;
; Get and set maximum acceleration as percentage
;
function DGGhwPrior::Acceleration, value

COMPILE_OPT IDL2, HIDDEN

if n_params() eq 1 then begin
   if (value lt 1) or (value gt 100) then $
      message, 'value must be between 1 and 100', /inf
   str = 'SAS,'+strtrim((value > 1) < 100,  2)
   if ~self.command(str, expect = '0') then $
      message, 'could not set maximum acceleration', /inf
endif

return, fix(self.command('SAS'))
end
;;;;
;
; DGGhwPrior::SCurve
;
; Get and set S-curve value as percentage
;
function DGGhwPrior::SCurve, value

COMPILE_OPT IDL2, HIDDEN

if n_params() eq 1 then begin
   if (value lt 1) or (value gt 100) then $
      message, 'value must be between 1 and 100', /inf
   str = 'SCS,'+strtrim((value > 1) < 100,  2)
   if ~self.command(str, expect = '0') then $
      message, 'could not set S-curve value', /inf
endif

return, fix(self.command('SCS'))
end

;;;;
;
; DGGhwPrior::MoveTo
;
; Set position
;
pro DGGhwPrior::MoveTo, r, relative = relative

COMPILE_OPT IDL2, HIDDEN

str = keyword_set(relative) ? 'GR' : 'G'

case n_elements(r) of
   1: begin 
      pos = keyword_set(relative) ? [0L, 0, 0] : self.position
      pos[2] = long(r)
   end
   2: pos = long(r)
   3: pos = long(r)
   else: begin
      message, 'coordinates must have 1, 2 or 3 elements', /inf
      return
   endelse
endcase
str += ',' + strjoin(strtrim(pos, 2), ',')

if ~self.command(str, expect = 'R') then $
   message, 'motion command failed', /inf

end

;;;;;
;
; DGGhwPrior::Step
;
; Move one step in specified direction
;
pro DGGhwPrior::Step, right = right, $
                      left = left, $
                      up = up, $
                      down = down, $
                      zup = zup, $
                      zdown = zdown

COMPILE_OPT IDL2, HIDDEN

if keyword_set(right) then $
   self.moveto, [self.dx, 0, 0], /relative

if keyword_set(left) then $
   self.moveto, [-self.dx, 0, 0], /relative

if keyword_set(up) then $
   self.moveto, [0, self.dy, 0], /relative

if keyword_set(down) then $
   self.moveto, [0, -self.dy, 0], /relative

if keyword_set(zup) then $
   self.moveto, [0, 0, self.dz], /relative

if keyword_set(zdown) then $
   self.moveto, [0, 0, -self.dz], /relative

end

;;;;;
;
; DGGhwPrior::SetOrigin
;
; Set current position to be origin of coordinate system
;
pro DGGhwPrior::SetOrigin

COMPILE_OPT IDL2, HIDDEN

self.setposition, [0L, 0, 0]

end

;;;;;
;
; DGGhwPrior::SetPosition
;
; Set the coordinate of the current position
;
pro DGGhwPrior::SetPosition, r

COMPILE_OPT IDL2, HIDDEN

if n_elements(r) ne 3 then begin
   message, 'coordinate must have three elements', /inf
   return
endif

str = 'P,' + strjoin(strtrim(long(r), 2), ',')
if ~self.command(str, expect = '0') then $
   message, 'unable to set origin', /inf

end

;;;;;
;
; DGGhwPrior::Position()
;
; Get position
;
function DGGhwPrior::Position

COMPILE_OPT IDL2, HIDDEN

s = self.command('P')
regex = '(-?[0-9]+),(-?[0-9]+),(-?[0-9]+)'
if stregex(s, regex) then $
   r = [0L, 0, 0] $
else $
   r = (long(stregex(s, regex, /subexpr, /extract)))[1:3]

return, r

end

;;;;;
;
; DGGhwPrior::EmergencyStop
;
; Perform an emergency stop
;
pro DGGhwPrior::EmergencyStop

COMPILE_OPT IDL2, HIDDEN

if ~self.command('K', expect = 'R') then $
    message, "Emergency stop failed!", /inf

return
end

;;;;;
;
; DGGhwPrior::Clear
;
; Clear the command queue, reset error conditions, and
; stop all operations
;
pro DGGhwPrior::Clear

COMPILE_OPT IDL2, HIDDEN

if ~self.command('I', expect = 'R') then $
    message, 'Clear operation failed!', /inf

end

;;;;;
;
; DGGhwPrior::Command()
;
; Send command to Proscan controller and return response
;
function DGGhwPrior::Command, cmd, $
                              expect = expect, $
                              text = text

COMPILE_OPT IDL2, HIDDEN

self.port.write, cmd
str = self.port.read(err = err)

if err then $
   message, 'read timed out', /inf

err = long((stregex(str, 'E,([0-9]+)', /subexpr, /extract))[1])
if err then begin
   message, 'ERROR: ' + str, /inf
   return, 0
endif

if isa(expect, 'string') then $
   return, strcmp(str, expect)

if keyword_set(text) then begin
   res = []
   while ~strcmp(str, 'end', 3, /fold_case)  do begin
      res = [[res], [str]]
      str = self.port.read()
   endwhile
endif else $
   res = str

return, res
end

;;;;;
;
; DGGhwPrior::SetProperty
;
; Set properties of the DGGhwPrior object
;
pro DGGhwPrior::SetProperty, position = position, $
                             x = x, $
                             y = y, $
                             z = z, $
                             dx = dx, $
                             dy = dy, $
                             dz = dz, $
                             speed = speed, $
                             acceleration = acceleration, $
                             scurve = scurve, $
                             _ref_extra = re

self->IDLitComponent::SetProperty, _extra = re

if isa(position, /number) then $
   self.moveto, position

if n_elements(x) + n_elements(y) + n_elements(z) ge 1 then begin
   r = self.position()
   if isa(x, /scalar, /number) then r[0] = x
   if isa(y, /scalar, /number) then r[1] = y
   if isa(z, /scalar, /number) then r[2] = z
   self.moveto, r
endif
   
if isa(dx, /scalar, /number) then $
   self.dx = long(dx)

if isa(dy, /scalar, /number) then $
   self.dy = long(dy)

if isa(dz, /scalar, /number) then $
   self.dz = long(dz)

if isa(speed, /number) then $
   void = self.speed(speed)

if isa(acceleration, /number) then $
   void = self.acceleration(acceleration)

if isa(scurve, /number) then $
   void = self.scurve(scurve)

end

;;;;;
;
; DGGhwPrior::GetProperty
;
; Get properties of the DGGhwPrior object
;
pro DGGhwPrior::GetProperty, device = device, $
                             version = version, $
                             position = position, $
                             x = x, $
                             y = y, $
                             z = z, $
                             dx = dx, $
                             dy = dy, $
                             dz = dz, $
                             speed = speed, $
                             acceleration = acceleration, $
                             scurve = scurve, $
                             _ref_extra = re
                             
COMPILE_OPT IDL2,  HIDDEN

self->IDLitComponent::GetProperty, _extra = re

if arg_present(device) then $
   device = self.port.device

if arg_present(version) then $
   version = self.command('VERSION')

if arg_present(position) then $
   position = self.position()

if (arg_present(x) || arg_present(y) || arg_present(z)) then begin
   r = self.position()
   x = r[0]
   y = r[1]
   z = r[2]
endif

if arg_present(dx) then $
   dx = self.dx

if arg_present(dy) then $
   dy = self.dy

if arg_present(dz) then $
   dz = self.dz

if arg_present(speed) then $
   speed = self.speed()

if arg_present(acceleration) then $
   acceleration = self.acceleration()

if arg_present(scurve) then $
   scurve = self.scurve()
end

;;;;;
;
; DGGhwPrior::Cleanup
;
; Free resources used by the DGGhwPrior object
;
pro DGGhwPrior::Cleanup

obj_destroy, self.port

end

;;;;;
;
; DGGhwPrior::Init
;
; Initialize the DGGhwPrior object
;
function DGGhwPrior::Init, device, $
                           dx = dx, $
                           dy = dy, $
                           dz = dz, $
                           speed = speed, $
                           acceleration = acceleration, $
                           scurve = scurve, $
                           quiet = quiet, $
                           _ref_extra = re

COMPILE_OPT IDL2, HIDDEN

if n_params() ne 1 then begin
   message, 'Specify the RS232 device file for the Proscan Controller', /inf
   return, 0
endif

if (self->IDLitComponent::Init(_extra = re) ne 1) then $
   return, 0

; open serial port
port = DGGhwSerial(device)
if ~isa(port, 'DGGhwSerial') then $
   return, 0

; save present settings so that they can be restored
osettings = port.settings

; settings for Proscan II determined with minicom
; and recorded with stty -g
port.settings = ['1:0:8bd:0:3:1c:7f:15:4:5:1:0:11:13' + $
                 ':1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0']
; settings for Proscan III
port.settings = ['1401:0:cbd:0:3:1c:7f:15:4:5:1:0:11:13' + $
                 ':1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0']
port.eol = string(13b)
port.timeout = 1.0 ; long timeout for motion commands

self.port = port
; check that the device is a Prior Proscan Controller
a = self.command("VERSION")
if strlen(a) ne 3 then begin    ; version is a 3-digit string
   if ~keyword_set(quiet) then $
   message, device + ' does not appear to be a Proscan Controller', /inf
   port.settings = osettings
   obj_destroy, self.port
   return, 0
endif

self.dx = isa(dx, /scalar, /number) ? long(dx) : 1L
self.dy = isa(dy, /scalar, /number) ? long(dy) : 1L
self.dz = isa(dz, /scalar, /number) ? long(dz) : 1L

if isa(speed, /scalar, /number) then $
   void = self.speed(speed)

if isa(acceleration, /scalar, /number) then $
   void = self.acceleration(acceleration)

if isa(scurve, /scalar, /number) then $
   void = self.scurve(scurve)

self.name = 'DGGhwPrior'
self.description = 'Prior Proscan Controller'
self->setpropertyattribute, 'NAME', /HIDE
self->registerproperty, 'device', /STRING, NAME = 'device', SENSITIVE = 0
self->registerproperty, 'version', /STRING, NAME = 'version', SENSITIVE = 0
self->registerproperty, 'x', /INTEGER, NAME = 'x', SENSITIVE = 0
self->registerproperty, 'y', /INTEGER, NAME = 'y', SENSITIVE = 0
self->registerproperty, 'z', /INTEGER, NAME = 'z', SENSITIVE = 0
self->registerproperty, 'dx', /INTEGER, NAME = 'dx', $
                        VALID_RANGE = [1, 100]
self->registerproperty, 'dy', /INTEGER, NAME = 'dy', $
                        VALID_RANGE = [1, 100]
self->registerproperty, 'dz', /INTEGER, NAME = 'dz', $
                        VALID_RANGE = [1, 10]
self->registerproperty, 'speed', /INTEGER, NAME = 'speed', $
                        VALID_RANGE = [1, 100]
self->registerproperty, 'acceleration', /INTEGER, NAME = 'acceleration', $
                        VALID_RANGE = [1, 100]
self->registerproperty, 'scurve', /INTEGER, NAME = 'scurve', $
                        VALID_RANGE = [1, 100]

return, 1
end

;;;;;
;
; DGGhwPrior_define
;
; Object definition for a Prior Proscan stage controller
;
pro DGGhwPrior__define

COMPILE_OPT IDL2

struct = {DGGhwPrior, $
          inherits IDL_Object, $
          inherits IDLitComponent, $
          dx: 0L, $
          dy: 0L, $
          dz: 0L, $
          port: obj_new() $
         }
end
