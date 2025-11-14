#include <xc.inc>

CountTemp EQU 0x90	
MyByte EQU 0x91

main:
    org     0x0
    goto    start
    org     0x100	
	
start:  
    ;--------------------------------------
    ; 1. Initialize SPI module
    ;--------------------------------------
    call    SPI_MasterInit
    ;--------------------------------------
    ; 2. Load FSR0 with address of database
    ;--------------------------------------
    lfsr    0, database      ; FSR0 ? points to first byte of table
    ;--------------------------------------
    ; 3. Select how many bytes to send
    ;--------------------------------------
    movlw   5                ; database has 5 bytes
    call    SPI_SendBuffer   ; transmit 5 bytes through SPI
Forever:
    bra     Forever          ; stop here and loop forever
	
database:
    db 0x07, 0xA0, 0x24, 0x56, 0xFF
	
SPI_MasterInit:
    ; Configure SSP2STAT: CKE = 0 (bit 6 of SSP2STAT)
    bcf     SSP2STAT, 6, A       ; CKE = 0 (transmit on idle to active)
    
    ; Configure SSP2CON1 for SPI Master mode
    ; Bit 5 = SSPEN (enable), Bit 4 = CKP (clock polarity)
    ; Bits 3-0 = SSPM (0010 for Fosc/64)
    movlw   0x32          ; SSPEN=1, CKP=1, SSPM=0010
    movwf   SSP2CON1, A
    
    ; Set SDO2 and SCK2 as outputs
    bcf     TRISD, 5, A          ; SDO2 output (RD5)
    bcf     TRISD, 6, A          ; SCK2 output (RD6)
    return
		     
SPI_MasterTransmit:  
    movwf   SSP2BUF, A           ; Write data to buffer (starts transmission)
Wait_Transmit:
    btfss   PIR2, 5, A           ; Wait for SSP2IF (bit 5 in PIR2)
    bra     Wait_Transmit
    bcf     PIR2, 5, A           ; Clear interrupt flag
    return

Send_One_Byte:
    movf    MyByte, W, A
    call    SPI_MasterTransmit
    return

SPI_SendBuffer:      ; W contains count before calling
    movwf   CountTemp, A         ; save count
NextByte:
    movf    POSTINC0, W, A       ; read next byte from buffer (auto-increment)
    call    SPI_MasterTransmit
    decfsz  CountTemp, F, A
    bra     NextByte
    return

    end