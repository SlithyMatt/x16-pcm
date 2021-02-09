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
PCM_MODE 128,1,1,"maximum stereo         ","48.828 khz 16-bit stereo, max = 2.6 s  " ; A
PCM_MODE 128,1,0,"maximum mono           ","48.828 khz 16-bit mono, max = 5.3 s    " ; B
PCM_MODE 116,1,1,"'cd quality' stereo    ","44.250 khz 16-bit stereo, max = 2.9 s  " ; C
PCM_MODE 116,1,0,"'cd quality' mono      ","44.250 khz 16-bit mono, max = 5.8 s    "
PCM_MODE  64,1,1,"half-freq stereo       ","24.414 khz 16-bit stereo, max = 5.3 s  "
PCM_MODE  64,1,0,"half-freq mono         ","24.414 khz 16-bit mono, max = 10.6 s   "
PCM_MODE 128,0,1,"maximum 8-bit stereo   ","48.828 khz 8-bit stereo, max = 5.3 s   "
PCM_MODE 128,0,0,"maximum 8-bit mono     ","48.828 khz 8-bit mono, max = 10.6 s    "
PCM_MODE  64,0,1,"half-freq 8-bit stereo ","24.414 khz 8-bit stereo, max = 10.6 s  "
PCM_MODE  64,0,0,"half-freq 8-bit mono   ","24.414 khz 8-bit mono, max = 21.1 s    "
PCM_MODE  32,1,1,"quarter-freq stereo    ","12.207 khz 16-bit stereo, max = 10.6 s "
PCM_MODE  32,1,0,"quarter-freq mono      ","12.207 khz 16-bit mono, max = 21.1 s   "
PCM_MODE  32,0,1,"qtr-freq 8-bit stereo  ","12.207 khz 8-bit stereo, max = 21.1 s  "
PCM_MODE  32,0,0,"qtr-freq 8-bit mono    ","12.207 khz 8-bit mono, max = 42.3 s    "
PCM_MODE  21,1,0,"speech-quality mono    ","8.011 khz 16-bit mono, max = 32.2 s    "
PCM_MODE  21,0,0,"phone-quality mono     ","8.011 khz 8-bit mono, max = 64.4 s     "
PCM_MODE  12,1,0,"effects-quality mono   ","4.578 khz 16-bit mono, max = 56.4 s    "
PCM_MODE  12,0,0,"fx-quality 8-bit (XCI) ","4.578 khz 8-bit mono, max = 112.7 s    "
PCM_MODE   2,1,1,"whole pop song stereo  ","763 hz 16-bit stereo, max = 169.1 s    "
PCM_MODE   4,1,0,"whole pop song mono    ","1.526 khz 16-bit mono, max = 169.1 s   "
PCM_MODE   4,0,1,"whole song 8-bit stereo","1.526 khz 8-bit stereo, max = 169.1 s  "
PCM_MODE   8,0,0,"whole song 8-bit mono  ","3.052 khz 8-bit mono, max = 169.1 s    "
PCM_MODE   1,1,1,"minimum stereo         ","381 hz 16-bit stereo, max = 338.2 s    "
PCM_MODE   1,1,0,"minimum mono           ","381 hz 16-bit mono, max = 676.5 s      " ; X
PCM_MODE   1,0,1,"minimum 8-bit stereo   ","381 hz 8-bit stereo, max = 676.5 s     " ; Y
PCM_MODE   1,0,0,"minimum 8-bit mono     ","381 hz 8-bit mono, max = 1352.9 s      " ; Z


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
