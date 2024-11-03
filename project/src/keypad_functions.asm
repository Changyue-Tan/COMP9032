; keypad set up, executed only once
setup_keypad:
	push temp1
	ldi			temp1,			PORTLDIR				; 
	STS			DDRL,			temp1					; set high bits of port L to output, and low bits to input
	pop temp1
	ret

/*
; keep scanning for input from keypad
; if there is input, as of now, output through port C
keypad_scan_loop:
	; DO_LCD_DATA_IMMEDIATE 'A'
	push r20
	push r21
	push r22
	push r23
	push r24
	push r25

	ldi			cmask,			INITCOLMASK				; set cmask to 0b11101111
	clr			col										; set initial column number to 0

	colloop:
		; DO_LCD_DATA_IMMEDIATE 'A'
		cpi			col,			4						; if we have scanned all 4 columns, 
		breq		keypad_scan_loop								; continue
															; else, start scanning the "col"th column
		STS			PORTL,			cmask					; ouput 0 to the column that we wish to scan
		rcall		sleep_5ms


		LDS			temp1,			PINL
		;in	temp1, PINL raise error				; 
		andi		temp1,			ROWMASK					; read from the low bits of PORTL 
		cpi			temp1,			0xF						; check if any rows are on
		breq		nextcol									; no rows are 0, hence no key is pressed, scan next column
															; else, a key is pressed, check which row it is
		ldi			rmask,			INITROWMASK				; initialise row check, set rmask to 0b00000001
		clr			row										; initial row = 0

		rowloop:
			; DO_LCD_DATA_IMMEDIATE 'A'
			cpi			row,			4						; check if we have scanned all 4 rows
			breq		nextcol									; if yes, scan next column
																; else, scan this row
			mov			temp2,			temp1					; temp1 is the lower bits if port L
			and			temp2,			rmask					; check the "row"th bit of temp2
			breq		convert 								; if the "row"th bit is 0, this key is pressed
																; else, scan the next row
			inc			row										; 
			lsl			rmask									; shift the mask to the next bit
			jmp			rowloop

	nextcol:
		lsl			cmask									; else get new mask by shifting and 
		inc			col										; increment column value
		jmp			colloop									; and check the next column

	convert:
		cpi			col,			3						; if column is 3 we have a letter
		breq		letters				
		cpi			row,			3						; if row is 3 we have a symbol or 0
		breq		symbols

		mov			temp1,			row						; otherwise we have a number in 1-9
		lsl			temp1					
		add			temp1,			row						; temp1 = row * 3 (row * 2 + row)
		add			temp1,			col						; add the column address to get the value
		;
		subi		temp1,			-1
		;
		subi		temp1,			-'0'					; add the value of character '0'
		
		jmp			convert_end

		letters:
			ldi			temp1,			'A'
			add			temp1,			row						; increment the character 'A' by the row value
			jmp			convert_end

		symbols:
			cpi			col,			0						; check if we have a star
			breq		star

			cpi			col,			1						; or if we have zero
			breq		zero	
							
			ldi			temp1,			'#'						; if not we have hash
			jmp			convert_end

		star:
			ldi			temp1,			'*'						; set to star
			jmp			convert_end

		zero:
			ldi			temp1,			'0'						; set to zero
		
	convert_end:
		mov 		r16, 			temp1
		DO_LCD_DATA_REGISTER r16
		; out			PORTC,			temp1					; write value to PORTC
		; do_lcd_data_from_register	temp1
		; mov			input,			temp1
		rcall		sleep_625ms
		; do_lcd_command				0b00000010				; Return home: The cursor moves to the top left corner
		;jmp			scan_start								; restart main loop
		
	pop r25
	pop r24
	pop r23
	pop r22
	pop r21
	pop r20

	ret				
*/

