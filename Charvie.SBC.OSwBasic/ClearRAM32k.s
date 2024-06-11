;****************************************************
;*                CLEAR RAM ROUTINE                 *
;*Loads (wipes) memory with #$00 from $0400 to $7fff*            
;****************************************************

	.org $E9E0
	
CLRAM:
			ldx $38					; addrhi+1 (end page)
			ldy #$00					; init low order byte index
			tya						; set 'a' to #$00

FIL013:	sta ($2b),y				; store 'a' starting in location $0400
			iny						; continue until page is filled
			bne FIL013				; with #$00 value
			
			inc $2c					; next page
			cpx $2c					; are we done with the final page??
			bne FIL013				; branch if NOT done
			
			jsr RAMzero				; re-init $2b,$2c,$37 & $38
			jmp STARTWM				; back to MENU
