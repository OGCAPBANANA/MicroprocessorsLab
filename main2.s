;===============================================================================
; PIC18F87K22 GLCD (KS0108) Driver - Clean Build
;===============================================================================

#include <xc.inc>

;-------------------------------------------------------------------------------
; CONFIGURATION BITS
;-------------------------------------------------------------------------------
; NOTE: These are commented out because you have a 'config.s' file in your 
; project that already sets them. 
;
; **IMPORTANT**: Ensure your config.s has:
;   CONFIG FOSC = INTIO2   (Internal Oscillator)
;   CONFIG WDTEN = OFF     (Watchdog Timer OFF)
;-------------------------------------------------------------------------------
; CONFIG FOSC = INTIO2    
; CONFIG PLLCFG = OFF     
; CONFIG WDTEN = OFF      
; CONFIG MCLRE = ON       
; CONFIG XINST = OFF      
; CONFIG SOSCSEL = DIG    

;-------------------------------------------------------------------------------
; Hardware Configuration
;-------------------------------------------------------------------------------
; Registers for 18F87K22
DATA_LAT        EQU     LATD
DATA_PORT       EQU     PORTD
DATA_TRIS       EQU     TRISD

CTRL_LAT        EQU     LATB
CTRL_PORT       EQU     PORTB
CTRL_TRIS       EQU     TRISB

; Analog Control Registers (Banked 0xF5D - 0xF5F)
ANCON0_REG      EQU     0xF5D
ANCON1_REG      EQU     0xF5E
ANCON2_REG      EQU     0xF5F

; Pin Definitions
CS1_BIT         EQU     0   ; RB0
CS2_BIT         EQU     1   ; RB1
RS_BIT          EQU     2   ; RB2
RW_BIT          EQU     3   ; RB3
EN_BIT          EQU     4   ; RB4
RST_BIT         EQU     5   ; RB5

; GLCD Commands
CMD_DISPLAY_ON  EQU     0x3F
CMD_DISPLAY_OFF EQU     0x3E
CMD_SET_Y       EQU     0x40
CMD_SET_X       EQU     0xB8
CMD_START_LINE  EQU     0xC0

;-------------------------------------------------------------------------------
; Variables (Access Bank)
;-------------------------------------------------------------------------------
psect   udata_acs
outer_counter:  DS  1
inner_counter:  DS  1
delay_counter2: DS  1
delay_counter3: DS  1
save_wreg:      DS  1
loop_counter:   DS  1

target_x:       DS  1
target_page:    DS  1
grid_count:     DS  1

;-------------------------------------------------------------------------------
; Reset Vector
;-------------------------------------------------------------------------------
psect   code, abs
org     0x0000
    GOTO    Start

psect   code
;===============================================================================
; STARTUP
;===============================================================================
Start:
    ; 1. Configure Oscillator (16MHz)
    MOVLB   0                   ; Select Bank 0
    MOVLW   0x70                ; IRCF = 111 (16MHz HFINTOSC)
    MOVWF   OSCCON, A
    
    ; 2. Wait for stabilization
    CALL    Delay_100ms
    
    ; 3. Go to Main
    GOTO    Main

;===============================================================================
; DELAY ROUTINES (Safe Logic)
;===============================================================================
; 1ms at 16MHz (approx 4000 cycles)
Delay_1ms:
    MOVLW   0x06                ; Outer loop = 6
    MOVWF   outer_counter, A
OuterLoop:
    MOVLW   0xFF                ; Inner loop = 255
    MOVWF   inner_counter, A
InnerLoop:
    NOP
    DECFSZ  inner_counter, F, A
    BRA     InnerLoop
    
    DECFSZ  outer_counter, F, A
    BRA     OuterLoop
    RETURN

Delay_100ms:
    MOVLW   100
    MOVWF   delay_counter2, A
Delay_100_Loop:
    CALL    Delay_1ms
    DECFSZ  delay_counter2, F, A
    BRA     Delay_100_Loop
    RETURN

Delay_500ms:
    MOVLW   5
    MOVWF   delay_counter3, A
Delay_500_Loop:
    CALL    Delay_100ms
    DECFSZ  delay_counter3, F, A
    BRA     Delay_500_Loop
    RETURN

;===============================================================================
; LOW-LEVEL GLCD (Using LATCH & Access Bank)
;===============================================================================

Select_Left:
    BCF     CTRL_LAT, CS1_BIT, A
    BSF     CTRL_LAT, CS2_BIT, A
    RETURN

Select_Right:
    BSF     CTRL_LAT, CS1_BIT, A
    BCF     CTRL_LAT, CS2_BIT, A
    RETURN

Deselect_All:
    BSF     CTRL_LAT, CS1_BIT, A
    BSF     CTRL_LAT, CS2_BIT, A
    RETURN

