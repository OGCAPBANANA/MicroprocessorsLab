#include <xc.inc>
extrn	UART_Setup, UART_Transmit_Message  ; external subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Send_Byte_I, LCD_delay_ms
extrn	LCD_Clear_Display, LCD_Set_Position, LCD_Write_Message_PM
	
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
button_prev:ds 1    ; store previous button state for debouncing
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray:    ds 0x80 ; reserve 128 bytes for message data

psect	data    
	; ******* Messages in programme memory *****
message1:
	db	'Button A',0x0a
	msg1_l   EQU	8	; length of message (without CR)
	
message2:
	db	'Button B',0x0a
	msg2_l   EQU	8
	
line1_text:
	db	'Press a button'
	line1_l  EQU    14
	
line2_text:
	db	'A or B'
	line2_l  EQU    6

	align	2
    
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Setup Code ***********************
setup:	
	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	
	; Setup button on RA0 and RA1 as inputs with pull-ups
	bsf	TRISA, 0, A	; RA0 as input (Button A)
	bsf	TRISA, 1, A	; RA1 as input (Button B)
	bcf	LATA, 0, A	; Clear LATA
	bcf	LATA, 1, A
	
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup LCD
	
	clrf	button_prev, A	; initialize button state
	
	goto	start
	
	; ******* Main programme ****************************************
start: 	
	; Display initial message on LCD
	call	LCD_Clear_Display
	
	; Write to line 1
	movlw	0x00		; Position 0 on line 1
	call	LCD_Set_Position
	movlw	low highword(line1_text)
	movwf	TBLPTRU, A
	movlw	high(line1_text)
	movwf	TBLPTRH, A
	movlw	low(line1_text)
	movwf	TBLPTRL, A
	movlw	line1_l
	call	LCD_Write_Message_PM
	
	; Write to line 2
	movlw	0x40		; Position 0 on line 2 (0x40 = start of line 2)
	call	LCD_Set_Position
	movlw	low highword(line2_text)
	movwf	TBLPTRU, A
	movlw	high(line2_text)
	movwf	TBLPTRH, A
	movlw	low(line2_text)
	movwf	TBLPTRL, A
	movlw	line2_l
	call	LCD_Write_Message_PM

	; Main loop - check for button presses
main_loop:
	; Check Button A (RA0)
	btfss	PORTA, 0, A	; Skip if button A is high (not pressed)
	call	button_A_pressed
	
	; Check Button B (RA1)
	btfss	PORTA, 1, A	; Skip if button B is high (not pressed)
	call	button_B_pressed
	
	; Small delay for debouncing
	movlw	50		; 50ms delay
	call	LCD_delay_ms
	
	bra	main_loop

; ******* Button A Handler *************************************
button_A_pressed:
	; Clear display
	call	LCD_Clear_Display
	
	; Copy message1 to RAM array
	lfsr	0, myArray
	movlw	low highword(message1)
	movwf	TBLPTRU, A
	movlw	high(message1)
	movwf	TBLPTRH, A
	movlw	low(message1)
	movwf	TBLPTRL, A
	movlw	msg1_l + 1	; include CR
	movwf 	counter, A
	
copy_msg1:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz	counter, A
	bra	copy_msg1
	
	; Send to UART
	movlw	msg1_l + 1
	lfsr	2, myArray
	call	UART_Transmit_Message
	
	; Display on LCD line 1
	movlw	0x00		; Line 1, position 0
	call	LCD_Set_Position
	movlw	low highword(message1)
	movwf	TBLPTRU, A
	movlw	high(message1)
	movwf	TBLPTRH, A
	movlw	low(message1)
	movwf	TBLPTRL, A
	movlw	msg1_l
	call	LCD_Write_Message_PM
	
	; Wait for button release
	call	wait_button_release
	return

; ******* Button B Handler *************************************
button_B_pressed:
	; Clear display
	call	LCD_Clear_Display
	
	; Copy message2 to RAM array
	lfsr	0, myArray
	movlw	low highword(message2)
	movwf	TBLPTRU, A
	movlw	high(message2)
	movwf	TBLPTRH, A
	movlw	low(message2)
	movwf	TBLPTRL, A
	movlw	msg2_l + 1	; include CR
	movwf 	counter, A
	
copy_msg2:
	tblrd*+
	movff	TABLAT, POSTINC0
	decfsz	counter, A
	bra	copy_msg2
	
	; Send to UART
	movlw	msg2_l + 1
	lfsr	2, myArray
	call	UART_Transmit_Message
	
	; Display on LCD line 2
	movlw	0x40		; Line 2, position 0
	call	LCD_Set_Position
	movlw	low highword(message2)
	movwf	TBLPTRU, A
	movlw	high(message2)
	movwf	TBLPTRH, A
	movlw	low(message2)
	movwf	TBLPTRL, A
	movlw	msg2_l
	call	LCD_Write_Message_PM
	
	; Wait for button release
	call	wait_button_release
	return

; ******* Wait for button release (debouncing) *****************
wait_button_release:
	movlw	50		; 50ms delay
	call	LCD_delay_ms
wait_loop:
	btfss	PORTA, 0, A	; Check if Button A still pressed
	bra	wait_loop
	btfss	PORTA, 1, A	; Check if Button B still pressed
	bra	wait_loop
	return

	; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return
	
	end	rst


