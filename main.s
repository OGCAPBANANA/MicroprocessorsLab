	#include <xc.inc>

psect	code, abs
	
main:
	org	0x0
	goto	start

	org	0x100		    ; Main code starts here at address 0x100
start:
	movlw 	0x0
	movwf	TRISJ, A
	movlw   0x50
	movwf   0x90; Port C all outputs
	movwf   0x91   ;original
	movlw 	0x0
	bra 	test
loop:
	movff 	0x06, PORTJ
	call    delay
	movff   0x91, 0x90
	incf 	0x06, W, A
test:
	movwf	0x06, A	    ; Test for end of loop condition
	movlw 	0xFF
	cpfsgt 	0x06, A
	bra 	loop		    ; Not yet finished goto start of loop again
	goto 	0x0		    ; Re-run program from start

	

delay:
        decfsz  0x90
	bra     delay
	return
        end	main