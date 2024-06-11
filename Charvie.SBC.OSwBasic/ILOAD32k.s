;**********************************************************************
;*                          ILOAD Function                            *
;*                 Load an Intel HEX file into RAM                    *
;*              Taken from D. Hansel's smon.asm files                 *
;*               https://github.com/dhansel/smon6502                  *
;**********************************************************************

	.org $EA00
	
LOAD:   
			jsr CLEARSCR			; Clear the screen
			jsr ildcur				; print cursor '.'
			jsr NEWLINE				;
        
LDNXT:	jsr RXCHAR				; get character from UART
			cmp #' '
			beq LDNXT				; ignore space at beginning of line
			cmp #$0D					; compare to 'CR'
			beq LDNXT				; ignore CR at beginning of line
			cmp #$0A					; compare to 'LF'
			beq LDNXT				; ignore LF at beginning of line
			cmp #$1B					; compare to 'ESC'
			beq LDBRK				; stop when receiving BREAK (ESC)
			cmp #$03					; compare to 'EXT' (End of teXT)
			beq LDBRK				; stop when receiving 'EXT' (CTRL-C)
			cmp #$3A					; expect ":" at beginning of line
			bne LDEIC				; if not branch and print an 'I' then '?'

;-------------------------------------------------------------------------
;            HERE IS WHERE WE START IMPORTING THE FILE
;-------------------------------------------------------------------------
			jsr LDBYT				; else - get record byte count
			tax						; 'x' will have record byte count 
			jsr LDBYT				; get address high byte
			sta $FC
			jsr LDBYT				; get address low byte
			sta $FB
			jsr LDBYT				; get record type
			beq LDDR					; jump if data record (record type 0)
			cmp #1					; end-of-file record (record type 1)
			bne LDERI				; neither a data nor eof record => error

;-------------------------------------------------------------------------
;             Read Intel HEX end-of-file record
;-------------------------------------------------------------------------
			jsr LDBYT				; get next byte (should be checksum)
			cmp #$FF					; checksum of EOF record is FF
			bne LDECS				; error if not
        
LDEOF:	jsr NEWLINE
			lda #'+'					; Print a '+' to show that EOF has been
			jsr TXCHAR				; reached and file is loaded into RAM
			jsr NEWLINE
LD053:	jsr GETCHAR				; wait for 'CR'
			cmp #$0d					; Is it a 'CR'
			bne LD053				; If 'NO' go back and check again 
			jmp WOZMON

;------------------------------------------------------
;                  'LDDR' Function
;          Load Intel HEX data record into RAM
;------------------------------------------------------
LDDR:		clc						; prepare checksum
			txa						; byte count
			adc $FB					; address low
			clc
			adc $FC					; address high
			sta $FD					; store checksum
			ldy #0					; offset
			inx
LDDR1:	dex						; decrement number of bytes
			beq LDDR2				; done if 0
			jsr LDBYT				; get next data byte
			sta ($FB),y				; store data byte
			cmp ($FB),y				; check data byte
			bne LDEM					; memory error if no match
			clc
			adc $FD					; add to checksum
			sta $FD					; store checksum
			iny
			bne LDDR1
LDDR2:	jsr LDBYT				; get checksum byte
			clc
			adc $FD					; add to computed checkum
			bne LDECS				; if sum is 0 then checksum is ok
			cpy #0					; did we have 0 bytes in this record?
			bne LDNXT				; if not then expect another record
			beq LDEOF				; end of file

;---------------------------------------------------
;              ERROR message block
;---------------------------------------------------       
LDBRK:	lda #'B'					; received BREAK (ESC)
			.byte   $2C
LDERI:	lda #'R'					; unknown record identifier error
			.byte   $2C
LDECS:	lda #'C'					; checksum error
			.byte   $2C
LDEIC:	lda #'I'					; input character error
			.byte   $2C
LDEM:		lda #'M'					; memory error
			jsr TXCHAR				; print it
LDERR:	jmp ERROR

;---------------------------------------------------        
        ;; get HEX byte from UART
;---------------------------------------------------
LDBYT:	jsr LDNIB				; get high nibble
			asl
			asl
			asl
			asl
			sta $B4
			jsr LDNIB				; get low libble
			ora $B4					; combine
			rts

    ;; get HEX character from UART, convert to 0-15
LDNIB:	jsr GETCHAR				; get character from UART
			jsr UCASE				; convert to uppercase
			jsr TXCHAR				; Print it back to the terminal
			cmp #'0'					; Is it less than '0'
			bcc LDEIC				; If yes then branch to 'error'
			cmp #'F'+1				; Is it larger than 'F'
			bcs LDEIC				; If yes then branch to 'error'
			cmp #'9'+1				; If it '9' or less
			bcc LDBYT2				; Then it is '0 - 9' & go convert to HEX byte
			cmp #'A'					; 
			bcc LDEIC				; If less than 'A' branch to 'error'
			adc #$08					; Else it is 'A - F' so go convert to HEX byte
LDBYT2:	and #$0F
			rts
        
;--------------------------------------------------
;                 'ERROR' Function
;       Print a "?" if an error in encountered
;--------------------------------------------------
ERROR:	lda #$3F					; print "?"
			jsr TXCHAR
ierror:	jsr GETCHAR
			cmp #$0d					; check for 'CR'
			bne ierror 
			jmp WOZMON				; go to menu
        
;--------------------------------------------------
;             ILOAD 'CURSOR' Function
;       Print a "." at the start of each line
;--------------------------------------------------
ildcur:	jsr NEWLINE
			lda #'.'					; CMON cursor
			jsr TXCHAR
			rts
                
;*********************************************************        


  


