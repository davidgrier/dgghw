;+
; NAME:
;    DGGhwShutter
;
; PURPOSE:
;    Object for interacting with a Thorlabs SC10 Shutter Controller
;
; USAGE:
;    a = DGGhwShutter(device)
;
; PROPERTIES:
;    DEVICE [IG ] name of the device character file to which the
;        shutter controller is attached
;
;    STATE  [IGS] state of the shutter 
;                 0: closed
;                 1: open
;    TOPEN  [IGS] time for shutter to remain open when triggered [ms]
;                 range: 1 ms to 999,999 ms
;    TSHUT  [IGS] time for shutter to remain shut when triggered [ms]
;                 range: 1 ms to 999,999 ms
;    MODE   [IGS] mode for triggered operation.
;                 0: manual mode: open and close shutter with STATE
;                 1: auto mode: repeatedly open and close shutter
;                 2: single mode: open and close shutter once
;                 3: repeat mode: open and close number of times set
;                                 by REP
;                 4: external gate mode
;    REP    [IGS] Number of repetitions in repeat mode (MODE = 3)
;                 range: [1, 99]
;    TRIG   [IGS] trigger mode
;                 0: internal trigger
;                 1: external trigger
;
; METHODS:
;    DGGhwShutter::GetProperty
;    DGGhwShutter::SetProperty
;
;    DGGhwShutter::Command(cmd)
;        Send string CMD to the shutter controller and return the result.
;
; INHERITS:
;    IDL_Object: permits implicity get and set methods
;    IDLitComponent: properties registered with PROPERTYSHEET widgets
;
; MODIFICATION HISTORY:
; 12/10/2011 Written by David G. Grier, New York University
; 12/11/2011 DGG Fixed IDLitComponent get and set methods.
; 05/03/2012 DGG updated parameter checking in Init and SetProperty
;
; Copyright (c) 2011-2012 David G. Grier
;-

;;;;;
;
; DGGhwShutter::Command()
;
; Send command to shutter controller and optionally return response
;
function DGGhwShutter::Command, cmd

COMPILE_OPT IDL2, HIDDEN

self.port.write, cmd
str = self.port.read()
if ~strcmp(str, cmd) then begin
   print, str
   return, ''
endif

str = self.port.read()

if ~strcmp(str, '> ') then begin
   res = self.port.read()
   return, strcmp(res, '> ') ? str : res
end

return, ''
end

;;;;;
;
; DGGhwShutter::SetProperty
;
; Set properties of the shutter controller object
;
pro DGGhwShutter::SetProperty, state = state, $
                               topen = topen, $
                               tshut = tshut, $
                               mode = mode,   $
                               rep =  rep,    $
                               trig = trig,   $
                               _ref_extra = re

COMPILE_OPT IDL2, HIDDEN

self->IDLitComponent::SetProperty, _extra = re

if n_elements(state) eq 1 then begin
   if self.command('ens?') ne keyword_set(state) then $
      void = self.command('ens')
endif

if isa(topen, /scalar, /number) then $
   void = self.command('open='+strtrim(topen, 2))

if isa(tshut, /scalar, /number) then $
   void = self.command('shut='+strtrim(tshut, 2))

if isa(mode, /scalar, /number) then $
   void = self.command('mode='+strtrim(mode+1, 2))

if isa(rep, /scalar, /number) then $
   void = self.command('rep='+strtrim(rep, 2))

if isa(trig, /scalar, /number) then $
   void = self.command('trig='+strtrim(trig, 2))

end

;;;;;
;
; DGGhwShutter::GetProperty
;
; Get properties of the shutter controller object
;
pro DGGhwShutter::GetProperty, device = device,   $
                               version = version, $
                               state = state,     $
                               topen = topen,     $
                               tshut = tshut,     $
                               mode = mode,       $
                               rep = rep,         $
                               trig = trig,       $
                               _ref_extra =  re
                             
COMPILE_OPT IDL2, HIDDEN

self->IDLitComponent::GetProperty, _extra = re

if arg_present(device) then $
   device = self.port.device

if arg_present(version) then $
   version = self.command('*idn?')

if arg_present(state) then $
   state = fix(self.command('ens?'))

if arg_present(topen) then $
   topen = float(self.command('open?'))

