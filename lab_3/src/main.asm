.include "m2560def.inc"
.include "lcd_defs.asm"
.include "lcd_macros.asm"
.include "keypad_defs.asm"

.def a              = r2						        ; Holds value of 'a'
.def b              = r3								; Holds value of 'b'
.def c              = r4								; Holds value of 'c'
.def result         = r5								; Holds value of result
.def temp			= r16
.def overflow_flag  = r17
; .def mul_flag       = r17                               ; indictes the result *= input
; .def sub_flag       = r18                               ; indictes the result -= input
.def display_mode   = r19							    ; Display mode flag (0 = decimal, 1 = hexadecimal)
.def num			= r20							    ; Holds the number that may be yet finish typing
.def input            = r21                               ; Holds the most recent read from input

;.include "main.asm"
start:
	rcall		setup_LCD
    rcall		setup_keypad
	rcall		setup_LED
	clr			num
	clr			display_mode

main_loop:
	rcall		sleep_125ms
    rcall		scan_start						; input from keypad stored in r21 (input) as text
	rcall		lcd_display_input

    cpi			input,			 '*'					;
    breq		multiplication 

    cpi			input,           'D'					    ; 
    breq		subtraction								; 
    
    cpi			input,           '#'						; 
    breq		display_result							; 
    
    cpi			input,           'C'						; 
    breq		toggle_display							; 
    
	rjmp		update_num								; 

    multiplication:
		; ser			mul_flag
        mov         a,              num                     ; typing finished, the number is a
        clr         num                                     ; clear num to prepare for next input
        rjmp        main_loop                               ; 

    subtraction:
		; ser			sub_flag
        mov         b,              num                     ; typing finished, the number is b
        clr         num                                     ; clear num to prepare for next input
        rjmp        main_loop                               ; 
    
    display_result:
		clr			r1
        mov         c,              num                     ; typing finished, the number is c
		mul			a,				b        				; r0 = LOW(a * b)
		mov			r16,			r1						; ; r1 = HIGH(a * b)
		cpi			r16,			0
		brne		set_overflow
		sbrc		r0,				7
		rjmp		set_overflow
	
	continue:
		mov			result,			r0						; result = LOW(a * b)
		sub			result,			c 						; result = LOW(a * b) - c

        rcall       LCD_display_result
		rjmp		main_loop
	
	set_overflow:
		ser			overflow_flag
		rjmp		continue
			
    
    toggle_display:
		com			display_mode
        rcall       LCD_display_result
        rjmp        main_loop

    update_num:
		ldi			temp,			10						
		mul			num,			temp					
		mov			num,			r0						; num = num * 10
		subi		input,			'0'						; convert input from ascii to decimal
		add			num,			input					; num = num + input
		rjmp		main_loop

.include "lcd_functions.asm"
.include "led_functions.asm"
.include "keypad_functions.asm"
.include "sleep_functions.asm"
