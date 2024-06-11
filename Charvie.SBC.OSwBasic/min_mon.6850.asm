;****************************************
;* minimal monitor for EhBASIC and 6502 *
;****************************************

; put the IRQ and MNI code in RAM so that it can be changed

IRQ_vec	= VEC_SV+2		; IRQ code vector
NMI_vec	= IRQ_vec+$0A	; NMI code vector


; Now the code. all this does is set up the vectors
; and interrupt code and jump to ehbasic start.
;***********************************************

	.org	$EB00			; pretend this is in a 1/8K ROM

EhBasic:					; entry point

; reset vector points here
RES_vec
	cld						; clear decimal mode
	ldx	#$FF				; empty stack
	txs						; set the stack
	
;----------------------------------------------------
;   setup vectors & interrupt code, copy to page2 
;----------------------------------------------------
	ldy	#END_CODE-LAB_vec	; set index/count
LAB_stlp
	lda	LAB_vec-1,Y			; get byte from interrupt code
	sta	VEC_IN-1,Y			; save to RAM
	dey						; decrement index/count
	bne	LAB_stlp			; loop if more to do

;----------------- Start EhBasic ----------------------
LAB_signon
	jmp	LAB_COLD

;--------Send a character to the terminal--------------
ACIAout:
	jsr TXCHAR
	rts

;--------Wait for character from the terminal---------
ACIAin
	lda ACIA_CnSt				; Check if receive data register is full
	and #$01					; If this bit is set data register is full
	beq LAB_nobyw				; branch if no byte waiting

	lda ACIA_TxRx				; load data from register
	sec
	rts

LAB_nobyw
	clc							; flag no byte received
	rts

;--------------- vector tables ----------------------
LAB_vec
	.word	ACIAin				; byte in from ACIA
	.word	ACIAout				; byte out to ACIA

;------------- EhBASIC IRQ support ------------------
IRQ_CODE
	pha						; save A
	lda	IrqBase				; get the IRQ flag byte
	lsr						; shift the set b7 to b6, and on down ...
	ora	IrqBase				; OR the original back in
	sta	IrqBase				; save the new IRQ flag byte
	pla						; restore A
	rti

;------------- EhBASIC NMI support ------------------
NMI_CODE
	pha						; save A
	lda	NmiBase				; get the NMI flag byte
	lsr						; shift the set b7 to b6, and on down ...
	ora	NmiBase				; OR the original back in
	sta	NmiBase				; save the new NMI flag byte
	pla						; restore A
	rti

END_CODE




