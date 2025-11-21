;===============================================================================
; PIC18F GLCD (KS0108) Driver - Clean Implementation
; Displays a test pattern and text on 128x64 GLCD
;===============================================================================

#include <xc.inc>

;-------------------------------------------------------------------------------
; Hardware Configuration
;-------------------------------------------------------------------------------
; Data Bus: PORTD (RD0-RD7) - 8-bit parallel data
; Control:  PORTB
;   RB0 = CS1 (Left controller, columns 0-63)
;   RB1 = CS2 (Right controller, columns 64-127)
;   RB2 = RS  (Register Select: 0=Command, 1=Data)
;   RB3 = RW  (Read/Write: 0=Write, 1=Read)
;   RB4 = EN  (Enable strobe)

;-------------------------------------------------------------------------------
; Constants
;-------------------------------------------------------------------------------
; Port assignments
DATA_PORT       EQU     PORTD
DATA_TRIS       EQU     TRISD
CTRL_PORT       EQU     PORTB
CTRL_TRIS       EQU     TRISB

; Control pin bit positions
CS1_BIT         EQU     0
CS2_BIT         EQU     1
RS_BIT          EQU     2
RW_BIT          EQU     3
EN_BIT          EQU     4

; GLCD Commands
CMD_DISPLAY_ON  EQU     0x3F
CMD_DISPLAY_OFF EQU     0x3E
CMD_SET_Y       EQU     0x40    ; Y address (column) base
CMD_SET_X       EQU     0xB8    ; X address (page) base
CMD_START_LINE  EQU     0xC0    ; Display start line base

;-------------------------------------------------------------------------------
; Variables
;-------------------------------------------------------------------------------
psect   udata_acs
delay_counter1: DS  1
delay_counter2: DS  1
delay_counter3: DS  1
save_wreg:      DS  1           ; For preserving WREG
loop_counter:   DS  1

;-------------------------------------------------------------------------------
; Reset Vector
;-------------------------------------------------------------------------------
psect   resetVec, class=CODE, reloc=2
resetVec:
    GOTO    Main

;-------------------------------------------------------------------------------
; Main Code Section
;-------------------------------------------------------------------------------
psect   code

;===============================================================================
; DELAY ROUTINES
;===============================================================================

;-------------------------------------------------------------------------------
; Short delay (~1ms at 4MHz) 
;-------------------------------------------------------------------------------
Delay_1ms:
    MOVLW   0xFA
    MOVWF   delay_counter1
Delay_1ms_loop:
    NOP
    NOP
    DECFSZ  delay_counter1, F
    BRA     Delay_1ms_loop
    RETURN

;-------------------------------------------------------------------------------
; Medium delay (~100ms)
;-------------------------------------------------------------------------------
Delay_100ms:
    MOVLW   0x64                ; 100 iterations
    MOVWF   delay_counter2
Delay_100ms_loop:
    CALL    Delay_1ms
    DECFSZ  delay_counter2, F
    BRA     Delay_100ms_loop
    RETURN

;-------------------------------------------------------------------------------
; Long delay (~500ms) for power-up
;-------------------------------------------------------------------------------
Delay_500ms:
    MOVLW   0x05
    MOVWF   delay_counter3
Delay_500ms_loop:
    CALL    Delay_100ms
    DECFSZ  delay_counter3, F
    BRA     Delay_500ms_loop
    RETURN

;===============================================================================
; LOW-LEVEL GLCD FUNCTIONS
;===============================================================================

;-------------------------------------------------------------------------------
; Select left controller (CS1)
;-------------------------------------------------------------------------------
Select_Left:
    BCF     CTRL_PORT, CS1_BIT  ; CS1 = 0 (active low)
    BSF     CTRL_PORT, CS2_BIT  ; CS2 = 1 (inactive)
    RETURN

;-------------------------------------------------------------------------------
; Select right controller (CS2)
;-------------------------------------------------------------------------------
Select_Right:
    BSF     CTRL_PORT, CS1_BIT  ; CS1 = 1 (inactive)
    BCF     CTRL_PORT, CS2_BIT  ; CS2 = 0 (active low)
    RETURN

;-------------------------------------------------------------------------------
; Select both controllers
;-------------------------------------------------------------------------------
Select_Both:
    BCF     CTRL_PORT, CS1_BIT  ; CS1 = 0 (active)
    BCF     CTRL_PORT, CS2_BIT  ; CS2 = 0 (active)
    RETURN

;-------------------------------------------------------------------------------
; Deselect all controllers
;-------------------------------------------------------------------------------
Deselect_All:
    BSF     CTRL_PORT, CS1_BIT  ; CS1 = 1 (inactive)
    BSF     CTRL_PORT, CS2_BIT  ; CS2 = 1 (inactive)
    RETURN

