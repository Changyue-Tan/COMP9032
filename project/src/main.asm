.include "m2560def.inc"

; --------------------------------------------------------------------------------------------------------------- ;
; --------------------------------------------- Includes ------------------------------------------------;
; --------------------------------------------------------------------------------------------------------------- ;
; must preserve this order of include
.include "data_memory_macros.asm"
.include "keypad_defs_and_macros.asm"
.include "lcd_defs_and_macros.asm"

; --------------------------------------------------------------------------------------------------------------- 
; ---------------------------------------------- Data Memroy Space Variables --------------------------------------------- 
; --------------------------------------------------------------------------------------------------------------- 
.dseg

Temp_Counter:    		.byte 2 
Seconds_Counter:		.byte 2

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Interrupt Vectors ------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
.cseg

.org 0x0000
	rjmp RESET

.org OVF0addr
	jmp Timer0OVF ; Jump to the interrupt handler for Timer0 overflow. 

; --------------------------------------------------------------------------------------------------------------- ;
; -----------------------------------------------  Interrupt Service Routine ------------------------------------ ;
; --------------------------------------------------------------------------------------------------------------- ;
RESET:
	CLEAR_TWO_BYTE_IN_DATA_MEMORY Temp_Counter ; Initialize the counter to 0
	CLEAR_TWO_BYTE_IN_DATA_MEMORY Seconds_Counter
    rcall interupt_setup
	rjmp main 

Timer0OVF: ; interrupt subroutine for Timer0
	push r16 ; Prologue starts.
	in r16, SREG
	push r16 

	INCREMENT_TWO_BYTE_IN_DATA_MEMORY Temp_Counter

    DATA_MEMORY_PROLOGUE
    ldi YL, low(Temp_Counter) 
	ldi YH, high(Temp_Counter)
	ld r24, Y+ 
	ld r25, Y

	cpi r24, low(1000) 
	brne continue_counting
	cpi r25, high(1000) 
	brne continue_counting
	
	INCREMENT_TWO_BYTE_IN_DATA_MEMORY Seconds_Counter

	; use the LED bars as a couner 
	DATA_MEMORY_PROLOGUE
	ldi YL, low(Seconds_Counter) 
	ldi YH, high(Seconds_Counter)
	ld r24, Y
	out PORTC, r24
	DATA_MEMORY_EPILOGUE

	rcall show_Seconds_Counter_data
	
	; reset the counter that counts for 1 second
	CLEAR_TWO_BYTE_IN_DATA_MEMORY Temp_Counter 
	
	continue_counting:
		DATA_MEMORY_EPILOGUE
		pop r16
		out SREG, r16
		pop r16
		reti ; Return from the interrupt.

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Main Program ------- ---------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;

main:

	rcall setup_LCD

	ser r16 ; set Port C as output
	out DDRC, r16
	ldi r16, 0b11111111	; out put 0b00001111 to leds
	out PORTC, r16

	; Port D Pin 7 => RDX4 => OpO, OpO falling edge when 1/4 circule spinned
	clr r16 ; set Port D as input
	out DDRD, r16
	ser r16 ; pull up
	out PORTD, r16

infinite_loop:
    rjmp infinite_loop

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Subrutines ------------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
interupt_setup:
    ldi r16, 0b00000000
	out TCCR0A, r16
	ldi r16, 0b00000011
	out TCCR0B, r16 ; Prescaler value=64, counting 1024 us
	
	ldi r16, 1<<TOIE0
	sts TIMSK0, r16 ; T/C0 interrupt enable
	
	;ldi r16, (2 << ISC00) ; set INT0 as falling edge triggered interrupt
	;sts EICRA, r16 ; Store Direct to data space
	;in r16, EIMSK ; enable INT0
	;ori r16, (1<<INT0)
	;out EIMSK, r16
	
	sei ; Enable global interrupt

    ret

show_Seconds_Counter_data:
	REFRESH_LCD
	DO_LCD_DISPLAY_2_BYTE_NUMBER_FROM_DATA_MEMEORY_ADDRESS Seconds_Counter
	ret

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Functions ------------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
.include "sleep_functions.asm"
.include "lcd_functions.asm"
.include "keypad_functions.asm"

