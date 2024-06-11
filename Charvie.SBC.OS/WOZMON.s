;*****************************************************
;*                  WOZMON.290524                    *
;*****************************************************

;+---------------------------------------------------+
;|              Zero Page Varables                   |
;+---------------------------------------------------+
XAML  = $23       ; Last "opened" location Low       
XAMH  = $24       ; Last "opened" location High      
STL   = $25       ; Store address Low                
STH   = $26       ; Store address High               
L     = $27       ; Hex value parsing Low            
H     = $28       ; Hex value parsing High           
YSAV  = $29       ; Used to see if hex value is given
MODE  = $2A       ; $00=XAM, $7F=STOR, $AE=BLOCK XAM 
;                                                     
IN	= $0200        ;Input text buffer                 
;*****************************************************

	.org $FF00

WOZMON:
	cld						; Clear decimal arithmetic mode
	cli						; Clear interrupts
	ldy #$7f				;needed to make code work on reset

notcr:
	cmp #$08				;backspace key??
	beq backspace			;branch if 'yes'
	cmp #$1b				;'esc'??
	beq escape				;branch if 'yes'
	iny						;advance text index.
	bpl nextchar			;auto ESC if line longer than 127

escape:
	jsr CLEARSCR			; 'CLEARSCR' sub-routine in bootup code
	lda #$5c				;'\'
	jsr TXCHAR

getline:
	jsr NEWLINE

	ldy #$01				;Init text index
backspace:
	dey						;backup text index
	bmi getline				;beyond start of line, reinit

nextchar:
	jsr GETCHAR				; Go get a character from ACIA
	jsr UCASE				; Make sure it is upper case
    jsr TXCHAR				; Echo back to terminal
	sta IN,y				; Add to text buffer
	cmp #$0d				; 'CR'??
	bne notcr				; NO

	ldy #$ff				;Reset text index
	lda #$00				;For XAM mode
	tax						;'x' register = '0'

setblock:
	asl

setstor:
	asl						; Leaves $7b if setting STOR mode
	sta MODE				; $00 = XAM, $74 = STOR, $b8 = BLOK XAM

blskip:
	iny						; Advance text index

nextitem:
	lda IN,y				; Get character
	cmp #$0d				; 'CR'??
	beq getline				; If 'yes' then new line
	cmp #$2e				; ','??
	bcc blskip				; Skip delimiter
	beq setblock			; Set BLOCK XAM mode
	cmp #$3a				; ':'??
	beq setstor				; If 'yes' then set STOR mode
	cmp #$52				; 'R'??
	beq run					; If 'yes' then run user program
	stx L					; $00 -> L
	stx H					; also -> H
	sty YSAV				; Save 'y' register for comparison
 
nexthex:
	lda IN,y				; Get character for hex test
	eor #$30				; Map digits to $0 to $9
	cmp #$0a				; Is it a digit??
	bcc dig					; If 'yes' then branch to 'dig'
	adc #$88				; If 'no' then map to 'A' to 'F' to $FA-FF
	cmp #$fa				; Is it a hex letter??
	bcc nothex				; 'no' character is not hex then branch to 'nothex'

dig:						; Hex digit to MSD of 'a' register
	asl
	asl
	asl
	asl

	ldx #$04				; Load 'x' register with shift count
hexshift
	asl						; Shift hex digit left, MSB to 'carry' flag
	rol L					; Rotate into LSD
	rol H					; Rotate into MSD's
	dex 					; Done 4 shifts??
	bne hexshift			; 'no', then loop 
	iny						; 'yes', then advance text index
	bne nexthex				; Will always go to 'nexthex' and check for hex character

nothex:
	cpy YSAV				; Check if L & H are empty (there are no hex digits)
	beq escape

	bit MODE				; Test MODE byte
	bvc notstor				; bit 6=0 is STOR, =1 is XAM & BLOCK XAM

	lda L					; LSD's of hex data
	sta (STL,x)				; Store current 'store index'
	inc STL					; Increment store index
	bne nextitem			; Get next item (no carry)
	inc STH					; Add 'carry' to 'store index' high order
tonextitem:
	jmp nextitem			; Get next command item

run:
	jmp (XAML)				; Run at current XAM index	

notstor:
	bmi xamnext				; Bit7=0 for XAM, bit7=0 for BLOCK XAM

	ldx #$02				; Set byte count
setadr:
	lda L-1,x				; Copy hex data to
	sta STL-1,x				;  'store index'
	sta XAML-1,x			;  and to 'XAM index'
	dex						; Next of 2 bytes
	bne setadr				; If not done, loop back

nxtprint:
	bne prdata				; NE means no address to print
	jsr NEWLINE
	lda XAMH				; 'Examine index' high-order byte
	jsr PRTXBYT				; Output it in hex format
	lda XAML				; 'Examine index' low-order byte 
	jsr PRTXBYT				; Output it in hex format
	lda #$3a				; ':'
	jsr TXCHAR				; Print it

prdata:
	lda #$20				;'space'
	jsr TXCHAR				; Print it
	lda (XAML,x)			; Get data byte at 'examine index'
	jsr PRTXBYT				; Print it in hex format

xamnext:
	stx MODE				; 0 -> MODE (XAM mode)
	lda XAML
	cmp L					; Compare 'examine index' to hex data
	lda XAMH
	sbc H
	bcs tonextitem			; Not less, so no more data tp output

	inc XAML
	bne mod8chk				; Increment 'examine index'				
	inc XAMH

mod8chk:
	lda XAML				; Check low-order 'examine index' byte
;	and #$07				; for MOD 8 = 0
	and #$0F				; changed to #$0F to print 16 bytes to terminal
	
	bpl nxtprint			; Always taken

	jsr PRTXBYT				; Output data byte in 'a' as ASCII
	rts