;-------------------------------------------------------------------------------
; Send command to GLCD
; Input: WREG = command byte
; Note: WREG is preserved
;-------------------------------------------------------------------------------
GLCD_Command:
    MOVWF   save_wreg           ; Save WREG
    
    BCF     CTRL_PORT, RS_BIT   ; RS = 0 (command mode)
    BCF     CTRL_PORT, RW_BIT   ; RW = 0 (write)
    
    MOVF    save_wreg, W        ; Restore WREG
    MOVWF   DATA_PORT           ; Output command
    
    NOP
    NOP
    BSF     CTRL_PORT, EN_BIT   ; EN = 1 (start pulse)
    NOP
    NOP
    NOP
    NOP
    BCF     CTRL_PORT, EN_BIT   ; EN = 0 (end pulse)
    NOP
    NOP
    
    CALL    Delay_1ms           ; Command execution time
    
    MOVF    save_wreg, W        ; Restore WREG
    RETURN

;-------------------------------------------------------------------------------
; Write data to GLCD
; Input: WREG = data byte
; Note: WREG is preserved
;-------------------------------------------------------------------------------
GLCD_WriteData:
    MOVWF   save_wreg           ; Save WREG
    
    BSF     CTRL_PORT, RS_BIT   ; RS = 1 (data mode)
    BCF     CTRL_PORT, RW_BIT   ; RW = 0 (write)
    
    MOVF    save_wreg, W        ; Restore WREG
    MOVWF   DATA_PORT           ; Output data
    
    NOP
    NOP
    BSF     CTRL_PORT, EN_BIT   ; EN = 1 (start pulse)
    NOP
    NOP
    NOP
    NOP
    BCF     CTRL_PORT, EN_BIT   ; EN = 0 (end pulse)
    NOP
    NOP
    
    CALL    Delay_1ms           ; Data write time
    
    MOVF    save_wreg, W        ; Restore WREG
    RETURN

;===============================================================================
; HIGH-LEVEL GLCD FUNCTIONS
;===============================================================================

;-------------------------------------------------------------------------------
; Set page address (row, 0-7)
; Input: WREG = page number (0-7)
;-------------------------------------------------------------------------------
GLCD_SetPage:
    ADDLW   CMD_SET_X           ; Add page base command
    CALL    GLCD_Command
    RETURN

;-------------------------------------------------------------------------------
; Set column address (0-63 per controller)
; Input: WREG = column number (0-63)
;-------------------------------------------------------------------------------
GLCD_SetColumn:
    ADDLW   CMD_SET_Y           ; Add column base command
    CALL    GLCD_Command
    RETURN

;-------------------------------------------------------------------------------
; Clear entire screen
;-------------------------------------------------------------------------------
GLCD_Clear:
    ; Clear left half
    CALL    Select_Left
    
    MOVLW   0x00
    MOVWF   loop_counter        ; Start at page 0
    
Clear_Left_Loop:
    MOVF    loop_counter, W
    CALL    GLCD_SetPage        ; Set page
    
    MOVLW   0x00
    CALL    GLCD_SetColumn      ; Set column to 0
    
    ; Write 64 zeros
    MOVLW   0x40                ; 64 columns
    MOVWF   delay_counter1
Clear_Left_Col:
    MOVLW   0x00
    CALL    GLCD_WriteData
    DECFSZ  delay_counter1, F
    BRA     Clear_Left_Col
    
    INCF    loop_counter, F
    MOVLW   0x08
    CPFSEQ  loop_counter
    BRA     Clear_Left_Loop
    
    ; Clear right half
    CALL    Select_Right
    
    MOVLW   0x00
    MOVWF   loop_counter
    
Clear_Right_Loop:
    MOVF    loop_counter, W
    CALL    GLCD_SetPage
    
    MOVLW   0x00
    CALL    GLCD_SetColumn
    
    MOVLW   0x40
    MOVWF   delay_counter1
Clear_Right_Col:
    MOVLW   0x00
    CALL    GLCD_WriteData
    DECFSZ  delay_counter1, F
    BRA     Clear_Right_Col
    
    INCF    loop_counter, F
    MOVLW   0x08
    CPFSEQ  loop_counter
    BRA     Clear_Right_Loop
    
    CALL    Deselect_All
    RETURN

;-------------------------------------------------------------------------------
; Initialize GLCD controller
; Input: W = controller to init (0=left, 1=right, 2=both)
;-------------------------------------------------------------------------------
GLCD_Init_Controller:
    ; Display ON
    MOVLW   CMD_DISPLAY_ON
    CALL    GLCD_Command
    
    ; Set start line to 0
    MOVLW   CMD_START_LINE
    CALL    GLCD_Command
    
    ; Set page to 0
    MOVLW   0x00
    CALL    GLCD_SetPage
    
    ; Set column to 0
    MOVLW   0x00
    CALL    GLCD_SetColumn
    
    CALL    Delay_100ms
    RETURN

;===============================================================================
; MAIN INITIALIZATION
;===============================================================================

