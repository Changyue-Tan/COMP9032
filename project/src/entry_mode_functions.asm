; .def temp            = r16
/*
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
*/

.macro ENTRY_MODE_PROLOGUE
    push    r16
    push    r17
    push    r18
    push    r19
    push    r20
    push    r21
    push    r22
    push    r23
    push    r24
    push    r25
    push    r26
    push    r27
    push    ZL
    push    ZH
    push    YL
    push    YH
.endmacro 

.macro  ENTRY_MODE_EPILOGUE
    pop     YH
    pop     YL
    pop     ZH
    pop     ZL
    pop     r27
    pop     r26
    pop     r25
    pop     r24
    pop     r23
    pop     r22
    pop     r21
    pop     r20
    pop     r19
    pop     r18
	pop     r17
    pop     r16
.endmacro  


; 主程序
start_entry_mode:
    ENTRY_MODE_PROLOGUE

    INCREMENT_ONE_BYTE_IN_DATA_MEMORY Entry_Mode_Flag

    REFRESH_LCD
    LCD_DISPLAY_STRING_FROM_PROGRAM_SPACE Entry_Mode_Prompt
    DO_LCD_COMMAND 0xC0                                     ; move cursor to second line
                                                            ; 0x40 + 0b10000000 = 0xC0
    clr         r22
    clr         r23
    clr         r24
    ; 初始化temp_name为全空格
    ldi         YL, low(temp_name)
    ldi         YH, high(temp_name)
    ldi         r17 , 10
    clear_temp_name_loop:
        ldi         r18, ' '    ; 空格的ASCII码
        st          Y+, r18
        dec         r17 
        brne        clear_temp_name_loop

    ldi         YL, low(Patient_Name)
    ldi         YH, high(Patient_Name)
    ldi         r17 , 10
    clear_Patient_Name_loop:
        ldi         r18, ' '    ; 空格的ASCII码
        st          Y+, r18
        dec         r17 
        brne        clear_Patient_Name_loop
    
    clr r17

main_loop:
    
    rcall       take_keypad_input         ; 从键盘获取输入的内容存储在r21中（r21）
    ; 处理输入内容
    cpi         r21, '2'
    brlo        not_number
    cpi         r21, '9'+ 1
    brsh        not_number

    ; 输入在'2'和'9'之间
    cp          r21, r23
    breq        same_key
    ; 按下不同的键
    mov         r23, r21
    clr         r24
    rjmp        display_current_letter

same_key:
    ; if same key is pressed, move cursor back to the previous one 
    ldi         r16, 0xC0                   ; start of second line 
    add         r16, r22                    
    DO_LCD_COMMAND_REGISTER r16
    inc         r24                         ; 

display_current_letter:

    mov         r18, r21
    ; DO_LCD_DATA_REGISTER r18
    subi        r18, '2'
    lsl         r18

    ; 加载key_offsets的基地址到Z
    ldi         ZL, low(key_offsets<<1)             ; program memory is addressed to each word (2 byte)
                                                    ; with a 2 byte address space
    ldi         ZH, high(key_offsets<<1)

    ; 将r18添加到Z
    clr         r1
    add         ZL, r18
    adc         ZH, r1

    ; 加载字母的地址到r17 :r18
    lpm         r17 , Z+
    lpm         r18, Z
    ; r17 :r18为键所对应的字母的地址

    ; 将r17 :r18加载到Z
    mov         ZL, r17
    mov         ZH, r18

    ; program memory is word addressed
    lsl         ZL
    rol         ZH

    ; 加载字母的数量到r19
    lpm         r19, Z
    ; r19为键所对应的字母的数量

    ; 比较r24和r19
    cp          r24, r19
    brlo        within_range
    clr         r24

within_range:
    ; 将r24添加到Z
    mov         r20, r24

    ; Z pointing to total number of letter in key
    adiw        Z, 1
    ; Z pointing to padding 0
    adiw        Z, 1
    ; Z pointing to letter with index 0

    add         ZL, r20
    adc         ZH, r1

    ; 读取字母
    lpm         r25, Z
    
    DO_LCD_DATA_REGISTER r25

    rjmp        main_loop

not_number:
    ; 检查是否按下'#'（接受字母）键
    cpi         r21, '#'
    breq        accept_letter

    ; 检查是否按下'D'（保存名字）键
    cpi         r21, 'D'
    breq        commit_name

    cpi         r21, 'C'
    breq        clear_input

    cpi         r21, 'B'
    breq        back_space

    ; 其他键不做处理
    rjmp        main_loop

clear_input:
    jmp        start_entry_mode

back_space:
    ; decrease letter index in name
    dec         r22
    ; move cursor backwards
    ldi         r16, 0xC0                   ; start of second line 
    add         r16, r22       
    DO_LCD_COMMAND_REGISTER r16
    ; print a space
    DO_LCD_DATA_IMMEDIATE ' '
    ; move curosr backwards again
    ldi         r16, 0xC0                   ; start of second line 
    add         r16, r22           
    DO_LCD_COMMAND_REGISTER r16
    rjmp        main_loop

accept_letter:
    ldi         YL, low(temp_name)
    ldi         YH, high(temp_name)
    add         YL, r22
    adc         YH, r1
    ; 存储r25
    st          Y, r25
    ; 增加r22
    inc         r22
    ; 重置r23和r24
    clr         r23
    clr         r24

    rjmp        main_loop

commit_name:
    CLEAR_ONE_BYTE_IN_DATA_MEMORY Entry_Mode_Flag
    INCREMENT_ONE_BYTE_IN_DATA_MEMORY Entry_Confirm_Flag
    ; 复制temp_name到Patient_Name
    ldi         ZL, low(temp_name)
    ldi         ZH, high(temp_name)
    ldi         YL, low(Patient_Name)
    ldi         YH, high(Patient_Name)
    mov         r17,    r22
    ; dec         r17
    ; ldi         r17 , 10
copy_name_loop:
    ld          r18, Z+
    st          Y+, r18
    dec         r17 
    brne        copy_name_loop
    ; 显示Patient_Name
    ; rcall       display_Patient_Name
    ; rjmp        main_loop

display_Patient_Name:
    ; 显示Patient_Name

    REFRESH_LCD
    LCD_DISPLAY_STRING_FROM_PROGRAM_SPACE Entry_Mode_Complete_Message
    DO_LCD_COMMAND 0xC0                  ; 设置DDRAM地址为0x40
    
    rcall   enqueue

    rcall   display_last_patient

    waitting_confirmation:
        rcall   take_keypad_input
        cpi     r21, 'D'
        brne    waitting_confirmation

    ; stop:
    ;    rjmp stop

    ; jmp start_entry_mode
    CLEAR_ONE_BYTE_IN_DATA_MEMORY Entry_Confirm_Flag


ENTRY_MODE_EPILOGUE
ret