;+
; NAME:
;    DGGhwThermometer
;
; PURPOSE:
;    Object for interacting with a Omega DP472 temperature logger
;
; USAGE:
;    a = DGGhwThermometer(device)
;
; PROPERTIES:
;    DEVICE [IG ] name of the device character file to which the
;        thermometer is attached
;    TEMPERATURE [ G ] Current temperature
;    CHANNEL     [ G ] Current channel
;    UPDATE      [IGS] Interval between internal updates 
;
; METHODS:
;    DGGhwThermometer::GetProperty
;    DGGhwThermometer::SetProperty
;
;    DGGhwThermometer::Command(cmd)
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
; 03/04/2015 DGG adapted for Omega DP472 temperature logger
;
; Copyright (c) 2011-2015 David G. Grier
;-

;;;;;
;
; DGGhwThermometer::Command()
;
; Send command to thermometer and return any response
;
function DGGhwThermometer::Command, cmd

  COMPILE_OPT IDL2, HIDDEN

  self.command, cmd
  return, self.port.read()
end

;;;;;
;
; DGGhwThermometer::Command
;
; Send command to thermometer
;
pro DGGhwThermometer::Command, cmd

  COMPILE_OPT IDL2, HIDDEN

  self.port.write, cmd
end

;;;;;
;
; DGGhwThermometer::handleTimerEvent
;
pro DGGhwThermometer::handleTimerEvent, id, userdata

  COMPILE_OPT IDL2, HIDDEN

  if self.update gt 0 then $
     self.timer = timer.set(self.update, self)
   a = self.command('64'x)
;  self._temperature = float(a.substring(24,29))
end

;;;;;
;
; DGGhwThermometer::NextChannel
;
pro DGGhwThermometer::NextChannel

  COMPILE_OPT IDL2, HIDDEN

  self.command, '58'x
end

;;;;;
;
; DGGhwThermometer::SetProperty
;
; Set properties of the temperature logger
;
pro DGGhwThermometer::SetProperty, update = update, $
                                   _ref_extra = re

  COMPILE_OPT IDL2, HIDDEN
  
  if isa(update, /number, /scalar) then begin
     if update gt 0 then begin
        self.update = float(update)
        self.timer = timer.set(self.update, self)
     endif else begin
        void = timer.cancel(self.timer)
        self.update = 0.
     endelse
  endif

  self->IDLitComponent::SetProperty, _extra = re
end

;;;;;
;
; DGGhwThermometer::GetProperty
;
; Get properties of the thermometer
;
pro DGGhwThermometer::GetProperty, device = device,   $
                                   temperature = temperature, $
                                   channel = channel, $
                                   update = update, $
                                   _ref_extra =  re
                             
  COMPILE_OPT IDL2, HIDDEN

  self->IDLitComponent::GetProperty, _extra = re

  if arg_present(device) then $
     device = self.port.device

  if arg_present(temperature) then begin
     if (self.update le 0) then begin
        a = self.command('64'x)
        self._temperature = float(a.substring(24,29))
     endif
     temperature = self._temperature
  endif

  if arg_present(channel) then begin
     a = self.command('64'x)
     channel = long(a.substring(3,3))
  endif

  if arg_present(update) then $
     update = self.update
end

;;;;;
;
; DGGhwThermometer::Cleanup
;
; Free resources used by the temperature logger
;
pro DGGhwThermometer::Cleanup

  COMPILE_OPT IDL2, HIDDEN
  
  obj_destroy, self.port
end

;;;;;
;
; DGGhwThermometer::Init
;
; Initialize the temperature logger
;
function DGGhwThermometer::Init, device,        $
                                 update = update, $
                                 _ref_extra = re

  COMPILE_OPT IDL2, HIDDEN

  if n_params() ne 1 then begin
     message, 'Specify the RS232 device file for the ' + $
              'Omega DP472 temperature logger', /inf
     return, 0
  endif
  
  if (self->IDLitComponent::Init(_extra = re) ne 1) then $
     return, 0

  port = DGGhwSerial(device)
  if ~isa(port, 'DGGhwSerial') then $
     return, 0

  ;; save present settings so that they can be restored
  osettings = port.settings

  port.settings = ['1:0:8bd:0:3:1c:7f:15:4:5:1:0:11:13' + $
                   ':1a:0:12:f:17:16:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0']
  port.eol = string(0)
  port.timeout = 0.1

  self.port = port

  if (self.command('59'x) ne 'Y') then begin
     message, 'Device on '+self.port+ $
              ' does not appear to be an Omega DP472', /inf
     return, 0
  end

  if isa(update, /number, /scalar) && (update gt 0) then begin
     self.update = float(update)
     self.timer = timer.set(self.update, self)
  endif

  self.name = 'DGGhwThermometer'
  self.description = 'Omega DP472'
  self->setpropertyattribute, 'NAME', /HIDE
  self->registerproperty, 'device', /STRING, NAME = 'device', SENSITIVE = 0
  self -> registerproperty, 'update', /FLOAT, NAME = 'update'
  
  return, 1
end

;;;;;
;
; DGGhwThermometer__define
;
; Object definition for an Omega DP472 temperature logger
;
pro DGGhwThermometer__define

  COMPILE_OPT IDL2
  
  struct = {DGGhwThermometer,        $
            inherits IDL_Object,     $
            inherits IDLitComponent, $
            port        : obj_new(), $
            _temperature: 0.,        $
            update      : 0.,        $
            timer       : 0L         $
           }
end
