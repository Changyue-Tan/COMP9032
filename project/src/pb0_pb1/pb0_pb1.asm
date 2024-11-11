.include "m2560def.inc"

; ---------------------------------------------------------------------------------------------------------------
; --------------------------------------------- Includes ----------------------------------------------------
; ---------------------------------------------------------------------------------------------------------------
; ?????????
.include "data_memory_macros.asm"
.include "keypad_defs_and_macros.asm"
.include "lcd_defs_and_macros.asm"

; --------------------------------------------------------------------------------------------------------------- 
; ---------------------------------------------- Data Memory Space Variables ------------------------------------ 
; --------------------------------------------------------------------------------------------------------------- 

.dseg

Temp_Counter:    		.byte 2 
Seconds_Counter:		.byte 2
; for queue data structure
Patients_Queue:			.byte 2560		; max number of patients pay day: 255
Next_Patient:			.byte 2			; pointer to next patient
Last_Patient:			.byte 2			; pointer to last patient
Space_For_New_Patient:	.byte 2			; pointer to the next avaliable space to store newly enqueued patient
Next_Patient_Number:	.byte 1			; a number between 0 - 255
Last_Patient_Number:	.byte 1			; a number between 0 - 255

; the input from keypad is stored here
Patient_Name:			.byte 10		; a char array with length of 10

; ---------------------------------------------------------------------------------------------------------------
; ------------------------------------------------------- Interrupt Vectors -------------------------------------
; ---------------------------------------------------------------------------------------------------------------
.cseg
; ???????????? m2560def.inc ?????
; ????????
.org 0x0000
    rjmp RESET

.org INT0addr
    rjmp EXT_INT0                ; INT0 ????

.org INT1addr
    rjmp EXT_INT1                ; INT1 ???? 

; ---------------------------------------------------------------------------------------------------------------
; -----------------------------------------------  Interrupt Service Routines ------------------------------------
; --------------------------------------------------------------------------------------------------------------- 

; RESET ??????
RESET:

    ; ??? LCD
    rcall setup_LCD               ; ??? LCD

    ; ??????
    ; ?????? INT0 ? INT1 ??????
    ldi r16, (2<<ISC00) | (2<<ISC10) ; ISC01=1, ISC00=0 ? ISC11=1, ISC10=0 ????????
    sts EICRA, r16               ; External Interrupt Control Register A

    ; ?? INT0 ? INT1 ??
    in r16, EIMSK                ; ??????????????
    ori r16, (1<<INT0) | (1<<INT1) ; ?? INT0 ? INT1 ?
    out EIMSK, r16               ; ????????????

    ; ??????
    sei                           ; Enable global interrupt

    ; ?????
    rjmp main 

; EXT_INT0 ?????? - PB0 ??????? displayMode ???
EXT_INT0:
    push r16
    in r16, SREG
    push r16

    rcall sleep_125ms          ; ??????????
	rcall setup_LCD
    DO_LCD_DATA_IMMEDIATE  'D'  
	DO_LCD_DATA_IMMEDIATE  's'          ; ?? displayMode ???

    pop r16
    out SREG, r16
    pop r16
    reti

; EXT_INT1 ?????? - PB1 ??????? DO_LCD_DATA_IMMEDIATE 'A'
EXT_INT1:
    push r16
    in r16, SREG
    push r16

    rcall sleep_125ms          ; ??????????
	rcall setup_LCD
    DO_LCD_DATA_IMMEDIATE  'A' 
	DO_LCD_DATA_IMMEDIATE  'S'  

    pop r16
    out SREG, r16
    pop r16
    reti

; ---------------------------------------------------------------------------------------------------------------
; ------------------------------------------------------- Main Program ---------------------------------------------
; --------------------------------------------------------------------------------------------------------------- 


main:
    ; ?? Port D Pin 2 ? Pin 3 ?????????????? INT0 ? INT1?
    clr r16                        ; ?? Port D ???
    out DDRD, r16
    ldi r16, (1<<PD2) | (1<<PD3)   ; ?? PD2 (INT0) ? PD3 (INT1) ????
    out PORTD, r16
	.include "displayMode.asm"
    rcall displayMode  

infinite_loop:
    ; ?????????????????
    rjmp infinite_loop

halt:
    rjmp halt

; ---------------------------------------------------------------------------------------------------------------
; ------------------------------------------------------- Functions -------------------------------------------
; --------------------------------------------------------------------------------------------------------------- 
.include "sleep_functions.asm"
.include "lcd_functions.asm"
.include "keypad_functions.asm"