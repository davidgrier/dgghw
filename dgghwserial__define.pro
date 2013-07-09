;+
; NAME:
;    DGGhwSerial
;
; PURPOSE:
;    Object for interacting with an RS-232 port
;
; PROPERTIES:
;    device:   (IG ) name of the device character file, such as /dev/ttyUSB0
;    lun:      ( G ) logical unit number of the port's IDL device
;    timeout:  (IGS) timeout for reads (seconds)
;    settings: (IGS) command-line arguments for stty as an array of strings
;        EXAMPLE: 9600 baud, 8N1:
;        ['9600', '-cstopb', '-parity']
;
; KEYWORD FLAG:
;    debug:    (IGS) if set, print all input and output activity to stdout
;    
; METHODS:
;    DGGhwSerial::GetProperty
;    DGGhwSerial::SetProperty
;
;    DGGhwSerial::Write, str
;        Write string str to the serial device, terminated with the
;        eol character.
;
;    DGGhwSerial::Read([err = err])
;        Read characters from the serial device until the eol
;        character is encountered, or an error occurs.  Return
;        the result as a string.
;        KEYWORD FLAG:
;            ERR: Set on output if an error (timeout) occurred during reading
;
; NOTES:
;    Can the eol character be rolled into an stty setting?
;
; MODIFICATION HISTORY:
; 06/23/2011 Written by David G. Grier, New York University
; 12/03/2011 DGG port settings returned with stty -g so that the
;    settings can be set with a subsequent call to setproperty.
;    Added DEBUG keyword.
; 02/02/2012 DGG stty incorrectly reports an error:
;    unable to perform all requested operations
;    for all regular users.  Commented out error check.  Sigh.
; 05/03/2012 DGG updated parameter checking in Init and SetPropert
; 07/08/2013 DGG added ERR keyword to Read().
;
; Copyright (c) 2011-2013 David G. Grier
;
;-

;;;;;
;
; DGGhwSerial::Read()
;
; Read a string from the serial device
;
function DGGhwSerial::Read, err = err

COMPILE_OPT IDL2, HIDDEN

str = ''
c = 'a'
err = 0
repeat begin
   if ~file_poll_input(self.lun, timeout = self.timeout) then begin
      err = 1
      break
   endif
   readu, self.lun, c, transfer_count = nbytes 
   if nbytes ne 1 then break
   if self.debug then print, c, byte(c)
   if c ne self.eol then $
      str += string(c)
endrep until c eq self.eol

return, str
end

;;;;;
;
; DGGhwSerial::Write
;
; Write a string to the serial device
;
pro DGGhwSerial::Write, str

COMPILE_OPT IDL2, HIDDEN

if self.debug then print, str
writeu, self.lun, str + self.eol
flush, self.lun

end

;;;;;
;
; DGGhwSerial::SetProperty
;
; Set properties of the DGGhwSerial object
;
pro DGGhwSerial::SetProperty, device = device, $
                              lun = lun, $
                              settings = settings, $
                              eol = eol, $
                              timeout = timeout, $
                              debug = debug

COMPILE_OPT IDL2, HIDDEN

if arg_present(device) then $
   message, 'cannot change device file name', /inf

if arg_present(lun) then $
   message, "cannot change device's logical unit number", /inf

if isa(settings, 'string') then begin
   cmd = ['stty', '-F', self.device, settings]
   spawn, cmd, /noshell, res, /stderr, exit_status = err
;   if (err ne 0) then $
;      message, 'could not set serial port properties:' + $
;               strtrim(err, 2), /inf
endif

if n_elements(eol) eq 1 then $
   self.eol = eol

if isa(timeout, /number) then $
   self.timeout = double(timeout)

if n_elements(debug) eq 1 then $
   self.debug = keyword_set(debug)

end

;;;;;
;
; DGGhwSerial::GetProperty
;
; Get properties of the DGGhwSerial object
;
pro DGGhwSerial::GetProperty, device = device, $
                              lun = lun, $
                              eol = eol, $
                              timeout = timeout, $
                              settings = settings, $
                              debug = debug

if arg_present(device) then $
   device = self.device

if arg_present(lun) then $
   lun = self.lun

if arg_present(eol) then $
   eol = self.eol

if arg_present(timeout) then $
   timeout = self.timeout

if arg_present(settings) then begin
   cmd = ['stty', '-g', '-F', self.device]
   spawn, cmd, /noshell, res, /stderr, exit_status = err
   if (err ne 0) then $
      message, 'could not get serial port properties', /inf
   settings = res
endif

if arg_present(debug) then $
   debug = self.debug

end

;;;;;
;
; DGGhwSerial::Cleanup
;
; Free resources used by the DGGhwSerial object
;
pro DGGhwSerial::Cleanup

close, self.lun
free_lun, self.lun
end

;;;;;
;
; DGGhwSerial::Init
;
; Initialize the DGGhwSerial object
;
function DGGhwSerial::Init, device, $
                            settings = settings, $
                            eol = eol, $
                            timeout = timeout

COMPILE_OPT IDL2, HIDDEN

if n_params() ne 1 then begin
   message, "Specify the RS232 device file", /inf
   return, 0
endif

if ~file_test(device, /read, /write, /character_special) then begin
   message, device + ' is not an accessible serial port', /inf
   return, 0
endif

if isa(settings, 'string') then begin
   cmd = ['stty', '-F', device, settings]
   spawn, cmd, /noshell, res, /stderr, exit_status = err
;   if (err ne 0) then begin
;      message, 'could not set serial port properties', /inf
;      return, 0
;   endif
endif

openw, lun, device, /get_lun, /rawio, error = err
if (err ne 0) then begin
   message, !ERROR_STATE.MSG, /inf
   return, 0
endif

s = fstat(lun)
if ~s.open or ~s.isatty or ~s.read or ~s.write then begin
   message, "cannot access " + device, /inf
   close, lun
   free_lun, lun
   return, 0
endif

if n_elements(eol) eq 1 then $
   self.eol = eol

if isa(timeout, /number) then $
   self.timeout = double(timeout) $
else $
   self.timeout = 0.1d

self.device = device
self.lun = lun

return, 1
end

;;;;;
;
; DGGhwSerial_define
;
; Object definition for a serial port
;
pro DGGhwSerial__define

COMPILE_OPT IDL2

struct = {DGGhwSerial, $
          inherits IDL_Object, $
          device: '',          $ ; name of character device
          lun: 0,              $ ; logical unit number
          eol: '',             $ ; end of line character
          timeout: 0.1d,       $ ; maximum time to wait for read (sec)
          debug: 0             $ ; flag to turn on communications debugging
         }
end
