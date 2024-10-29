; 2024/10/29 
; COMP9032 Microprocessors and Interfacing
; Lab 4

; OpO => TDX2 => PortD Bit 5


.include "m2560def.inc"
.include "lcd_defs.asm"
.include "lcd_macros.asm"

.def temp = r16
.def leds = r17
.def speed = r18

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Macros ------------------------------------------------ ;
; --------------------------------------------------------------------------------------------------------------- ;

; The macro clears a word (2 bytes) in the data memory
; The parameter @0 is the memory address for that word
.macro Clear
	ldi YL, low(@0) ; load the memory address to Y
	ldi YH, high(@0)
	clr temp
	st Y+, temp ; clear the two bytes at @0 in SRAM
	st Y, temp
.endmacro


; --------------------------------------------------------------------------------------------------------------- 
; ------------------------------------------------------- Variables --------------------------------------------- 
; --------------------------------------------------------------------------------------------------------------- 
.dseg

Counter:    	.byte 2 ; unnecessary, but it works now, so do not change it

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
	
	ldi YL, low(Counter) ; Load the address of the counter.
	ldi YH, high(Counter) 
	ld r24, Y+ ; Load the value of the  counter.
	ld r25, Y
	adiw r25:r24, 1 ; Increase the  counter by one.
	cpi r24, low(1000) ; 0.1 seconds, 100 ms
	brne NotSecond
	cpi r25, high(1000) ; 0.1 seconds, 100 ms
	brne NotSecond
	
	com leds
	out PORTC, leds
	Clear Counter ; Reset the  counter.
	
	rcall LCD_display_result
	do_lcd_data_from_immediate 'B'

	clr speed ; ; Reset the  Speed.
	
	rjmp endif
	
	NotSecond:
		st Y, r25 ; Store the value of the counter.
		st -Y, r24
	
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

	ldi leds, 0xff ; Init pattern displayed
	out PORTC, leds
	ldi leds, 0b00001111
	Clear Counter ; Initialize the counter to 0
	ldi temp, 0b00000000
	out TCCR0A, temp
	ldi temp, 0b00000011
	out TCCR0B, temp ; Prescaler value=64, counting 1024 us
	ldi temp, 1<<TOIE0
	sts TIMSK0, temp ; T/C0 interrupt enable
	sei ; Enable global interrupt

	clr speed

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
		do_lcd_data_from_immediate 'A'
		inc speed
		rjmp loop


; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Functions ------------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
.include "sleep_functions.asm"
.include "lcd_functions.asm"