if arg_present(tshut) then $
   tshut = float(self.command('shut?'))

if arg_present(mode) then $
   mode = self.command('mode?') - 1

if arg_present(rep) then $
   rep = self.command('rep?')

if arg_present(trig) then $
   trig = self.command('trig?')

end

;;;;;
;
; DGGhwShutter::Cleanup
;
; Free resources used by the shutter controller object
;
pro DGGhwShutter::Cleanup

COMPILE_OPT IDL2, HIDDEN

obj_destroy, self.port

end

;;;;;
;
; DGGhwShutter::Init
;
; Initialize the shutter controller object
;
function DGGhwShutter::Init, device,        $
                             state = state, $
                             topen = topen, $
                             tshut = tshut, $
                             mode = mode,   $
                             rep = rep,     $
                             trig = trig,   $
                             quiet = quiet, $
                             _ref_extra = re

COMPILE_OPT IDL2, HIDDEN

if n_params() ne 1 then begin
   message, 'Specify the RS232 device file for the' + $
            'Thorlabs SC10 shutter controller', /inf
   return, 0
endif

if (self->IDLitComponent::Init(_extra = re) ne 1) then $
   return, 0

port = DGGhwSerial(device)
if ~isa(port, 'DGGhwSerial') then $
   return, 0

; save present settings so that they can be restored
osettings = port.settings

; settings for Thorlabs SC10 shutter controller determined with minicom
; and recorded with stty -g
port.settings = ['1:0:8bd:0:3:1c:7f:15:4:5:1:0:11:13' + $
                 ':1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0']
port.eol = string(13b)
port.timeout = 0.1
;port.debug = 1

self.port = port
; check that the device is a Thorlabs SC10
cmd = '*idn?'
self.port.write, cmd
str = self.port.read()
if strcmp(cmd, str) then begin
   void = self.port.read()
   void = self.port.read()
endif else begin
   if ~keyword_set(quiet) then $
   message, device + ' does not appear to be a Thorlabs SC10', /inf
   port.settings = osettings
   obj_destroy, self.port
   return, 0
endelse

if n_elements(state) eq 1 then $
   self.setproperty, state = keyword_set(state)

if isa(topen, /scalar, /number) then $
   self.setproperty, topen = float(topen)

if isa(tshut, /scalar, /number) then $
   self.setproperty, tshut = float(tshut)

if isa(mode, /scalar, /number) then $
   self.setproperty, mode = ((fix(mode)+1) > 1) < 5

if isa(rep, /scalar, /number) then $
   self.setproperty, rep = (fix(rep) > 1) < 99

if isa(trig, /scalar, /number) then $
   self.setproperty, trig = fix(trig) > 0 < 1

self.name = 'DGGhwShutter'
self.description = 'Thorlabs SC10'
self->setpropertyattribute, 'NAME', /HIDE
self->registerproperty, 'device', /STRING, NAME = 'device', SENSITIVE = 0
self->registerproperty, 'version', /STRING, NAME = 'version', SENSITIVE = 0
states = ['Open', 'Closed']
self->registerproperty, 'state', NAME = 'state', ENUM = states
self->registerproperty, 'topen', /FLOAT, NAME = 'Topen [ms]', $
                        VALID_RANGE = [1., 999999., 0.1]
self->registerproperty, 'tshut', /FLOAT, NAME = 'Tshut [ms]', $
                        VALID_RANGE = [1., 999999., 0.1]
modes = ['Manual', 'Auto', 'Single', 'Repeat', 'External']
self->registerproperty, 'mode', NAME = 'mode', ENUM = modes
self->registerproperty, 'rep', /INTEGER, NAME = 'repetitions', $
                        VALID_RANGE = [1, 99]
triggermodes = ['Internal', 'External']
self->registerproperty, 'trig', NAME = 'trigger', ENUM = triggermodes

return, 1
end

;;;;;
;
; DGGhwShutter_define
;
; Object definition for a Thorlabs SC10 shutter controller
;
pro DGGhwShutter__define

COMPILE_OPT IDL2

struct = {DGGhwShutter, $
          inherits IDL_Object, $
          inherits IDLitComponent, $
          port: obj_new() $
         }
end
