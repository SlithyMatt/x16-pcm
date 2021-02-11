.include "x16.inc"

STOP_KEY = $03
RETURN = $0D
SPACE = $20
COLON = $3A
CHAR_A = $41
CHAR_Z = $5A
CLR = $93

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
   .byte $8F | (sixteen << 5) | (stereo << 4)
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
PCM_MODE  12,0,0,"fx-quality 8-bit (xci) ","4.578 khz 8-bit mono, max = 112.7 s    "
PCM_MODE   2,1,1,"whole pop song stereo  ","763 hz 16-bit stereo, max = 169.1 s    "
PCM_MODE   4,1,0,"whole pop song mono    ","1.526 khz 16-bit mono, max = 169.1 s   "
PCM_MODE   4,0,1,"whole song 8-bit stereo","1.526 khz 8-bit stereo, max = 169.1 s  "
PCM_MODE   8,0,0,"whole song 8-bit mono  ","3.052 khz 8-bit mono, max = 169.1 s    "
PCM_MODE   1,1,1,"minimum stereo         ","381 hz 16-bit stereo, max = 338.2 s    "
PCM_MODE   1,1,0,"minimum mono           ","381 hz 16-bit mono, max = 676.5 s      " ; X
PCM_MODE   1,0,1,"minimum 8-bit stereo   ","381 hz 8-bit stereo, max = 676.5 s     " ; Y
PCM_MODE   1,0,0,"minimum 8-bit mono     ","381 hz 8-bit mono, max = 1352.9 s      " ; Z

filename: .byte "0.bin"
FILENAME_LENGTH = 5

guide1:
.byte " 'persona' by severah [creative commons]",RETURN,RETURN
.byte " press any letter key (a-z) to play",RETURN
.byte " back the song at different sample", RETURN
.byte " rates, bit depths and in stereo or", RETURN
.byte " mono. the 'max' time listed for each",RETURN
.byte " encoding is how much pcm data can fit",RETURN,0
guide2:
.byte " in 504 kb of free banked ram on the",RETURN
.byte " x16. the song will play until the",RETURN
.byte " 504 kb is exhausted, the track is",RETURN
.byte " done, or another encoding is selected.",RETURN,RETURN
.byte " press stop or ctrl+c to quit.",0

start:

   ; clear display
   lda #CLR
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
   lda #$30 ; '0'
   sta filename

   ; print guide
   ldx #4
   ldy #0
   clc
   jsr PLOT
   ldx #0
@print_guide1:
   lda guide1,x
   beq @done_guide1
   jsr CHROUT
   inx
   bra @print_guide1
@done_guide1:
   ldx #0
@print_guide2:
   lda guide2,x
   beq @done_guide2
   jsr CHROUT
   inx
   bra @print_guide2
@done_guide2:

   jsr init_irq

@flush:
   jsr GETIN
   cmp #0
   bne @flush

mainloop:
   wai
   jsr GETIN
   cmp #STOP_KEY
   beq @quit
   cmp #CHAR_A
   bmi @check_aflow
   cmp #(CHAR_Z + 1)
   bpl @check_aflow
   jsr load
   bra mainloop
@check_aflow:
   lda aflow_trig
   beq mainloop
   jsr fill
   bra mainloop
@quit:
   ; Restore IRQ vector
   jsr restore_irq
   rts

load:
   sta filename
   sec
   sbc #CHAR_A ; 'A' -> 0
   stz ZP_PTR_1+1
   asl
   asl
   asl
   asl
   rol ZP_PTR_1+1
   asl
   rol ZP_PTR_1+1
   asl
   rol ZP_PTR_1+1 ; * 64
   clc
   adc #<pcm_modes
   sta ZP_PTR_1
   lda ZP_PTR_1+1
   adc #>pcm_modes
   sta ZP_PTR_1+1 ; ZP_PTR_1 = PCM mode structure
   stz VERA_audio_rate
   ldy #1
   lda (ZP_PTR_1),y
   sta VERA_audio_ctrl ; flush FIFO and reconfigure PCM
   ldx #1
   clc
   jsr PLOT
   lda filename
   jsr CHROUT
   lda #COLON
   jsr CHROUT
   lda #SPACE
   jsr CHROUT
   ldy #2
@name_loop:
   lda (ZP_PTR_1),y
   jsr CHROUT
   iny
   cpy #25
   bne @name_loop
   lda #RETURN
   jsr CHROUT
   lda #SPACE
   jsr CHROUT
@stats_loop:
   lda (ZP_PTR_1),y
   jsr CHROUT
   iny
   cpy #64
   bne @stats_loop
; load file
   lda #1
   ldx #8
   ldy #0
   jsr SETLFS
   lda #FILENAME_LENGTH
   ldx #<filename
   ldy #>filename
   jsr SETNAM
   lda #1
   sta RAM_BANK
   sta sound_bank
   lda #0
   ldx #<RAM_WIN
   stx SOUND_PTR ; zero
   ldy #>RAM_WIN
   sty SOUND_PTR+1
   jsr LOAD
   lda RAM_BANK
   sta end_bank
   stx end_addr
   sty end_addr+1
   jsr fill
   lda (ZP_PTR_1)
   sta VERA_audio_rate ; Set new sample rate to start playing
   rts

fill:
   stz aflow_trig
   lda sound_bank
   cmp end_bank
   bne @start_fill
   lda SOUND_PTR
   cmp end_addr
   bne @start_fill
   lda SOUND_PTR+1
   cmp end_addr+1
   bne @start_fill
   jmp @return
@start_fill:
   lda sound_bank
   sta RAM_BANK
   cmp end_bank
   bne @load_2k
   lda end_addr+1
   sec
   sbc SOUND_PTR+1
   cmp #8
   bpl @load_2k
   tax
   ldy #0
@partial:
   lda (SOUND_PTR),y
   sta VERA_audio_data
   cpx #0
   bne @next_partial
   cpy end_addr
   beq @return
@next_partial:
   iny
   bne @partial
   dex
   inc SOUND_PTR+1
   bra @partial
@load_2k:
   ldx #7
   ldy #0
@loop_2k:
   lda (SOUND_PTR),y
   sta VERA_audio_data
   iny
   bne @loop_2k
   inc SOUND_PTR+1
   cpx #0
   beq @next_bank
   dex
   bra @loop_2k
@next_bank:
   lda SOUND_PTR+1
   cmp #>ROM_WIN
   bne @return
   inc sound_bank
   lda #>RAM_WIN
   sta SOUND_PTR+1
@return:
   rts
