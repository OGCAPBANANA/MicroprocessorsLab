#include <xc.inc>


; Port Definitions - Adjust based on your hardware connections
GLCD_DATA    EQU     PORTD      ; 8-bit data bus
GLCD_CTRL    EQU     PORTB      ; Control signals

; Control Pin Definitions
     RS          EQU     2          ; PORTB, bit 0 - Register Select
     RW_mine     EQU     3          ; PORTB, bit 1 - Read/Write  
     EN          EQU     4          ; PORTB, bit 2 - Enable
     CS1         EQU     0          ; PORTB, bit 3 - Chip Select 1 (left controller)
     CS2         EQU     1          ; PORTB, bit 4 - Chip Select 2 (right controller)
	 

;Variables in access RAM
psect	 UDATA
temp:    ds     1
temp2:    ds     1    ; Add second variable
    
; Code Section
psect    CODE
    ORG     0x0000
    GOTO    Main


; Delay subroutine - approximately 1ms
Delay:
    MOVLW   0x50
    MOVWF   temp          ; initialize temp
Delay_Loop:
    DECFSZ  temp, F       ; decrement temp, skip if zero
    BRA     Delay_Loop    ; Use BRA instead of GOTO
    RETURN

; Longer delay using Delay() as inner loop
Long_Delay:
    MOVLW   0x5
    MOVWF   temp2         ; Use temp2 instead of temp
Long_Delay_Outer:
    CALL    Delay
    DECFSZ  temp2, F      ; Use temp2 instead of temp
    BRA     Long_Delay_Outer
    RETURN
; Send command to GLCD
    
; Input: WREG contains command byte
GLCD_Command:
    BCF     GLCD_CTRL, RS      ; RS=0 for command
    BCF     GLCD_CTRL, RW_mine ; R/W=0 for write
    MOVWF   GLCD_DATA          ; Send command on data bus
    BSF     GLCD_CTRL, EN      ; Pulse enable high
    NOP
    BCF     GLCD_CTRL, EN      ; Pulse enable low (FIXED - was commented!)
    CALL    Delay              ; Wait for command to process
    RETURN
    
GLCD_WriteData:
    BSF     GLCD_CTRL, RS      ; RS=1 for data (FIXED - was BCF!)
    BCF     GLCD_CTRL, RW_mine ; RW=0 (write)
    MOVWF   GLCD_DATA          ; Put data on port
    BSF     GLCD_CTRL, EN      ; Enable pulse
    NOP
    BCF     GLCD_CTRL, EN
    CALL    Delay
    RETURN
    
GLCD_SetPage:
    ; Command = 0xB8 + page
    ADDLW   0xB8
    CALL    GLCD_Command
    RETURN

; Set column (Y = 0?63 per controller)
GLCD_SetColumn:
    ; Command = 0x40 + column
    ADDLW   0x40
    CALL    GLCD_Command
    RETURN
    
; Initialize GLCD
Init_GLCD:
    ; Set data port as output
    CLRF    TRISD
    
    ; Set control port as output
    CLRF    TRISB              ; Changed to CLRF for clarity
    
    ; Deselect both controllers initially (active low!)
    BSF     GLCD_CTRL, CS1     ; FIXED - deselect
    BSF     GLCD_CTRL, CS2     ; FIXED - deselect
    
    ; Wait for GLCD to power up
    CALL    Long_Delay
    
    ; Initialize left controller (CS1)
    BCF     GLCD_CTRL, CS1     ; FIXED - Select left (active low)
    BSF     GLCD_CTRL, CS2     ; FIXED - Deselect right
    
    MOVLW   0x3F               ; FIXED - Display ON (was 0x3E = OFF!)
    CALL    GLCD_Command
    
    MOVLW   0x40               ; Set Y address to 0
    CALL    GLCD_Command
    
    MOVLW   0xB8               ; Set page address to 0
    CALL    GLCD_Command
    
    MOVLW   0xC0               ; Set start line to 0
    CALL    GLCD_Command
    
    ; Initialize right controller (CS2)  
    BSF     GLCD_CTRL, CS1     ; FIXED - Deselect left
    BCF     GLCD_CTRL, CS2     ; FIXED - Select right
    
    MOVLW   0x3F               ; FIXED - Display ON (was 0x3E!)
    CALL    GLCD_Command
    
    MOVLW   0x40               ; Set Y address to 0
    CALL    GLCD_Command
    
    MOVLW   0xB8               ; Set page address to 0
    CALL    GLCD_Command
    
    MOVLW   0xC0               ; Set start line to 0
    CALL    GLCD_Command
    
    RETURN

