;+
; NAME:
;    DGGhwViper
;
; PURPOSE:
;    Control an iFlex Viper laser with an AIOUSB D/A converter.
;
; PROPERTIES:
;    v640: power of 640 nm laser line in range 0 .. 1
;    v561: power of 561 nm laser line in range 0 .. 1
;    v488: power of 488 nm laser line in range 0 .. 1
;    v455: power of 455 nm laser line in range 0 .. 1
;    v405: power of 405 nm laser line in range 0 .. 1
;
; METHODS:
;    DGGhwViper::SetProperty
;    DGGhwViper::GetProperty
;
; Inherits IDL_Object so that get and set operations can be performed
; implicitly.
;
; Inherits IDLitComponent so that registered values may be set with
; a property sheet.
;
; MODIFICATION HISTORY:
; 12/05/2011 Written by David G. Grier, New York University
;
; Copyright (c) 2011, David G. Grier
;-
;;;;;
;
; DGGhwViper::Value
;
; Scale values so that the AIOUSB D/A converter
; outputs the correct range for the iFlex Viper.
;
function DGGhwViper::Value, v

COMPILE_OPT IDL2, HIDDEN

return, v/2. + 0.5
end

;;;;;
;
; DGGhwViper::GetProperty
;
pro DGGhwViper::GetProperty, v640 = v640, $
                             v561 = v561, $
                             v488 = v488, $
                             v455 = v455, $
                             v405 = v405, $
                             _ref_extra = re

COMPILE_OPT IDL2, HIDDEN

v640 = self.v640
v561 = self.v561
v488 = self.v488
v455 = self.v455
v405 = self.v405

self->IDLitComponent::GetProperty, _extra = re
end

;;;;;
;
; DGGhwViper::SetProperty
;
pro DGGhwViper::SetProperty, v640 = v640, $
                             v561 = v561, $
                             v488 = v488, $
                             v455 = v455, $
                             v405 = v405, $
                             _ref_extra = re

COMPILE_OPT IDL2, HIDDEN

if arg_present(v640) then begin
   void = viper_setvalue(*self.device, self.c640, self.value(v640))
   self.v640 = v640
endif
if arg_present(v561) then begin
   void = viper_setvalue(*self.device, self.c561, self.value(v561))
   self.v561 = v561
endif
if arg_present(v488) then begin
   void = viper_setvalue(*self.device, self.c488, self.value(v488))
   self.v488 = v488
endif
if arg_present(v455) then begin
   void = viper_setvalue(*self.device, self.c455, self.value(v455))
   self.v455 = v455
endif
if arg_present(v405) then begin
   void = viper_setvalue(*self.device, self.c405, self.value(v405))
   self.v405 = v405
endif

self->IDLitComponent::SetProperty, _extra = re
end

;;;;;
;
; DGGhwViper::Cleanup
;
pro DGGhwViper::Cleanup

COMPILE_OPT IDL2, HIDDEN

ptr_free, self.device
viper_close
end

;;;;;
;
; DGGhwViper::Init
;
; Initialize AIOUSB system to control the iFlex Viper laser
;
function DGGhwViper::Init, _ref_extra = re

COMPILE_OPT IDL2, HIDDEN

catch, error
if (error ne 0L) then begin
   catch, /cancel
   return, 0
endif

if (self->IDLitComponent::Init(_extra = re) ne 1) then $
   return, 0

s = viper_open()
if ~isa(s, 'AIOUSB_DEVICE') then $
   return, 0

self.device = ptr_new(s, /no_copy)

self.c640 = 1
self.c561 = 2
self.c488 = 0
self.c455 = 3
self.c405 = 4

for c = 0, 4 do $
   void = viper_setvalue(*self.device, c, self.value(0))

self.name = 'DGGhwViper'
self.description = 'iFlex Viper'
self->setpropertyattribute, 'NAME', /HIDE

self->registerproperty, 'v640', /FLOAT, NAME = 'v640', $
                        VALID_RANGE = [0., 1., 0.01]
self->registerproperty, 'v561', /FLOAT, NAME = 'v561', $
                        VALID_RANGE = [0., 1., 0.01]
self->registerproperty, 'v488', /FLOAT, NAME = 'v488', $
                        VALID_RANGE = [0., 1., 0.01]
self->registerproperty, 'v455', /FLOAT, NAME = 'v455', $
                        VALID_RANGE = [0., 1., 0.01]
self->registerproperty, 'v405', /FLOAT, NAME = 'v405', $
                        VALID_RANGE = [0., 1., 0.01]

return, 1
end
   
;;;;;
;
; DGGhwViper__define
;
; Define an object abstracting an iFlex Viper laser
;
pro DGGhwViper__define

COMPILE_OPT IDL2

struct = {DGGhwViper,              $
          inherits IDL_Object,     $
          inherits IDLitComponent, $
          device: ptr_new(),       $
          c640: 1L,                $
          c561: 2L,                $
          c488: 0L,                $
          c455: 3L,                $
          c405: 4L,                $
          v640: 0.,                $
          v561: 0.,                $
          v488: 0.,                $
          v455: 0.,                $
          v405: 0.                 $
         }
end
