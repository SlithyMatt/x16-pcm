.ifndef IRQ_INC
IRQ_INC = 1

.include "globals.asm"

def_irq: .word $0000

init_irq:
   sei
   lda IRQVec
   sta def_irq
   lda IRQVec+1
   sta def_irq+1
   lda #<handle_irq
   sta IRQVec
   lda #>handle_irq
   sta IRQVec+1
   cli
   rts

restore_irq:
   sei
   lda def_irq
   sta IRQVec
   lda def_irq+1
   sta IRQVec+1
   cli
   rts

handle_irq:

   ; check for AFLOW
   lda VERA_isr
   and #$08
   beq @done_aflow
   sta aflow_trig
@done_aflow:

   ; TODO check other IRQs

   jmp (def_irq)




.endif
