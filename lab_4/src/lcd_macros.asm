 ; Set a particular bit in LCD control register
.macro lcd_set
	sbi			PORTA,			@0
.endmacro

; Clear a particular bit in LCD control register
.macro lcd_clr
	cbi			PORTA,			@0
.endmacro



.macro LCD_GO_HOME
	do_lcd_command 0b00000010 	; return home
.endmacro

.macro CLEAR_LCD
	do_lcd_command 0b00000001 	; clear display
	LCD_GO_HOME
.endmacro



; Send a particular 8 bit number as Instruction to LCD
.macro do_lcd_command
	ldi			r16,			@0
	rcall		lcd_command
	rcall		lcd_wait
.endmacro

; Send a particular 8 bit number as data to LCD
.macro do_lcd_data_from_immediate
	ldi			r16,			@0
	rcall		lcd_data
	rcall		lcd_wait
.endmacro

; Send a particular 8 bit number as data to LCD from a register
.macro do_lcd_data_from_register
	mov			r16,			@0
	rcall		lcd_data
	rcall		lcd_wait
.endmacro
