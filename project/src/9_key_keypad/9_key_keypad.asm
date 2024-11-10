; 九键输入名字，临时存储和永久存储功能

.include "m2560def.inc"

.include "data_memory_macros.asm"
.include "keypad_defs_and_macros.asm"
.include "lcd_defs_and_macros.asm"


; 定义寄存器
.def temp            = r16
.def temp1           = r17
.def temp2           = r18
.def temp3           = r19
.def temp4           = r20
.def input           = r21   ; 从键盘存储最近输入的内容
.def name_index      = r22   ; 名字数组中的索引（0到9）
.def last_key        = r23   ; 最后按下的键（'2'到'9'）
.def letter_index    = r24   ; 当前键映射字母中的索引
.def current_letter  = r25   ; 当前选定的字母
.def temp_letter     = r26   ; 字母的临时存储
.def temp_letter_num = r27   ; 当前键对应的字母数量

; 名字存储
.dseg
temp_name:    .byte 10
perm_name:    .byte 10

.cseg

main:
    rcall setup_keypad
    rcall setup_LCD
    rjmp start

.include "keypad_functions.asm"
.include "lcd_functions.asm"

; 主程序
start:
    clr         name_index
    clr         last_key
    clr         letter_index
    ; 初始化temp_name为全空格
    ldi         ZL, low(temp_name)
    ldi         ZH, high(temp_name)
    ldi         temp1, 10
    clear_temp_name_loop:
        ldi         temp2, ' '    ; 空格的ASCII码
        st          Z+, temp2
        dec         temp1
        brne        clear_temp_name_loop

main_loop:
    rcall       take_keypad_input          ; 从键盘获取输入的内容存储在r21中（input）

    DO_LCD_DATA_REGISTER input

    ; 处理输入内容
    cpi         input, '2'
    brlo        not_number
    cpi         input, '9'+1
    brsh        not_number

    ; 输入在'2'和'9'之间
    cp          input, last_key
    breq        same_key
    ; 按下不同的键
    mov         last_key, input
    clr         letter_index
    rjmp        display_current_letter

same_key:
    inc         letter_index

display_current_letter:
    ; 计算键的索引：input - '2'
    ldi         temp1, '2'
    sub         input, temp1       ; input = input - '2' (现在为0到7)

    ; 将input乘以2得到key_offsets中的偏移量
    mov         temp2, input
    lsl         temp2              ; temp2 = input * 2

    ; 加载key_offsets的基地址到Z
    ldi         ZL, low(key_offsets)
    ldi         ZH, high(key_offsets)

    ; 将temp2添加到Z
    add         ZL, temp2
    adc         ZH, r1

    ; 加载字母的地址到temp1:temp2
    lpm         temp1, Z+
    lpm         temp2, Z

    ; temp1:temp2为键所对应的字母的地址

    ; 将temp1:temp2加载到Z
    mov         ZL, temp1
    mov         ZH, temp2

    ; 加载字母的数量到temp3
    lpm         temp3, Z+
    ; temp3为键所对应的字母的数量

    ; 比较letter_index和temp3
    cp          letter_index, temp3
    brlo        within_range
    clr         letter_index

within_range:
    ; 将letter_index添加到Z
    mov         temp4, letter_index
    add         ZL, temp4
    adc         ZH, r1

    ; 读取字母
    lpm         current_letter, Z

    rjmp        main_loop

not_number:
    ; 检查是否按下'#'（接受字母）键
    cpi         input, '#'
    breq        accept_letter

    ; 检查是否按下'D'（保存名字）键
    cpi         input, 'D'
    breq        commit_name

    ; 其他键不做处理
    rjmp        main_loop

accept_letter:
    ; 将current_letter存储到temp_name[name_index]
    cpi         name_index, 10
    brsh        main_loop          ; 名字已满，忽略输入
    ; 将temp_name[name_index]的地址加载到Z
    ldi         ZL, low(temp_name)
    ldi         ZH, high(temp_name)
    add         ZL, name_index
    adc         ZH, r1
    ; 存储current_letter
    st          Z, current_letter
    ; 增加name_index
    inc         name_index
    ; 重置last_key和letter_index
    clr         last_key
    clr         letter_index
    ; 显示temp_name
    rcall       display_temp_name
    rjmp        main_loop

commit_name:
    ; 复制temp_name到perm_name
    ldi         ZL, low(temp_name)
    ldi         ZH, high(temp_name)
    ldi         YL, low(perm_name)
    ldi         YH, high(perm_name)
    ldi         temp1, 10
copy_name_loop:
    ld          temp2, Z+
    st          Y+, temp2
    dec         temp1
    brne        copy_name_loop
    ; 显示perm_name
    rcall       display_perm_name
    rjmp        main_loop

display_temp_name:
    ; 显示temp_name
    ret

display_perm_name:
    ; 显示perm_name
    ret



; 键盘扫描功能实现
take_keypad_input:
    ; ; 假设从某个端口（如PINA）读取输入
    ; in          input, PINA      ; 从PINA读取键盘输入
    ; ret

    push r16
    push r20
	; push r21
	push r22
	push r23
	push r24
	push r25
    
    scan_start:
        clr r16
        clr r20
        clr r21
        clr r22
        clr r23
        clr r24
        clr r25

	ldi			cmask,			INITCOLMASK				; set cmask to 0b11101111
	clr			col										; set initial column number to 0

	colloop:
		; DO_LCD_DATA_IMMEDIATE 'A'
		cpi			col,			4						; if we have scanned all 4 columns, 
		breq		scan_start								; continue
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
        ; DO_LCD_DATA_IMMEDIATE 'A'
		; mov 		r16, 			temp1
        mov 		input, 			temp1
		; DO_LCD_DATA_REGISTER r16
		; out			PORTC,			temp1					; write value to PORTC
		; do_lcd_data_from_register	temp1
		; mov			input,			temp1
		rcall		sleep_125ms
		; do_lcd_command				0b00000010				; Return home: The cursor moves to the top left corner
		;jmp			scan_start								; restart main loop
	
    ; ldi YL, low(@0) 
	; ldi YH, high(@0)
    ; st  Y, r16

    pop r16
	pop r25
	pop r24
	pop r23
	pop r22
	; pop r21
	pop r20

; 其他LCD函数和宏的实现也在这里

; 键盘映射字母
; key_offsets中存储键的地址和对应的字母
.cseg

key_offsets:
    .dw key2_letters
    .dw key3_letters
    .dw key4_letters
    .dw key5_letters
    .dw key6_letters
    .dw key7_letters
    .dw key8_letters
    .dw key9_letters

key2_letters:
    .db 3
    .db 'A', 'B', 'C', ' '
key3_letters:
    .db 3
    .db 'D', 'E', 'F', ' '
key4_letters:
    .db 3
    .db 'G', 'H', 'I', ' '
key5_letters:
    .db 3
    .db 'J', 'K', 'L', ' '
key6_letters:
    .db 3
    .db 'M', 'N', 'O', ' '
key7_letters:
    .db 4
    .db 'P', 'Q', 'R', 'S'
key8_letters:
    .db 3
    .db 'T', 'U', 'V', ' '
key9_letters:
    .db 4
    .db 'W', 'X', 'Y', 'Z'