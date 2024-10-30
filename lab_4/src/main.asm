; 2024/10/29 
; COMP9032 Microprocessors and Interfacing
; Lab 4

; OpO => TDX2 => PortD Bit 5


.include "m2560def.inc"
.include "lcd_defs.asm"
.include "lcd_macros.asm"

.def temp = r16
.def leds = r17
.def num = r19

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Macros ------------------------------------------------ ;
; --------------------------------------------------------------------------------------------------------------- ;

; The macro clears a word (2 bytes) in the data memory
; The parameter @0 is the memory address for that word
.macro CLEAR_DATA_IN_MEMORY
	ldi YL, low(@0) ; load the memory address to Y
	ldi YH, high(@0)
	clr temp
	st Y+, temp ; clear the two bytes at @0 in SRAM
	st Y, temp
.endmacro

.macro INC_DATA_IN_MEMORY
	ldi YL, low(@0) ; load the memory address to Y
	ldi YH, high(@0)
	ld r24, Y+ 
	ld r25, Y
	adiw r25:r24, 1 
	st Y, r25 ; Store the value of the counter.
	st -Y, r24
.endmacro


; --------------------------------------------------------------------------------------------------------------- 
; ------------------------------------------------------- Variables --------------------------------------------- 
; --------------------------------------------------------------------------------------------------------------- 
.dseg

Counter:    	.byte 2 
Speed:			.byte 2

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Interrupt Vectors ------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
.cseg

.org 0x0000
	rjmp RESET

.org OVF0addr
	jmp Timer0OVF ; Jump to the interrupt handler for Timer0 overflow. 


; --------------------------------------------------------------------------------------------------------------- ;
; -----------------------------------------------  interrupt service routine ------------------------------------ ;
; --------------------------------------------------------------------------------------------------------------- ;
RESET:
	ser temp ; set Port C as output
	out DDRC, temp
	rjmp main 

Timer0OVF: ; interrupt subroutine for Timer0
	push temp ; Prologue starts.
	in temp, SREG
	push temp 
	push Yh ; Save all conflict registers in the prologue.
	push YL
	push r25
	push r24 ; Prologue ends.
	
	INC_DATA_IN_MEMORY Counter
	; DO_LCD_DATA_IMMEDIATE 'A'

	cpi r24, low(1000) 
	brne endif
	cpi r25, high(1000) 
	brne endif
	
	com leds
	out PORTC, leds
	; DO_LCD_DATA_IMMEDIATE 'A'

	rcall display_speed
	
	CLEAR_DATA_IN_MEMORY Counter ; Reset the  counter.
	; CLEAR_DATA_IN_MEMORY Speed
	INC_DATA_IN_MEMORY Speed
	
	endif:
		pop r24 ; Epilogue starts;
		pop r25 ; Restore all conflict registers from the stack.
		pop YL
		pop YH
		pop temp
		out SREG, temp
		pop temp
		reti ; Return from the interrupt.

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Main Program ------- ---------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;

main:

	rcall setup_LCD

	clr num

	ldi leds, 0xff ; Init pattern displayed
	out PORTC, leds
	ldi leds, 0b00001111
	CLEAR_DATA_IN_MEMORY Counter ; Initialize the counter to 0
	CLEAR_DATA_IN_MEMORY Speed
	ldi temp, 0b00000000
	out TCCR0A, temp
	ldi temp, 0b00000011
	out TCCR0B, temp ; Prescaler value=64, counting 1024 us
	ldi temp, 1<<TOIE0
	sts TIMSK0, temp ; T/C0 interrupt enable
	sei ; Enable global interrupt


	clr temp ; set Port D as input
	out DDRD, temp
	ser temp ; pull up
	out PORTD, temp

	loop:
		in temp, PIND
		andi temp, 0b00100000; Get bit 5
		cpi	temp, 0
		breq Received_light
		rjmp loop

	Received_light:
		DO_LCD_DATA_IMMEDIATE 'A'
		
		INC_DATA_IN_MEMORY Speed
		
		rjmp loop

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Subrutines ------------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;

display_speed:
	push Yh ; Save all conflict registers in the prologue.
	push YL
	push r25
	push r24 ; Prologue ends.

	ldi YL, low(Speed) 
	ldi YH, high(Speed) 
	ld r24, Y+ 
	ld r25, Y

	CLEAR_LCD

	; subi	r25,	-'0'
	; DO_LCD_DATA_REGISTER r25

	mov num, r25
	; inc num
	rcall LCD_display_1_byte_number
	; inc num
	mov num, r24
	rcall LCD_display_1_byte_number

	

	pop r24 ; Epilogue starts;
	pop r25 ; Restore all conflict registers from the stack.
	pop YL
	pop YH
	ret

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Functions ------------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
.include "sleep_functions.asm"
.include "lcd_functions.asm"
