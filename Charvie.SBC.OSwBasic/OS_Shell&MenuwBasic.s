;*****************************************************
;*              OS_Shell & Menu w/BASIC              *
;*****************************************************

	.include "min_mon.6850.asm"
	.include "basic.asm"
	.include "ClearRAM32k.s
	.include "ILOAD32k.s"
	.include "KERNAL.s"
	.include "WOZMON.s"
	.include "InterruptHandler.s"

;CLRAM = $E9E0
;ILOAD = $EA00
;EhBasic = $EB00
;WOZMON  = $FF00 
;IRQ = $FFE0
                                                  
;*****************************************************
;*                  START OF CODE                    *
;*****************************************************
	.org $8000				; Start of the ROM (Needed for programming)

	.org $E900

STARTWM:					; $E000 entry point for 'warm start' or 
							; return from an app.
	jsr CLEARSCR
	
STARTCD:					; 'STARTCD' is used to ensure that startup messages 
							; are not erased on Power up or reset button
	ldx	#$ff
	txs

;*****************************************************
;*               Start of Main Code                  *
;*****************************************************

;-------Send a Startup Message to the Terminal---------

	lda #<mesg0			; set string low byte
	ldy #>mesg0			; set string high byte
	jsr PRTSTR			; print null terminated string
	jsr	NEWLINE
	
	lda #<mesg1			; set string low byte
	ldy #>mesg1			; set string high byte
	jsr PRTSTR			; print null terminated string
	jsr	NEWLINE

	lda #<mesg2			; set string low byte
	ldy #>mesg2			; set string high byte
	jsr PRTSTR			; print null terminated string
	jsr	NEWLINE

	lda #<mesg3			; set string low byte
	ldy #>mesg3			; set string high byte
	jsr PRTSTR			; print null terminated string
	jsr	NEWLINE

	lda #<mesg4			; set string low byte
	ldy #>mesg4			; set string high byte
	jsr PRTSTR			; print null terminated string
	jsr	NEWLINE

;----------------Wait for Input-----------------------
	jsr GETCHAR
	jsr UCASE
	cmp #'W'				;Is it a 'W'
	beq key1				;If yes=>branch
	cmp #'L'				;Is it a 'L'
	beq key2				;if yes=>branch
	cmp #'C'				;Is it a 'C'
	beq key3				;if yes=>branch
	cmp #'B'				;Is it a 'B'
	beq key4				;if yes=>branch

	jmp STARTWM			;No => go to 'warm start'

;------------------------------------------------------
key1:
	jmp WOZMON
key2:
	jmp LOAD
key3:
	jmp CLRAM 
key4:
	jmp EhBasic

mesg0: .asciiz "----MENU----"
mesg1: .asciiz " (W)OZMON" 
mesg2: .asciiz " (L)OAD"
mesg3: .asciiz " (C)LEAR RAM"
mesg4: .asciiz " (B)ASIC"

;*******************VICTORS*********************
	
	.org $fffc
	
	.word Reset
	.word IRQ