; Turn on both displays (This might be redundant now)
GLCD_DisplayOn:
    ; Turn on left display
    BCF     GLCD_CTRL, CS1     ; Select left
    BSF     GLCD_CTRL, CS2     ; Deselect right
    
    MOVLW   0x3F               ; FIXED - Display ON (was 0x3E!)
    CALL    GLCD_Command
    
    ; Turn on right display
    BSF     GLCD_CTRL, CS1     ; Deselect left
    BCF     GLCD_CTRL, CS2     ; Select right
    
    MOVLW   0x3F               ; FIXED - Display ON (was 0x3E!)
    CALL    GLCD_Command
    
    ; Deselect both for safety
    BSF     GLCD_CTRL, CS1
    BSF     GLCD_CTRL, CS2
    
    RETURN

; Main program
Main:
    CALL    Init_GLCD          ; Initialize the GLCD
    CALL    GLCD_DisplayOn     ; Turn on the display
    CALL    Display_HELLO
    
Display_HELLO:
    ; Select only left controller (0?63 pixels)
    BCF     GLCD_CTRL, CS1
    BSF     GLCD_CTRL, CS2

    ; Draw on page 0 (top 8 rows)
    MOVLW   0x00
    CALL    GLCD_SetPage

    ; Start at column 0
    MOVLW   0x00
    CALL    GLCD_SetColumn

    ; ---- H ----
    MOVLW   0x7F    ; #######
    CALL    GLCD_WriteData
    MOVLW   0x08
    CALL    GLCD_WriteData
    MOVLW   0x08
    CALL    GLCD_WriteData
    MOVLW   0x08
    CALL    GLCD_WriteData
    MOVLW   0x7F
    CALL    GLCD_WriteData
    MOVLW   0x00    ; spacing column
    CALL    GLCD_WriteData

    ; ---- E ----
    MOVLW   0x7F
    CALL    GLCD_WriteData
    MOVLW   0x49
    CALL    GLCD_WriteData
    MOVLW   0x49
    CALL    GLCD_WriteData
    MOVLW   0x49
    CALL    GLCD_WriteData
    MOVLW   0x41
    CALL    GLCD_WriteData
    MOVLW   0x00
    CALL    GLCD_WriteData

    ; ---- L ----
    MOVLW   0x7F
    CALL    GLCD_WriteData
    MOVLW   0x01
    CALL    GLCD_WriteData
    MOVLW   0x01
    CALL    GLCD_WriteData
    MOVLW   0x01
    CALL    GLCD_WriteData
    MOVLW   0x01
    CALL    GLCD_WriteData
    MOVLW   0x00
    CALL    GLCD_WriteData

    ; ---- L ---- (second L)
    MOVLW   0x7F
    CALL    GLCD_WriteData
    MOVLW   0x01
    CALL    GLCD_WriteData
    MOVLW   0x01
    CALL    GLCD_WriteData
    MOVLW   0x01
    CALL    GLCD_WriteData
    MOVLW   0x01
    CALL    GLCD_WriteData
    MOVLW   0x00
    CALL    GLCD_WriteData

    ; ---- O ----
    MOVLW   0x3E
    CALL    GLCD_WriteData
    MOVLW   0x41
    CALL    GLCD_WriteData
    MOVLW   0x41
    CALL    GLCD_WriteData
    MOVLW   0x41
    CALL    GLCD_WriteData
    MOVLW   0x3E
    CALL    GLCD_WriteData
    MOVLW   0x00
    CALL    GLCD_WriteData

    RETURN
    
    ; Your main program loop here
Main_Loop:
    ; Add your application code here
    
    BRA     Main_Loop          ; Infinite loop

    END