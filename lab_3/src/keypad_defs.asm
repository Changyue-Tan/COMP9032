; local constants for keypad
.equ PORTLDIR	 =	0b11110000							; use Port L for input/output from keypad: PF7-4, output, PF3-0, input
.equ INITCOLMASK =	0b11101111							; scan from the leftmost column, the value to mask output
.equ INITROWMASK =	0b00000001							; scan from the bottom row
.equ ROWMASK	 =	0b00001111							; low four bits are output from the keypad. This value mask the high 4 bits.

; local variable for keypad
.def row    = r22										; current row number
.def col    = r23										; current column number
.def rmask  = r24										; mask for current row
.def cmask	= r25										; mask for current column
.def temp1	= r26										
.def temp2  = r27