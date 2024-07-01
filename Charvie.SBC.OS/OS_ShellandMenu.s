;*****************************************************
;*                OS_Shell and Menu                  *
;*****************************************************

	.include "KERNAL.s"
	.include "WOZMON.s"
	.include "ILOAD16k.s"
	.include "ClearRAM16k.s"
	.include "InterruptHandler.s"

;MENU = $E000
;CLRAM = $E0E0
;ILOAD = $E100
;WOZMON = $FF00
;IRQ = $FFE0

;*****************************************************
;*                  START OF CODE                    *
;*****************************************************

;	.org $8000				; Start of the ROM (Needed for
;							; programming a 32K ROM)

;****************************************************

	.org $E000

MENU:

STARTWM:					; $E000 entry point for 'warm start' or 
							; return from an app.

;-------Send a Startup Message to the Terminal---------
	jsr CLEARSCR			; Clears the screen

STARTCD:					; 'STARTCD' is used to ensure that startup messages 
							; are not erased on Power up or reset button

	lda #<mesg0				; set string low byte
	ldy #>mesg0				; set string high byte
	jsr PRTSTR				; print null terminated string
	jsr	NEWLINE

	lda #<mesg1				; set string low byte
	ldy #>mesg1				; set string high byte
	jsr PRTSTR				; print null terminated string
	jsr	NEWLINE

	lda #<mesg2				; set string low byte
	ldy #>mesg2				; set string high byte
	jsr PRTSTR				; print null terminated string
	jsr	NEWLINE

	lda #<mesg3				; set string low byte
	ldy #>mesg3				; set string high byte
	jsr PRTSTR				; print null terminated string
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

	jmp STARTWM				;No => go to 'warm start'

;------------------------------------------------------
key1:
	jmp WOZMON
key2:
	jmp LOAD
key3:
	jmp CLRAM

mesg0: .asciiz "----MENU----"
mesg1: .asciiz " (W)OZMON" 
mesg2: .asciiz " (L)OAD"
mesg3: .asciiz " (C)LEAR RAM"

;*******************VECTORS*********************
	
	.org $fffc
	
	.word Reset
	.word IRQ

