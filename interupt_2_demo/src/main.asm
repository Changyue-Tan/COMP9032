; 2024/10/29 
; COMP9032 Microprocessors and Interfacing
; Interupt_2_demo: Timer


.include "m2560def.inc"

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Constants and definitions ----------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;

.equ PATTERN=0b11110000
.def temp = r16
.def leds = r17

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Macros ------------------------------------------------ ;
; --------------------------------------------------------------------------------------------------------------- ;

; The macro clears a word (2 bytes) in the data memory for the counter stored in the memory
; The parameter @0 is the memory address for that word
.macro Clear
	ldi YL, low(@0) ; load the memory address to Y
	ldi YH, high(@0)
	clr temp
	st Y+, temp ; clear the two bytes at @0 in SRAM
	st Y, temp
.endmacro

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Variables --------------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
.dseg
SecondCounter:
	.byte 2 ; Two-byte counter for counting the number of seconds.

TempCounter:
	.byte 2 ; Temporary counter. Used to determine if one second has passed (i.e. when TempCounter=1000) 

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
	
	ldi YL, low(TempCounter) ; Load the address of the temporary
	ldi YH, high(TempCounter) ; counter.
	ld r24, Y+ ; Load the value of the temporary counter.
	ld r25, Y
	adiw r25:r24, 1 ; Increase the temporary counter by one.
	cpi r24, low(1000) ; Check if (r25:r24)=1000
	brne NotSecond
	cpi r25, high(1000)
	brne NotSecond
	
	com leds
	out PORTC, leds
	Clear TempCounter ; Reset the temporary counter.
	
	ldi YL, low(SecondCounter) ; Load the address of the second
	ldi YH, high(SecondCounter) ; counter.
	ld r24, Y+ ; Load the value of the second counter.
	ld r25, Y
	adiw r25:r24, 1 ; Increase the second counter by one.
	st Y, r25 ; Store the value of the second counter.
	st -Y, r24
	rjmp endif
	
	NotSecond:
		st Y, r25 ; Store the value of the temporary counter.
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
	ldi leds, 0xff ; Init pattern displayed
	out PORTC, leds
	ldi leds, PATTERN
	Clear TempCounter ; Initialize the temporary counter to 0
	Clear SecondCounter ; Initialize the second counter to 0
	ldi temp, 0b00000000
	out TCCR0A, temp
	ldi temp, 0b00000011
	out TCCR0B, temp ; Prescaler value=64, counting 1024 us
	ldi temp, 1<<TOIE0
	sts TIMSK0, temp ; T/C0 interrupt enable
	sei ; Enable global interrupt
	
	loop:
		rjmp loop 

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Subroutines ------------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
.include "sleep_functions.asm"
