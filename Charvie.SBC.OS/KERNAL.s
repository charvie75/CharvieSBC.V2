;*****************************************************
;*                   KERNAL.060624                   *
;*****************************************************

;-----------------------------------------------------
;               ACIA Register Addresses
;-----------------------------------------------------
ACIA_CnSt = $8008			; Control & Status registers address
ACIA_TxRx = $8009			; Tx & Rx registers address

IRQ_VEC = $0314

freebyte = $0200			; Start of input buffer (also used by WOZMON)

;*****************************************************
;               Cold Start Entry Point
;*****************************************************

	.org $F000

Reset:
	ldx	#$FF				; set X for stack
	sei						; disable interrupts
	txs						; clear stack
	cld						; clear decimal mode
	jsr	RAMinit				; initialize and test RAM
	jsr IRQINIT				; initialize Interrupt Vector location
	jsr	IOINIT				; initialize I/O registers
	cli						; enable interrupts

	jsr	RAMzero				; initialise BASIC RAM locations
	jsr	STARTmgs			; print start up message and initialise memory pointers
	ldx	#$FF				; value for start stack
	txs						; set stack pointer
	jmp STARTCD				; Go 'cold start' MENU ($E000)

;*************************************************************
;                           RAMinit
;*************************************************************
; Initialise and test RAM, the RAM from $000 to $03FF is never
; tested and is just assumed to work. First pages 0,2 and 3
; are filled with zeros. Then memory from $0400 to $7FFF is
; tested via RAMbytst routine. All tested RAM is left with zeros. 

RAMinit:
	lda	#$00				; clear A
	tax						; clear index
	
