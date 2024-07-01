;*************************************************************
;                        Interrupt Handler
; As written, when an IRQ occurs the 'cpu' will jump here, 
; then jump to the vector location stored in $0314 & $0315.
; IF those locations have not been changed since powerup or 
; a reset, the vector points to the 'rti' instruction here.
;*************************************************************

	.org $FFE0

IRQ:
	jmp (IRQ_VEC)			; This is memory address $FFE0
						; loaded in to memory at powerup or a reset
						; If you change the address @ $0314 & $0315 you 
						; can relocate an IRQ handler where ever you want.
	rti
