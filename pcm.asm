.include "x16.inc"

.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"
   jmp start

.include "irq.asm"
.include "globals.asm"

.macro PCM_MODE rate, sixteen, stereo, name, stats
   .byte rate
   .byte (sixteen << 5) | (stereo << 4)
   .byte name
   .byte stats
.endmacro

pcm_modes:
PCM_MODE 128,1,1,"Maximum Stereo         ","48.828 kHz 16-Bit Stereo, Max = 2.6 s  "

start:

   ; clear display
   lda #$0D
   jsr CHROUT

   ; set display to 2x scale
   lda #64
   sta VERA_dc_hscale
   sta VERA_dc_vscale

   ; init globals
   lda #<RAM_WIN
   sta SOUND_PTR
   lda #>RAM_WIN
   sta SOUND_PTR+1
   stz aflow_trig
   lda #1
   sta sound_bank

   jsr init_irq

mainloop:
   wai
   lda aflow_trig
   bne mainloop

   ; TODO fill FIFO

   ; TODO check for input

   ; Restore IRQ vector
   jsr restore_irq
   rts
