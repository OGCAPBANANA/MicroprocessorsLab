
    #include <xc.inc>

;password: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
STATUS EQU 0FD8h
Z EQU 2
data_points EQU 0x90
delay_number EQU 0x91
original_value EQU 0x92
temp_value EQU 0x93
bit_counter EQU 0x94
psect	code, abs
temp_subtraction EQU 0x67
 
main:          
	org	0x0
	goto	start
	org	0x100		    ; Main code starts here at address 0x100
start:
	bsf     LATC, 1               ; turn LED off
	clrf    TRISC
	clrf    LATC
  	;movlw 	0x0
	;movwf	TRISC, A            ; Port C all outputs
	; Configure Port C as all outputs
	movlw 	0x0F
	movwf	TRISC, A            ; Port C all outputs
	
	; Turn off all LEDs initially (assuming active-low LEDs)		    ; All bits high = LEDs off
	movlw   0x2F               ;number of data points
	;movwf   data_points, A
	movwf   data_points
	clrf    WREG
	movlw   0x01
	movwf   temp_subtraction
	movlw   0x0F         ;delay number
	movwf   delay_number
	clrf    WREG
	movlw   0x0        
	call 	loopdata
	movlw   0x0        ; Load WREG with 0x00 (target address low byte)
        bra     loopread
	nop
	                              ;movff 	0x06, PORTC
loopdata:
	movwf   FSR0L
	clrf    FSR0H
	movwf   INDF0
	addlw   0x01
	movf    WREG, W
	cpfslt  data_points
	bra     loopdata
return  ;branches to clear W again and start loopread
	
	
loopread:         ; Load WREG with 0x00 (target address low byte)
	movwf   FSR0L       ; Set FSR0L to 0x00
	clrf    FSR0H       ; Clear FSR0H to point to Bank 0 (address 0x0000)    
	movwf   INDF0 ; Read the value at address pointed by FSR0 into WREG
	movwf   original_value   ; original value
	movwf   temp_value  ;changing value (temp)
	movlw   0x08
	movwf   bit_counter   ;bit counter
	clrf    WREG
	bra     bitcheck
	clrf    WREG  
	movlw   0x0F
	movwf   delay_number
	clrf    WREG
	movf    original_value, W
	addlw   0x01
	cpfslt  data_points
	bra     loopread
	bra     END_LOOP       ;branches to NOP
	
	
	
bitcheck:
         rrcf    temp_value, F
	 bnc     bit_zero 
	 bra     led_display
	 ;activate LED at current bit of original temp value
	 bra     next_bit
	 
next_bit:
         decfsz  bit_counter, F  ;0x102 is bit counter
         bra     bitcheck
         goto    led_delay    ;branches to clear LEDS 

bit_zero:
         ;keep LED at current bit off          ; Compare with 0
	  iorwf   WREG, W     ; W OR W ? W (unchanged)
	  movwf   0x99
	  btfss   STATUS, Z
	  goto    next_check1_off; If result zero, W == 0
	  addlw   0x01
	  bra     condition0_off

next_check1_off:	 
	 subwf   temp_subtraction, W   ;F-W
	 COMF    WREG, F
	 INCF    WREG, F
	 movwf   0x99
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check2_off; If result zero, W == 0
	 addlw   0x02
	 bra     condition1_off
	 
next_check2_off:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 movwf   0x99
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check3_off   ; If result zero, W == 0
	 addlw   0x03
	 bra     condition2_off

next_check3_off:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 movwf   0x99
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check4_off   ; If result zero, W == 0
	 addlw   0x04
	 bra     condition3_off	 

next_check4_off:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 movwf   0x99
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check5_off   ; If result zero, W == 0
	 addlw   0x05
	 bra     condition4_off

next_check5_off:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check6_off   ; If result zero, W == 0
	 addlw   0x06
	 bra     condition5_off

next_check6_off:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check7_off   ; If result zero, W == 0
	 addlw   0x07
	 bra     condition6_off

next_check7_off:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check3_off   ; If result zero, W == 0
	 bra     condition7_off
	 
condition0_off:	  
	  bsf     LATC, 0            ; Set RC0
	  bra     next_bit
condition1_off:
	  bsf     LATC, 1            ; Set RC1
	  bra     next_bit
condition2_off:
	  bsf     LATC, 2            ; Set RC2
	  bra     next_bit
condition3_off:
	  bsf     LATC, 3            ; Set RC3
	  bra     next_bit
condition4_off:
	  bsf     LATC, 4            ; Set RC4
	  bra     next_bit
condition5_off:
	  bsf     LATC, 5            ; Set RC5
	  bra     next_bit
condition6_off:
	  bsf     LATC, 6            ; Set RC6
	  bra     next_bit
condition7_off:
	  bsf     LATC, 7            ; Set RC7
	  bra     next_bit

led_display:
         ;keep LED at current bit off          ; Compare with 0
	  iorwf   WREG, W     ; W OR W ? W (unchanged)
	  btfss   STATUS, Z
	  goto    next_check1_on; If result zero, W == 0
	  addlw   0x01
	  goto    condition0_on

next_check1_on:	 
	subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 movwf   0x99
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check2_on; If result zero, W == 0
	 addlw   0x02
	 bra     condition1_on
next_check2_on:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 movwf   0x99
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check3_on; If result zero, W == 0
	 addlw   0x03
	 bra     condition2_on

next_check3_on:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 movwf   0x99
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check4_on; If result zero, W == 0
	 addlw   0x04
	 bra     condition3_on	 

next_check4_on:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 movwf   0x99
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check5_on; If result zero, W == 0
	 addlw   0x05
	 bra     condition4_on

next_check5_on:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 movwf   0x99
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check6_on; If result zero, W == 0
	 addlw   0x06
	 bra     condition5_on
next_check6_on:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 movwf   0x99
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check7_on; If result zero, W == 0
	 addlw   0x07
	 bra     condition6_on

next_check7_on:	 
	 subwf   temp_subtraction, W
	 COMF    WREG, F
	 INCF    WREG, F
	 movwf   0x99
	 iorwf   WREG, W     ; W OR W ? W (unchanged)
	 movwf   0x99
	 btfss   STATUS, Z
	 goto    next_check2_on; If result zero, W == 0
	 bra     condition7_on
	 
condition0_on:	  
	  bcf     LATC, 0            ; Set RC0
	  bra     next_bit
condition1_on:
	  bcf     LATC, 1            ; Set RC1
	  bra     next_bit
condition2_on:
	  bcf     LATC, 2            ; Set RC2
	  bra     next_bit
condition3_on:
	  bcf     LATC, 3            ; Set RC3
	  bra     next_bit
condition4_on:
	  bcf     LATC, 4            ; Set RC4
	  bra     next_bit
condition5_on:
	  bcf     LATC, 5            ; Set RC5
	  bra     next_bit
condition6_on:
	  bcf     LATC, 6            ; Set RC6
	  bra     next_bit
condition7_on:
	  bcf     LATC, 7            ; Set RC7
	  bra     next_bit 	  
	  
	  	  
led_delay:
         decfsz   delay_number, F
	 bra      led_delay
         bra      led_clear
    
led_clear:
         bsf     LATC, 0
	 bsf     LATC, 1
	 bsf     LATC, 2
	 bsf     LATC, 3
	 bsf     LATC, 4
	 bsf     LATC, 5
	 bsf     LATC, 6
	 bsf     LATC, 7
	 goto    0x00142       ;branches to clear W register and read the next number


END_LOOP:
    goto END_LOOP   