; these should only be called during interupts
; need to save conflicting regs else where

.macro CLEAR_DATA_IN_MEMORY
	ldi YL, low(@0) ; load the memory address to Y
	ldi YH, high(@0)
	clr r16
	st Y+, r16 ; clear the two bytes at @0 in SRAM
	st Y, r16
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