; 2024/10/29 
; COMP9032 Microprocessors and Interfacing
; Lab 4

; OpO => TDX2 => PortD Bit 5


.include "m2560def.inc"

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- defs ------------------------------------------------ ;
; --------------------------------------------------------------------------------------------------------------- ;

.def temp = r16
.def leds = r19
.def num = r17

.include "lcd_defs.asm"

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Macros ------------------------------------------------ ;
; --------------------------------------------------------------------------------------------------------------- ;

.include "lcd_macros.asm"
.include "data_memory_macros.asm"

; --------------------------------------------------------------------------------------------------------------- 
; ------------------------------------------------------- Variables --------------------------------------------- 
; --------------------------------------------------------------------------------------------------------------- 
.dseg

Counter:    	.byte 2 
Speed:			.byte 2
;Number_LOW:		.byte 1
;Number_HIGH:	.byte 1

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Interrupt Vectors ------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
.cseg

.org 0x0000
	rjmp RESET

.org INT0addr
	rjmp EXT_INT0 ; vector for INT0

.org OVF0addr
	jmp Timer0OVF ; Jump to the interrupt handler for Timer0 overflow. 

; --------------------------------------------------------------------------------------------------------------- ;
; -----------------------------------------------  interrupt service routine ------------------------------------ ;
; --------------------------------------------------------------------------------------------------------------- ;
RESET:
	CLEAR_DATA_IN_MEMORY Counter ; Initialize the counter to 0
	CLEAR_DATA_IN_MEMORY Speed

	ldi temp, 0b00000000
	out TCCR0A, temp
	ldi temp, 0b00000011
	out TCCR0B, temp ; Prescaler value=64, counting 1024 us
	
	ldi temp, 1<<TOIE0
	sts TIMSK0, temp ; T/C0 interrupt enable
	
	ldi temp, (2 << ISC00) ; set INT0 as falling edge triggered interrupt
	sts EICRA, temp ; Store Direct to data space
	in temp, EIMSK ; enable INT0
	ori temp, (1<<INT0)
	out EIMSK, temp
	
	sei ; Enable global interrupt

	rjmp main 


EXT_INT0:
	push temp ; Prologue starts.
	in temp, SREG
	push temp 
	push YH ; Save all conflict registers in the prologue.
	push YL
	push r25
	push r24 ; Prologue ends.

	INC_DATA_IN_MEMORY Speed

	pop r24 ; Epilogue starts;
	pop r25 ; Restore all conflict registers from the stack.
	pop YL
	pop YH
	pop temp
	out SREG, temp
	pop temp

	reti ; Return from the interrupt.

Timer0OVF: ; interrupt subroutine for Timer0
	
	push temp ; Prologue starts.
	in temp, SREG
	push temp 
	push YH ; Save all conflict registers in the prologue.
	push YL
	push r25
	push r24 ; Prologue ends.

	INC_DATA_IN_MEMORY Counter

	cpi r24, low(1000) 
	brne continue_counting
	cpi r25, high(1000) 
	brne continue_counting
	
	; Since we have not branched, this means counter >= 1000
	com leds
	out PORTC, leds ; flip leds to signal passage of time
	
	; speed data is stored else where,
	REFRESH_LCD
	rcall display_speed
	; DO_LCD_DATA_IMMEDIATE 'B'
	
	CLEAR_DATA_IN_MEMORY Counter 
	CLEAR_DATA_IN_MEMORY Speed
	
	continue_counting:
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
	ser temp ; set Port C as output
	out DDRC, temp
	ldi leds, 0b01010101	; out put 0b00001111 to leds
	out PORTC, leds

	rcall setup_LCD
	
	clr temp ; set Port D as input
	out DDRD, temp
	ser temp ; pull up
	out PORTD, temp

loop:
	rjmp loop

; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Subrutines ------------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;

/*
display_speed:
	
	push YH ; Save all conflict registers in the prologue.
	push YL
	push r25
	push r24 ; Prologue ends.

	ldi YL, low(Speed) 
	ldi YH, high(Speed) 
	ld r24, Y+ 
	ld r25, Y

	REFRESH_LCD

	;ldi YL, low(Number_HIGH) 
	;ldi YH, high(Number_HIGH)

	;st  Y, r25
	;st  -Y, r24
	
	;DO_LCD_DISPLAY_1_BYTE_NUMBER_FROM_DATA_MEMEORY_ADDRESS Number_HIGH
	
	;DO_LCD_DISPLAY_1_BYTE_NUMBER_FROM_DATA_MEMEORY_ADDRESS Number_LOW

	; lsr r25
	; ror r24

	mov num, r25
	; rcall LCD_display_1_byte_number
	rcall LCD_display_1_byte_number_from_r17

	mov num, r24
	; rcall LCD_display_1_byte_number
	rcall LCD_display_1_byte_number_from_r17
	
	pop r24 ; Epilogue starts;
	pop r25 ; Restore all conflict registers from the stack.
	pop YL
	pop YH
	
	ret
*/

; maximum number represented by a two byte word is 65535
; the decimal number will be display like this:
display_speed:
	push YH ; Save all conflict registers in the prologue.
	push YL
	push r25
	push r24 	; speed r25:r24
	push r26	
	push r27	; quotient r17:r16
	push r18 	; counter for number of digits in decimal
	
	clr r26
	clr r27
	clr r18
	
	ldi YL, low(Speed) ; load the memory address to Y
	ldi YH, high(Speed)
	ld r24, Y+ ; 
	ld r25, Y

	lsr r25
	ror r24

	lsr r25
	ror r24

	keep_minus_10:

		tst r25              ; Test if the high byte is zero
		brne continue_minus_10 ; If r25 is non-zero, the number is greater than 10

		cpi r24, 10          ; Compare the low byte to 10
		brlo division_finish    ; Branch if r24 < 10

		continue_minus_10:
		sbiw r25:r24, 10
		adiw r27:r26, 1
		rjmp keep_minus_10
	
	division_finish:
		push r24 ; push remainder to stack
		inc	r18
		movw r25:r24, r27:r26 ; swap dividend to quotient
		clr r27
		clr r26	; set new quotient to zero
		
		tst r25              ; Test if the high byte is zero
		brne continue_minus_10 ; If r25 is non-zero, the number is greater than 10

		cpi r24, 10          ; Compare the low byte to 10
		brlo conversion_finish    ; Branch if r24 < 10
		rjmp continue_minus_10

	conversion_finish:
		push r24 ; push the last digit to stack
		inc r18

	display_digit_from_stack:
		cpi	r18, 0
		breq all_digits_displayed
		pop r24
		dec r18

		;mov r17, r24
		;rcall LCD_display_1_byte_number_from_r17
		;DO_LCD_DATA_IMMEDIATE 'A'

		subi r24, -'0'
		DO_LCD_DATA_REGISTER r24

		rjmp display_digit_from_stack


	all_digits_displayed:
	pop r18
	pop r27
	pop r26
	pop r24 
	pop r25 
	pop YL
	pop YH


; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Functions ------------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
.include "sleep_functions.asm"
.include "lcd_functions.asm"
