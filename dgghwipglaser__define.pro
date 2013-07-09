;+
; NAME:
;    DGGhwIPGlaser
;
; PURPOSE:
;    Object class for controlling an IPG fiber laser
;
; CATEGORY:
;    Equipment control
;
; USAGE:
;    a = DGGhwIPGlaser(device)
;
; PROPERTIES:
;    DEVICE:      (IG ) Name of the serial port's device file
;    FIRMWARE:    ( G ) Version of the laser's firmware
;    STATUS:      ( G ) Instrument status: structure of type IPGLaserStatus
;    KEYSWITCH:   ( G ) Keyswitch status: 1 on, 0 off
;    EMISSION:    ( GS) Emission status:  1 on, 0 off
;    CURRENT:     ( GS) Diode current as percentage of maximum current
;    POWER:       ( G ) Emission power [W]
;    TEMPERATURE: ( G ) Diode temperature [degrees C]
;
; METHODS:
;    DGGhwIPGlaser::GetProperty
;    DGGhwIPGlaser::SetProperty
;
; INHERITS:
;    IDL_Object so that properties can be get or set using implicit
;    syntax.
;
; EXAMPLE:
; IDL> a = DGGhwIPGLaser("/dev/ttyUSB0")
; IDL> help, a.status
; IDL> a.emission = 1
; IDL> a.current = 10
;
; MODIFICATION HISTORY:
; 03/15/2011 Written by David G. Grier, New York University
; 04/26/2011 DGG derived from IPGLASER class.
; 06/23/2011 DGG inherits DGGhwSerialDevice
; 11/28/2011 DGG DGGhwSerial used as an object, rather than
;    being inherited.
; 12/03/2011 DGG determined robust communications settings.
; 12/06/2011 DGG Cleaned up IDLitComponent code.
;
; Copyright (c) 2011, David G. Grier
;-
;;;;;
;
; DGGhwIPGlaser::Keyswitch
;
; Get keyswitch setting
;
function DGGhwIPGlaser::Keyswitch

COMPILE_OPT IDL2, HIDDEN

st = self.status()
return, st.keyswitch

end


;;;;;
;
; DGGhwIPGlaser::Emission
;
; Set and return emission status
;
function DGGhwIPGlaser::Emission, status

COMPILE_OPT IDL2, HIDDEN

if n_params() eq 1 then begin
   if ~self.keyswitch() then $
      message, 'Keyswitch is off', /inf
   void = self.command((status) ? 'EMON' : 'EMOFF')
endif

st = self.status()
return, st.emission

end

;;;;;
;
; DGGhwIPGlaser::Power()
;
; Get laser power
;
function DGGhwIPGlaser::Power

COMPILE_OPT IDL2, HIDDEN

res = self.command('ROP')
if strcmp(res, 'off', 3, /fold_case) then $
   return, 0. $
else if strcmp(res, 'low', 3, /fold_case) then $
   return, 0.1
return, float(res)
end

;;;;;
;
; DGGhwIPGlaser::Current()
;
; Get and set the diode current
;
function DGGhwIPGlaser::Current, value

COMPILE_OPT IDL2, HIDDEN

if n_params() eq 0 then $
   return, float(self.command('RCS'))

value = (value > float(self.command('RNC'))) < 100.
cmd = 'SDC ' + strtrim(string(value, format = '(F5.1)'), 2)
return, float(self.command(cmd))
end

;;;;;
;
; DGGhwIPGlaser::Temperature()
;
; Get laser temperature
;
function DGGhwIPGlaser::Temperature

COMPILE_OPT IDL2, HIDDEN

return, float(self.command('RCT'))
end

;;;;;
;
; DGGhwIPGlaser::Status()
;
; Get laser status
;
function DGGhwIPGlaser::Status

COMPILE_OPT IDL2, HIDDEN

res = fix(self.command('STA'))

status = {IPGlaserStatus,                            $
          emission:           ((res AND 2^2) ne 0),  $
          backreflection:     ((res AND 2^3) ne 0),  $
          analogcontrol:      ((res AND 2^4) ne 0),  $
          moduledisconnect:   ((res AND 2^6) ne 0),  $
          modulefailure:      ((res AND 2^7) ne 0),  $
          aimingbeam:         ((res AND 2^8) ne 0),  $
          powersupply:        ((res AND 2^11) EQ 0), $
          modulationenabled:  ((res AND 2^12) ne 0), $
          laserenable:        ((res AND 2^14) ne 0), $
          safeemission:       ((res AND 2^15) ne 0), $
          unexpectedemission: ((res AND 2^17) ne 0), $
          keyswitch:          ((res AND 2^21) EQ 0), $
          aimingbeamhardware: ((res AND 2^22) ne 0), $
          modulesconnected:   ((res AND 2^29) EQ 0), $
          collimator:         ((res AND 2^30) ne 0)  $
         }

return, status
end

;;;;;
;
; DGGhwIPGlaser::Command()
;
; Send command to IPG laser and return response
;
function DGGhwIPGlaser::Command, cmd

COMPILE_OPT IDL2, HIDDEN

self.port.write, cmd
str = self.port.read()

; NULL return suggests that device is not responding
; ... perhaps not an IPG laser?
if strlen(str) lt 1 then $
   return, ''

