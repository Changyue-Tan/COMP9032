 ; Set a particular bit in LCD control register
.macro LCD_SET
	sbi			PORTA,			@0
.endmacro

; Clear a particular bit in LCD control register
.macro LCD_CLR
	cbi			PORTA,			@0
.endmacro


.macro LCD_GO_HOME
	DO_LCD_COMMAND 0b00000010 	; return home
.endmacro


.macro REFRESH_LCD
	DO_LCD_COMMAND 0b00000001 	; clear display
	LCD_GO_HOME
.endmacro


; Send a particular 8 bit number as Instruction to LCD
.macro DO_LCD_COMMAND
	ldi			r16,			@0
	rcall		lcd_command
	rcall		lcd_wait
.endmacro

; Send a particular 8 bit number as data to LCD
.macro DO_LCD_DATA_IMMEDIATE
	ldi			r16,			@0
	rcall		lcd_data
	rcall		lcd_wait
.endmacro

; Send a particular 8 bit number as data to LCD from a register
.macro DO_LCD_DATA_REGISTER
	mov			r16,			@0
	rcall		lcd_data
	rcall		lcd_wait
.endmacro

.macro DO_LCD_DISPLAY_1_BYTE_NUMBER_FROM_DATA_MEMEORY_ADDRESS
	push	YH
	push	YL 
	push  	r17

	ldi YL, low(@0) 
	ldi YH, high(@0)
	ld	r17, Y
	
	DO_LCD_DATA_REGISTER r17
	; rcall LCD_display_1_byte_number
	; rcall LCD_display_1_byte_number_from_r17
	; rcall LCD_dummy_func
	DO_LCD_DATA_IMMEDIATE 'A'

	pop 	r17
	push	YL
	push	YH
.endmacro
