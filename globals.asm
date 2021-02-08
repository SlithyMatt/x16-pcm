.ifndef GLOBALS_INC
GLOBALS_INC = 1

.include "x16.inc"

; ------------ Constants ------------

; dedicated zero page pointers
SOUND_PTR = $3C

; --------- Global Variables ---------
aflow_trig: .byte 0
sound_bank: .byte 1

.endif
