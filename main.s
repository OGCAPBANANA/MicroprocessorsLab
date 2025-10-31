	#include <xc.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
  	movlw 	0x0
	movwf	TRISC, A            ; Port C all outputs
	movlw   0x0F
	movwf   0x90, A
	movlw   0x0
	bra 	loop                           ;movff 	0x06, PORTC
loop:
	movwf   FSR0L
	clrf    FSR0H
	movwf   INDF0
	addlw   0x01
	movf    WREG, W 
	cpfslt  0x90, A
	bra     loop
	nop
        
	end	main
