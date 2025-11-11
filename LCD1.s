#include <xc.inc>
global  LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I, LCD_delay_ms
global  LCD_Clear_Display, LCD_Set_Position, LCD_Write_Message_PM

psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1   ; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1   ; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1   ; reserve 1 byte for ms counter
LCD_tmp:	ds 1   ; reserve 1 byte for temporary use
LCD_counter:	ds 1   ; reserve 1 byte for counting through message
	LCD_E	EQU 5	; LCD enable bit
    	LCD_RS	EQU 4	; LCD register select bit
psect	lcd_code,class=CODE
    
LCD_Setup:
	clrf    LATB, A
	movlw   11000000B	    ; RB0:5 all outputs
	movwf	TRISB, A
	movlw   40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	movlw	00110000B	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00001111B	; display on, cursor on, blinking on
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms
	movlw	00000110B	; entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	return

LCD_Write_Message:	    ; Message stored at FSR2, length stored in W
	movwf   LCD_counter, A
LCD_Loop_message:
	movf    POSTINC2, W, A
	call    LCD_Send_Byte_D
	decfsz  LCD_counter, A
	bra	LCD_Loop_message
	return

; ***** NEW ROUTINE: Write message directly from Program Memory *****
; TBLPTR must point to start of message in PM, length in W
LCD_Write_Message_PM:
	movwf   LCD_counter, A
LCD_Loop_PM:
	tblrd*+			; read byte from PM to TABLAT, increment pointer
	movf	TABLAT, W, A	; move data to W
	call    LCD_Send_Byte_D	; send to LCD
	decfsz  LCD_counter, A
	bra	LCD_Loop_PM
	return

; ***** NEW ROUTINE: Set cursor position *****
; Call with position in W (0x00-0x0F for line 1, 0x40-0x4F for line 2)
; For convenience: Line 1 position N: pass N
;                  Line 2 position N: pass 0x40 + N
LCD_Set_Position:
	addlw	0x80		; Add set DDRAM address command bit
	call	LCD_Send_Byte_I
	movlw	20		; wait 40us
	call	LCD_delay_x4us
	return

; ***** NEW ROUTINE: Clear Display *****
LCD_Clear_Display:
	movlw   0x01		; Clear display command
	call    LCD_Send_Byte_I
	movlw   2		; Wait 2ms for command to complete
	call    LCD_delay_ms
	return

LCD_Send_Byte_I:	    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit 
	return

LCD_Send_Byte_D:	    ; Transmits byte stored in W to data reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A	; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A	; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit	    
        call    LCD_Enable  ; Pulse enable Bit 
	movlw	10	    ; delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATB, LCD_E, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCD_E, A	    ; Writes data to LCD
	return
    
; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return
    end