;-------------------------------------------------------------------------------
; Initialize hardware and GLCD
;-------------------------------------------------------------------------------
GLCD_Init:
    ; Configure ports
    CLRF    DATA_TRIS           ; PORTD all outputs
    CLRF    CTRL_TRIS           ; PORTB all outputs
    
    ; Set control lines to safe state
    CLRF    DATA_PORT           ; Data = 0
    CLRF    CTRL_PORT           ; All control low
    
    CALL    Deselect_All        ; CS1=1, CS2=1
    BCF     CTRL_PORT, EN_BIT   ; EN=0
    BCF     CTRL_PORT, RS_BIT   ; RS=0
    BCF     CTRL_PORT, RW_BIT   ; RW=0
    
    ; Wait for power stabilization
    CALL    Delay_500ms
    
    ; Initialize left controller
    CALL    Select_Left
    CALL    GLCD_Init_Controller
    
    ; Initialize right controller
    CALL    Select_Right
    CALL    GLCD_Init_Controller
    
    ; Deselect all
    CALL    Deselect_All
    
    ; Clear the screen
    CALL    GLCD_Clear
    
    RETURN

;===============================================================================
; DISPLAY FUNCTIONS
;===============================================================================

;-------------------------------------------------------------------------------
; Draw a test pattern - vertical lines
;-------------------------------------------------------------------------------
Draw_TestPattern:
    CALL    Select_Left
    
    ; Draw on page 0
    MOVLW   0x00
    CALL    GLCD_SetPage
    MOVLW   0x00
    CALL    GLCD_SetColumn
    
    ; Draw alternating pattern
    MOVLW   0x20                ; 32 columns
    MOVWF   loop_counter
    
TestPattern_Loop:
    MOVLW   0xFF                ; Solid line
    CALL    GLCD_WriteData
    MOVLW   0x00                ; Space
    CALL    GLCD_WriteData
    
    DECFSZ  loop_counter, F
    BRA     TestPattern_Loop
    
    CALL    Deselect_All
    RETURN

;-------------------------------------------------------------------------------
; Display "HI" text on screen
;-------------------------------------------------------------------------------
Display_HI:
    CALL    Select_Left
    
    ; Position at page 2, column 20
    MOVLW   0x02
    CALL    GLCD_SetPage
    MOVLW   0x14                ; Column 20
    CALL    GLCD_SetColumn
    
    ; Draw 'H'
    MOVLW   0x7F                ; ???????
    CALL    GLCD_WriteData
    MOVLW   0x08                ;    ?
    CALL    GLCD_WriteData
    MOVLW   0x08                ;    ?
    CALL    GLCD_WriteData
    MOVLW   0x08                ;    ?
    CALL    GLCD_WriteData
    MOVLW   0x7F                ; ???????
    CALL    GLCD_WriteData
    
    ; Space
    MOVLW   0x00
    CALL    GLCD_WriteData
    MOVLW   0x00
    CALL    GLCD_WriteData
    
    ; Draw 'I'
    MOVLW   0x41                ; ?     ?
    CALL    GLCD_WriteData
    MOVLW   0x7F                ; ???????
    CALL    GLCD_WriteData
    MOVLW   0x41                ; ?     ?
    CALL    GLCD_WriteData
    
    CALL    Deselect_All
    RETURN

;-------------------------------------------------------------------------------
; Draw a border around the screen
;-------------------------------------------------------------------------------
Draw_Border:
    ; Top border (page 0, all columns)
    CALL    Select_Left
    MOVLW   0x00
    CALL    GLCD_SetPage
    MOVLW   0x00
    CALL    GLCD_SetColumn
    
    MOVLW   0x40                ; 64 columns
    MOVWF   loop_counter
Border_Top_Left:
    MOVLW   0x01                ; Top line only
    CALL    GLCD_WriteData
    DECFSZ  loop_counter, F
    BRA     Border_Top_Left
    
    CALL    Select_Right
    MOVLW   0x00
    CALL    GLCD_SetPage
    MOVLW   0x00
    CALL    GLCD_SetColumn
    
    MOVLW   0x40
    MOVWF   loop_counter
Border_Top_Right:
    MOVLW   0x01
    CALL    GLCD_WriteData
    DECFSZ  loop_counter, F
    BRA     Border_Top_Right
    
    ; Bottom border (page 7, all columns)
    CALL    Select_Left
    MOVLW   0x07
    CALL    GLCD_SetPage
    MOVLW   0x00
    CALL    GLCD_SetColumn
    
    MOVLW   0x40
    MOVWF   loop_counter
Border_Bottom_Left:
    MOVLW   0x80                ; Bottom line only
    CALL    GLCD_WriteData
    DECFSZ  loop_counter, F
    BRA     Border_Bottom_Left
    
    CALL    Select_Right
    MOVLW   0x07
    CALL    GLCD_SetPage
    MOVLW   0x00
    CALL    GLCD_SetColumn
    
    MOVLW   0x40
    MOVWF   loop_counter
Border_Bottom_Right:
    MOVLW   0x80
    CALL    GLCD_WriteData
    DECFSZ  loop_counter, F
    BRA     Border_Bottom_Right
    
    CALL    Deselect_All
    RETURN

;===============================================================================
; MAIN PROGRAM
;===============================================================================

Main:
    ; Initialize the GLCD
    CALL    GLCD_Init
    
    ; Draw border
    CALL    Draw_Border
    
    ; Draw test pattern on left side
    CALL    Draw_TestPattern
    
    ; Display "HI" text
    CALL    Display_HI
    
    ; Main loop - do nothing
Main_Loop:
    NOP
    BRA     Main_Loop

    END