; Check for bad command
if strcmp(str, 'BCMD', /fold_case) then begin
   message, cmd + ': invalid command', /inf
   return, ''
endif

; Check for other error conditions
res = stregex(str, 'ERR: (.*)', /subexpr, /extract)
if strlen(res[0]) ge 1 then begin
   message, 'ERROR: ' + cmd + ': ' + res[1], /inf
   return, ''
endif

; Successful commands return strings in the format
; CMD: Response string
res = stregex(str, cmd+': (.*)', /subexpr, /extract)

; Check for invalid response
if strlen(res[0]) lt 1 then $
   return, ''

; Success
return, res[1]

end

;;;;;
;
; DGGhwIPGlaser::SetProperty
;
; Set properties of the IPG laser object
;
pro DGGhwIPGlaser::SetProperty, firmware = firmware, $
                                keyswitch = keyswitch, $
                                emission = emission, $
                                power = power, $
                                current = current, $
                                temperature = temperature, $
                                status = status, $
                                _ref_extra = re

COMPILE_OPT IDL2, HIDDEN

self->IDLitComponent::SetProperty, _extra = re

if n_elements(firmware) eq 1 then $
   message, 'cannot set firmware version', /inf

if n_elements(keyswitch) eq 1 then $
   message, 'keyswitch must be set manually', /inf

if n_elements(emission) eq 1 then $
   void = self.emission(emission)

if n_elements(power) eq 1 then $
   message, 'cannot specify output power directly; use current', /inf

if n_elements(current) eq 1 then $
   void = self.current(current)

if n_elements(temperature) eq 1 then $
   message, 'cannot set temperature', /inf

if n_elements(status) eq 1 then $
   message, 'cannot set status', /inf

end

;;;;;
;
; DGGhwIPGlaser::GetProperty
;
; Get properties of the IPG laser object
;
pro DGGhwIPGlaser::GetProperty, device = device, $
                                firmware = firmware, $
                                keyswitch = keyswitch, $
                                emission = emission, $
                                power = power, $
                                current = current, $
                                temperature = temperature, $
                                status = status, $
                                _ref_extra = re

COMPILE_OPT IDL2, HIDDEN

self->IDLitComponent::GetProperty, _extra = re

if arg_present(device) then $
   device = self.port.device

if arg_present(firmware) then $
   firmware = self.command('RFV')

if arg_present(keyswitch) then $
   keyswitch = self.keyswitch()

if arg_present(emission) then $
   emission = self.emission()

if arg_present(power) then $
   power = self.power()

if arg_present(current) then $
   current = self.current()

if arg_present(temperature) then $
   temperature = self.temperature()

if arg_present(status) then $
   status = self.status()

end

;;;;;
;
; DGGhwIPGlaser::Cleanup
;
; Free resources used by the IPG laser object
;
pro DGGhwIPGlaser::Cleanup

obj_destroy, self.port
end

;;;;;
;
; DGGhwIPGlaser::Init
;
; Initialize the IPG laser object
;
function DGGhwIPGlaser::Init, device, $
                              quiet = quiet

COMPILE_OPT IDL2, HIDDEN

if ~isa(device, 'STRING') then begin
   message, "Specify the RS232 device file for the IPG laser", /inf
   return, 0
endif

if (self->IDLitComponent::Init() ne 1) then $
   return, 0

; open serial port
port = DGGhwSerial(device)
if ~isa(port, 'DGGhwSerial') then $
   return, 0

; save present settings so that they can be restored
osettings = port.settings

; settings for IPG laser determined with minicom
; and recorded with stty -g
port.settings = ['0:0:18b1:0:3:1c:7f:15:4:0:1:0:11:13' + $
                 ':1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0']
port.eol = string(13b)

self.port = port

; check that this really is an IPG laser
res = self.command('RFV')
if strlen(res) le 1 then begin  ; if not ...
   if ~keyword_set(quiet) then $
   message, device + ' does not appear to be an IPG laser', /inf
   port.settings = osettings    ; restore port settings
   obj_destroy, self.port
   return, 0
end

self.name = 'DGGhwIPGlaser'
self.description = 'IPG Fiber Laser'
self->setpropertyattribute, 'NAME', /HIDE
self->registerproperty, 'device', /STRING, NAME = 'device', sensitive = 0
self->registerproperty, 'firmware', /STRING, NAME = 'firmware', sensitive = 0
self->registerproperty, 'keyswitch', /boolean, NAME = 'keyswitch', sensitive = 0
self->registerproperty, 'emission', /boolean, NAME = 'emission'
self->registerproperty, 'current', /FLOAT, NAME = 'current', $
                        VALID_RANGE = [10., 35., 0.1]
self->registerproperty, 'power', /FLOAT, NAME = 'power', sensitive = 0
self->registerproperty, 'temperature', /FLOAT, NAME = 'temperature', sensitive = 0
return, 1
end

;;;;;
;
; DGGhwIPGlaser__define
;
; Object definition for an IPG fiber laser
;
pro DGGhwIPGlaser__define

COMPILE_OPT IDL2

struct = {DGGhwIPGlaser,           $
          inherits IDL_Object,     $
          inherits IDLitComponent, $
          port: obj_new()          $
         }
end
