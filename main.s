	#include <xc.inc>

psect	code, abs
	
data_out	EQU 0x95 
temp	        EQU 0x90 
delay_number	EQU 0x91  
loop_number     EQU 0x92
counter_low     EQU 0x93 	
counter_high    EQU 0x94 	

main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
	banksel temp
	movlw 	0x0
	movwf	TRISJ, A
	movlw   0x01
	movwf   counter_high
	movlw   0x01
	movwf   counter_low
	movlw   65
	movwf   loop_number ; 7F = 128 loop
	movlw   64
	movwf   temp; Port C all outputs
	movwf   delay_number   ;original
	bra 	loop_high
loop_high:
	movlw 	0xFF
	movwf   data_out
	movff 	data_out, PORTJ
	call    delay
	movff   delay_number, temp
	incf    counter_high, F
	movf    counter_high, W      ; W = counter
	cpfslt  loop_number         ; skip if counter > loop number
	bra     loop_high
	bra     loop_low
loop_low:
	movlw 	0x00
	movwf   data_out
	movff 	data_out, PORTJ
	call    delay
	movff   delay_number, temp
	incf    counter_low, F
	movf    counter_low, W      ; W = counter
	cpfslt  loop_number         ; skip if counter > loop number
	bra     loop_low
	goto    0x0
	

delay:        
	decfsz  temp
	bra     delay
	return
        end	main
    