; Send Command (RS=0)
GLCD_Command:
    MOVWF   save_wreg, A
    BCF     CTRL_LAT, RS_BIT, A
    BCF     CTRL_LAT, RW_BIT, A
    
    MOVF    save_wreg, W, A
    MOVWF   DATA_LAT, A
    
    BSF     CTRL_LAT, EN_BIT, A
    NOP
    NOP
    BCF     CTRL_LAT, EN_BIT, A
    
    CALL    Delay_1ms
    MOVF    save_wreg, W, A
    RETURN

; Send Data (RS=1)
GLCD_WriteData:
    MOVWF   save_wreg, A
    BSF     CTRL_LAT, RS_BIT, A
    BCF     CTRL_LAT, RW_BIT, A
    
    MOVF    save_wreg, W, A
    MOVWF   DATA_LAT, A
    
    BSF     CTRL_LAT, EN_BIT, A
    NOP
    NOP
    BCF     CTRL_LAT, EN_BIT, A
    
    NOP
    NOP
    MOVF    save_wreg, W, A
    RETURN

;===============================================================================
; SMART CURSOR
;===============================================================================
GLCD_Set_Cursor:
    MOVLW   64
    SUBWF   target_x, W, A      ; W = x - 64
    BC      Is_Right_Chip       ; Carry set if x >= 64
    
Is_Left_Chip:
    CALL    Select_Left
    MOVF    target_x, W, A
    BRA     Send_Cursor_Cmds

Is_Right_Chip:
    CALL    Select_Right
    MOVLW   64
    SUBWF   target_x, W, A      ; Calculate relative column

Send_Cursor_Cmds:
    ADDLW   CMD_SET_Y           ; 0x40 base
    CALL    GLCD_Command
    
    MOVF    target_page, W, A
    ADDLW   CMD_SET_X           ; 0xB8 base
    CALL    GLCD_Command
    RETURN

;===============================================================================
; GRAPHICS
;===============================================================================

GLCD_Clear:
    CLRF    target_page, A
Clear_Page_Loop:
    CLRF    target_x, A
Clear_Col_Loop:
    CALL    GLCD_Set_Cursor
    MOVLW   0x00
    CALL    GLCD_WriteData
    
    INCF    target_x, F, A
    MOVLW   128
    CPFSEQ  target_x, A
    BRA     Clear_Col_Loop
    
    INCF    target_page, F, A
    MOVLW   0x08
    CPFSEQ  target_page, A
    BRA     Clear_Page_Loop
    RETURN

Draw_Vertical_Line:
    CLRF    target_page, A
Line_Loop:
    CALL    GLCD_Set_Cursor
    MOVLW   0xFF
    CALL    GLCD_WriteData
    
    INCF    target_page, F, A
    MOVLW   0x08
    CPFSEQ  target_page, A
    BRA     Line_Loop
    RETURN

Draw_Even_Grid:
    MOVLW   0x07
    MOVWF   grid_count, A
    MOVLW   0x10                ; Start at 16
    MOVWF   target_x, A
Grid_Loop:
    CALL    Draw_Vertical_Line
    MOVLW   0x10
    ADDWF   target_x, F, A
    DECFSZ  grid_count, F, A
    BRA     Grid_Loop
    CALL    Deselect_All
    RETURN

;===============================================================================
; INITIALIZATION (FIXED ANSEL)
;===============================================================================
GLCD_Init:
    ; 1. Configure ANCONx registers (Banked in Bank 15)
    ; ANCON0, ANCON1, ANCON2 must be cleared to 0 for Digital I/O
    
    MOVLB   15                  ; Select Bank 15
    CLRF    ANCON0_REG, 1       ; Clear ANCON0 (Banked)
    CLRF    ANCON1_REG, 1       ; Clear ANCON1 (Banked)
    CLRF    ANCON2_REG, 1       ; Clear ANCON2 (Banked)
    MOVLB   0                   ; Return to Bank 0
    
    ; 2. Set Directions
    CLRF    DATA_TRIS, A
    CLRF    CTRL_TRIS, A
    
    ; 3. Reset Sequence
    BCF     CTRL_LAT, RST_BIT, A
    CALL    Delay_100ms
    BSF     CTRL_LAT, RST_BIT, A
    CALL    Delay_500ms
    
    ; 4. Init LCD Chips
    CALL    Select_Left
    MOVLW   CMD_DISPLAY_ON
    CALL    GLCD_Command
    MOVLW   CMD_START_LINE
    CALL    GLCD_Command
    
    CALL    Select_Right
    MOVLW   CMD_DISPLAY_ON
    CALL    GLCD_Command
    MOVLW   CMD_START_LINE
    CALL    GLCD_Command
    
    CALL    Deselect_All
    RETURN

;===============================================================================
; MAIN
;===============================================================================
Main:
    CALL    GLCD_Init
    CALL    GLCD_Clear
    CALL    Draw_Even_Grid
    
Main_Loop:
    NOP
    BRA     Main_Loop

    END