; 2024/10/29 
; COMP9032 Microprocessors and Interfacing
; Interupt_1_demo


.include "m2560def.inc"

.def temp = r16
.def output = r17
.def count = r18 ; count the number of interrupts
.equ PATTERN = 0b00001111
.equ MAX_COUNT = 0x05
.equ MAX_PATTERN = 0xFF


; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Interrupt Vectors ------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
.cseg
.org 0x0000
	rjmp RESET

.org INT0addr ; location for INT0 vector, defined in m2560def.inc
	jmp EXT_INT0 ; INT0 vector

.org INT1addr
	jmp EXT_INT1 ; vector for INT1

; --------------------------------------------------------------------------------------------------------------- ;
; -----------------------------------------------  interrupt service routine ------------------------------------ ;
; --------------------------------------------------------------------------------------------------------------- ;
RESET:
	ser temp ; set Port C as output
	out DDRC, temp
	out PORTC, temp
	ldi output, PATTERN

	ldi temp, 0b00000010
	out DDRD, temp ; set Port D bit 1 as output
	out PORTD, temp

	ldi temp, (2 << ISC00) | (2 << ISC10) ; set INT0 and INI1 as falling edge triggered interrupt
	sts EICRA, temp ; Store Direct to data space
	
	in temp, EIMSK ; take note on which interupts are already enabled
	ori temp, (1<<INT0) | (1<<INT1) ; enable INT0 and INT1, keep others the same
	out EIMSK, temp
	
	sei ; enable Global Interrupt
	jmp main

EXT_INT0:
	push temp ; save register
	in temp, SREG ; save SREG
	push temp
	
	com output ; One’s Complement to flip the pattern
	out PORTC, output
	inc count

	rcall sleep_625ms
	
	pop temp ; restore SREG
	out SREG, temp
	pop temp ; restore register
	reti

EXT_INT1:
	push temp
	in temp, SREG
	push temp

	ldi output, MAX_PATTERN
	out PORTC, output

	rcall sleep_625ms 
	
	ldi output, PATTERN ; set pattern for normal LED display
	sbi PORTD, 1 ; set bit for INT1
	pop temp
	out SREG, temp
	pop temp
	reti

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Main Program ------- ---------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
main:
	clr count
	clr temp

	loop:
		inc temp 
		cpi count, MAX_COUNT 
		breq max_value_reached 
		rjmp loop

	max_value_reached:
		cbi PORTD, 1 ; clear bit 1 - generates INT1 request by falling edge
		clr count ; prepare for the next sw interrupt
		rjmp loop


; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Subroutines ------------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
.include "sleep_functions.asm"
