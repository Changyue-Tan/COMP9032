; local constants for keypad
.equ PORTLDIR	 =	0b11110000							; use Port L for input/output from keypad: PF7-4, output, PF3-0, input
.equ INITCOLMASK =	0b11101111							; scan from the leftmost column, the value to mask output
.equ INITROWMASK =	0b00000001							; scan from the bottom row
.equ ROWMASK	 =	0b00001111							; low four bits are output from the keypad. This value mask the high 4 bits.

; local variable for keypad
.def row    = r20										; current row number
.def col    = r21										; current column number
.def rmask  = r22										; mask for current row
.def cmask	= r23										; mask for current column
.def temp1	= r24										
.def temp2  = r25

; data memory location to store the ascii value of the key being pressed taken as @0
.macro SCAN_KEYPAD_INPUT_AS_ASCII_TO_DATA_MEMORY
    rcall data_memory_prologue
    rcall keypad_scan_loop      ; running indefinitely until input from keypad detected, and stored in r16
    ldi YL, low(@0) 
	ldi YH, high(@0)
    st  Y, r16
    rcall data_memory_epilogue
.endmacro