KL_046:						; WRITES #$00 TO PAGES 0,2,3
	sta	$00,X				; clear page 0
	sta	$0200,X				; clear page 2
	sta	$0300,X				; clear page 3
	inx						; increment index
	bne	KL_046				; loop if more to do

	sta	$0281				; clear OS start of memory low byte (#$00)
	tay						; clear Y (#$00) this index used by 'RAMbytst'
	
	lda	#$80
	sta	$0284				; set top of RAM+1 = $8000
	
	lda	#$04				; set RAM test pointer high byte
	sta	$0282				; start of RAM = $0400
	lda	#$03				;
	sta	$C2					; save to RAM test pointer high byte
							; will roll over to #$04 at start of 'TESTmem'
 
	lda #$ff				; set $c1 to #$ff which will roll over 
	sta $c1					; #$00 at start of 'TESTmem' which will cause
							; $c2 to roll over to #$04 so we will start 
							; checking RAM at $0400 
TESTmem:
	inc	$C1					; increment RAM test pointer low byte
	bne	KL_079				; if no rollover skip the high byte increment
	inc	$C2					; increment RAM test pointer high byte
	
	ldx $c2					; go to the next page
	cpx #$80				; compare with $8000, RAM should always end at or after
							; $8000 as the built in RAM ends at $7FFF.
	beq KL_083 
	
KL_079:
	jsr	RAMbytst			; test RAM byte, return Cb=0 if failed
	jmp TESTmem
	
KL_083:
	rts
	
;*************************************************************
;                         'RAMbytst'
;                       (RAM byte test)
;    Destructive RAM byte test, Leaves #$00 in all RAM
;    locations from $0400 to $7fff
;    Called by RAMinit (Simple RAM Test)
;*************************************************************
RAMbytst:
	lda	#$55				; set first test byte
	sta	($C1),Y				; save to RAM
	cmp	($C1),Y				; compare with saved
	bne	RAMbyfail			; branch if fail

	ror						; make byte $AA, carry is set here
	sta	($C1),Y				; save to RAM
	cmp	($C1),Y				; compare with saved
	bne	RAMbyfail			; branch if fail

	lda #$00
	sta ($c1),y				; store #$00 in memory location
	rts
	
RAMbyfail:					; if a byte fails, #$00 will not 
							; be written to that location
	rts

;************************************************
;                    'RAMzero'
;        initialise 'Z'page RAM locations
;************************************************
RAMzero:
	ldx	$0281				; read OS start of memory low byte
	ldy	$0282				; read OS start of memory high byte
	stx	$2B					; save start of memory low byte
	sty	$2C					; save start of memory high byte

	ldx	$0283				; get memory top low byte
	ldy	$0284				; get memory top high byte
	stx	$37					; save end of memory low byte
	sty	$38					; save end of memory high byte

	rts

;************************************************
;                    'STARTmgs'
;  print startup message & init memory pointers
;************************************************
STARTmgs:
	jsr CLEARSCR			; CLEAR SCREEN BEFORE MESSAGE PRINT
	lda	#<startmg1			; set "**** CHARVIE DYI 65C02 COMPUTER ****" pointer low byte
	ldy	#>startmg1			; set "**** CHARVIE DYI 65C02 COMPUTER ****" pointer high byte
	jsr	PRTSTR				; print null terminated string
	jsr	NEWLINE
	lda	$37					; get end of memory low byte
	sec						; set carry for subtract
	sbc	$2B					; subtract start of memory low byte
	tax						; copy result to X
	lda	$38					; get end of memory high byte
	sbc	$2C					; subtract start of memory high byte
	jsr	FREERAM				; print amount of free RAM space to the terminal
	lda	#<startmg2			; set " BYTES FREE" pointer low byte
	ldy	#>startmg2			; set " BYTES FREE" pointer high byte
	jsr	PRTSTR				; print null terminated string
	jsr	NEWLINE
	rts

;*****************************************************
;                     'PRTSTR'
; When 'called' this code prints any 'null' terminated
; ascii string to the terminal who's memory address
; is in 'a' and 'y' before the calling of this routine.
;*****************************************************
PRTSTR:
	sta	$71					; store string start low byte
	sty	$72					; store string start high byte
	ldy	#$FF				; set length to -1
strgprt:	
	INY						; increment length
	lda	($71),Y				; get byte from string
	beq	strgdon				; string done - exit loop if null byte [EOS], else
	jsr TXCHAR				; print character to terminal
	jmp strgprt				; go get next character
strgdon:
	clc						; clear carry (only if [EOL] terminated string)
;	jsr	NEWLINE
	rts
	
;****************************************************
;                     'FREERAM'
; This code takes the binary value for the amount
; of free RAM that was calculated by STARTmgs, stores
; it @ $62 & $63, converts it to ascii decimal format
; and then prints it to the terminal.
;****************************************************
FREERAM:
	stx $62					; save low byte 
	sta $63					; save high byte
	
	lda #$00				; load a 'null' character into 'freebyte' string
	sta freebyte			; 1st character 'in' of the string will be last
							; character of string (FILO)

;---------------Initialize value to be the number to convert----------------

divide:						; Initialize the remainder to zero
	lda #$0
	sta $64
	sta $65
	clc						; Clear the carry bit

	ldx #16					; Initialize counter for 'divloop'

divloop:						; Start of divide loop
	rol $62					; Shifts all bytes to the left
	rol $63
	rol $64
	rol $65

;-------------value in 'a,y' = (dividend - divisor)--------------

	sec						; Set the carry bit so that we will know if we had to borrow
	lda $64
	sbc #10					; Subtract #10 from $64, answer is left in the 'a'
	tay						; Transfer value in 'a' to 'y' (save low byte)
	lda $65
	sbc #0
	bcc ignresult			; If 'Cf' is clear then the dividend is < divisor so ignore

	sty $64					; If 'Cf' is not clear then we are not done
	sta $65					; Put 'y' and 'a' into $64 and $65

ignresult:
	dex						; Decrement the 'divloop' counter	
	bne	divloop				; Branch back to 'divloop' if the counter is not '0'

	rol $62					; Shift in the last bit of the quotient
	rol $63

	lda $64					; Load the remainder into 'a'
	clc 
	adc #"0"					; Make result an ascii character by adding #$30
	jsr push_char			; Puts character into 'string'

;----------------if value !=0, then continue dividing--------------------

	lda $62
	ora $63					; If done result of 'or' between high and low value
							; bytes will be '0'
	bne divide				; If not done, 'Zf' is not clear, branch back to divide

;-------Add spaces '#$20' to front of string---------

	lda #$0A
	sta $FF
nextspc:
	lda #$20
	jsr push_char
	dec $FF
	lda $FF
	bne nextspc

;----------------Go Print It------------------------
	lda	#<freebyte			; set string low byte
	ldy	#>freebyte			; set string high byte

	sta	$71					; store string start low byte
	sty	$72					; store string start high byte
	ldy	#$FF				; set length to -1
freeprt:
	INY						; increment length
	lda	($71),Y				; get byte from string
	beq	freedon				; string done - exit loop if null byte [EOS], else
	jsr TXCHAR				; print character to terminal
	jmp freeprt				; go get next character
freedon:
	rts

;---------------------------------------------------
;                  'push_char'
; Add the character in the 'a' register to the
; beginning of the null-terminated string 'freebyte'
;---------------------------------------------------
push_char:
	pha						; Push new first char onto the stack
	ldy #0					; Set counter to '0'

char_loop:
	lda freebyte,y			; Get character on string and put into 'x'
	tax
	pla
	sta freebyte,y			; Pull character off the stack and add it to the string
	iny						; Increment the counter
	txa
	pha						; Push character from the string onto the stack
	bne char_loop			; If the character is not the #0 we add first branch to 'char_loop'
	
	pla
	sta freebyte,y			; Pull the null off the stack and add back to the string
	rts

;***************************************************************
;                    Initialize Interrupt Vector
; $0314 & $0315 hold the memory address of the Interrupt Handler
; routine. When an IRQ occurs the CPU will jump to this location
; and handle the IRQ request. 
;***************************************************************
IRQINIT:
	lda #$e3				; IRQ Vector low order byte
	sta IRQ_VEC				; Store
	lda #$ff				; IRQ Vector high order byte
	sta IRQ_VEC+1			; Store
	rts

;*************************************************************
;                    Initialize ACIA registers
;*************************************************************
IOINIT:
	lda #%00000011
	sta ACIA_CnSt			; Reset ACIA (resets status register)
	lda #%00010101			; Set ACIA to N-8-1, 115200 Baud, No IRQs
	sta ACIA_CnSt
	rts

;*************************************************************
;                          'TXCHAR'
;    Sends an ascii character to the terminal via the ACIA
;*************************************************************
TXCHAR:
	sta ACIA_TxRx
	pha
tx_wait:
	lda ACIA_CnSt
	and #$02				; Check if tx buffer status flag is set (1)
	beq tx_wait				; If tx buffer is not empty, go back and wait
	pla
	rts
	
;*************************************************************
;                           'RXCHAR'                      
;           Wait for & get character from the terminal 
;                        ==>ECHO BACK<==       
;*************************************************************
RXCHAR:
	jsr GETCHAR
	jsr TXCHAR				; echo character back out
	rts

;*************************************************************
;                          'GETCHAR'                      
;          Wait for & get character from the terminal
;                      ==>NO ECHO BACK<==        
;*************************************************************
GETCHAR:
	lda ACIA_CnSt			; Check if receive data register is full
	and #$01				; If this bit is set data register is full
	beq GETCHAR				; If not set, go back up
	lda ACIA_TxRx			; load data from register
	rts
	
;*************************************************************
;                         'CLEARSCR'                      
;                    Clear Terminal Screen                
;*************************************************************
CLEARSCR:
	lda #$1b				; Begin with 'escape' & 'c'.
	jsr TXCHAR
	lda #$63				; This will clear the screen
	jsr TXCHAR
	rts

;*************************************************************
;                         'NEWLINE'
;               'CR' & 'LF' ON Terminal Screen
;*************************************************************
NEWLINE:
	lda #$0d				; 'CR'
	jsr TXCHAR				; Print It
	lda #$0a				; 'LF'
	jsr TXCHAR				; Print It
	rts
	
;*************************************************************
;                          'UCASE' 
;            Convert character in A to uppercase
;*************************************************************
UCASE:
	cmp #'a'				; is the hex value of the character less than #$61?
   	bcc KL_361				; if yes then character is not 'LCASE' so done 
   	cmp #'z'+1				; is the hex value of the character greater than #$7A
   	bcs KL_361				; if yes then done
   	and #$DF				; else 'and' with #$DF to convert character to 'UCASE'
KL_361:
	rts

;*************************************************************
;                         'PRTXBYT' 
;               Output data byte in A as ASCII
;                   Taken from WOZMON Code
;*************************************************************
PRTXBYT:
	pha						; Save 'a' register for LSD
	lsr						; These 'lsr's move 
	lsr						; MSD to LSD position
	lsr
	lsr
	jsr KL_377				; Print hex digit
	pla						; restore the 'a' register
KL_377:
	and #$0f				; Mask LSD for hex print
	ora #$30				; Add '0'
	cmp #$3a				; Is it a digit??
	bcc KL_383				; If 'yes' then print it
	adc #$06				; Add offset for letter, fall through & 'print it'
KL_383:
	jsr TXCHAR
	rts 

;*************************************************************
;                        MESSAGES
;*************************************************************
startmg2:
	.asciiz	" BYTES FREE"
startmg1:
	.asciiz	"**** CHARVIE DIY 65C02 COMPUTER ****"
;*************************************************************











