; 九键输入名字，临时存储和永久存储功能

.include "m2560def.inc"

.include "data_memory_macros.asm"
.include "keypad_defs_and_macros.asm"
.include "lcd_defs_and_macros.asm"

.include "patients_queue_macros.asm"

; 定义寄存器
.def temp            = r16
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

; 名字存储
.dseg
temp_name:    .byte 10

; for queue data structure
Patients_Queue:			.byte 2560		; max number of patients per day: 255
Next_Patient:			.byte 2			; pointer to next patient
Last_Patient:			.byte 2			; pointer to last patient
Space_For_New_Patient:	.byte 2			; pointer to the next avaliable space to store newly enqueued patient
Next_Patient_Number:	.byte 1			; a number between 0 - 255
Last_Patient_Number:	.byte 1			; a number between 0 - 255

; the input from keypad is stored here
Patient_Name:			.byte 10		; a char array with length of 10

.cseg

main:
    rcall setup_keypad
    rcall setup_LCD

    rcall initialise_queue
    
    rjmp start_entry_mode

.include "sleep_functions.asm"
.include "keypad_functions.asm"
.include "lcd_functions.asm"

.include "patients_queue_functions.asm"

.include "display_mode_functions.asm"


; 键盘映射字母
; key_offsets中存储键的地址和对应的字母

Entry_Mode_Prompt:
    .db "Enter Name:", 0

Entry_Mode_Complete_Message:
    .db "Your number is:", 0

key_offsets:   
    ; .db 'X', 0
    ; .db 'A', 0
    .dw key2_letters
    .dw key3_letters
    .dw key4_letters
    .dw key5_letters
    .dw key6_letters
    .dw key7_letters
    .dw key8_letters
    .dw key9_letters

; 0 for padding
key2_letters:
    .db 3, 0
    .db 'A', 'B', 'C', 0
key3_letters:
    .db 3, 0
    .db 'D', 'E', 'F', 0
key4_letters:
    .db 3, 0
    .db 'G', 'H', 'I', 0
key5_letters:
    ; .db 'X', 0
    .db 3, 0
    .db 'J', 'K', 'L', 0
key6_letters:
    .db 3, 0
    .db 'M', 'N', 'O' , 0
key7_letters:
    .db 4, 0
    .db 'P', 'Q', 'R', 'S'  
key8_letters:
    .db 3, 0
    .db 'T', 'U', 'V', 0
key9_letters:
    .db 4, 0
    .db 'W', 'X', 'Y', 'Z'

; 主程序
start_entry_mode:
    REFRESH_LCD
    LCD_DISPLAY_STRING_FROM_PROGRAM_SPACE Entry_Mode_Prompt
    ; DO_LCD_DATA_IMMEDIATE 'S'
    DO_LCD_COMMAND 0xC0                                     ; move cursor to second line
                                                            ; 0x40 + 0b10000000 = 0xC0
    ; DO_LCD_DATA_IMMEDIATE 'S'
    ; DO_LCD_DATA_IMMEDIATE 'S'
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
    
    ; DO_LCD_DATA_REGISTER r23
    rcall       take_keypad_input         ; 从键盘获取输入的内容存储在r21中（r21）
    ; DO_LCD_DATA_REGISTER r23
    
    ; DO_LCD_DATA_REGISTER r21

    ; 处理输入内容
    cpi         r21, '2'
    brlo        not_number
    cpi         r21, '9'+ 1
    brsh        not_number

    ; 输入在'2'和'9'之间
    ; DO_LCD_DATA_REGISTER r23
    ; DO_LCD_DATA_REGISTER r21
    cp          r21, r23
    breq        same_key
    ; 按下不同的键
    mov         r23, r21
    ; breq        accept_letter
    ; DO_LCD_DATA_REGISTER r23
    ; DO_LCD_DATA_REGISTER r21
    clr         r24
    rjmp        display_current_letter

same_key:
    ; if same key is pressed, move cursor back to the previous one 
    ldi         r16, 0xC0                   ; start of second line 
    add         r16, r22                    
    DO_LCD_COMMAND_REGISTER r16
    inc         r24                         ; 
    ; DO_LCD_DATA_IMMEDIATE 'A'

display_current_letter:
/*
    ; 计算键的索引：r21 - '2'
    ldi         r17 , '2'
    sub         r21, r17        ; r21 = r21 - '2' (现在为0到7)

    ; 将r21乘以2得到key_offsets中的偏移量
    mov         r18, r21
    lsl         r18              ; r18 = r21 * 2
*/
    mov         r18, r21
    ; DO_LCD_DATA_REGISTER r18
    subi        r18, '2'
    lsl         r18

    ; 加载key_offsets的基地址到Z
    ldi         ZL, low(key_offsets<<1)             ; program memory is addressed to each word (2 byte)
                                                    ; with a 2 byte address space
    ldi         ZH, high(key_offsets<<1)

    ; DO_LCD_DATA_REGISTER r17
    ; lpm         r17, Z+
    ; lpm         r17, Z+
    ; lpm         r17, Z
    ; ldi         r17, 0x41
    ; DO_LCD_DATA_REGISTER r17
    ; clr         r17
    ; nop 
    ; nop 
    ; nop 
    ; nop 


    ; 将r18添加到Z
    clr         r1
    add         ZL, r18
    adc         ZH, r1
    
    ; subi        r18, -'0'
    ; DO_LCD_DATA_REGISTER r18

    ; 加载字母的地址到r17 :r18
    lpm         r17 , Z+
    ; DO_LCD_DATA_REGISTER r17
    lpm         r18, Z
    ; DO_LCD_DATA_REGISTER r18

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

    ; subi        r19, -'0'
    ; DO_LCD_DATA_REGISTER r19

    ; 比较r24和r19
    cp          r24, r19
    brlo        within_range
    clr         r24

within_range:
    ; 将r24添加到Z
    mov         r20, r24
    
    ; subi        r20, -'0'
    ; DO_LCD_DATA_REGISTER r20

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
    ; DO_LCD_DATA_REGISTER r21
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
    ; 将r25存储到temp_name[r22]
    ; cpi         r22, 10
    ; brsh        main_loop          ; 名字已满，忽略输入
    ; 将temp_name[r22]的地址加载到Z
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
    ; 显示temp_name
    rcall       display_temp_name
    rjmp        main_loop

commit_name:
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
    rcall       display_Patient_Name
    rjmp        main_loop

display_temp_name:
    ; 显示temp_name
    ; REFRESH_LCD
    ret 

display_Patient_Name:
    ; 显示Patient_Name

    REFRESH_LCD
    LCD_DISPLAY_STRING_FROM_PROGRAM_SPACE Entry_Mode_Complete_Message
    DO_LCD_COMMAND 0xC0                  ; 设置DDRAM地址为0x40
    
    rcall   enqueue

    rcall   display_last_patient
    ; DO_LCD_DATA_MEMORY_ONE_BYTE Patients_Queue + 10
    ; DO_LCD_DATA_MEMORY_ONE_BYTE Patients_Queue + 11
    ; DO_LCD_DATA_MEMORY_ONE_BYTE Patients_Queue + 12
    ; DO_LCD_DATA_MEMORY_ONE_BYTE Patients_Queue + 13

    waitting_confirmation:
        rcall   take_keypad_input
        cpi     r21, 'D'
        brne    waitting_confirmation

    jmp start_entry_mode

/*
    DATA_MEMORY_PROLOGUE
	ldi YL, low(Patient_Name) ; load the memory address to Y
	ldi YH, high(Patient_Name)
	ld r24, Y+
	DO_LCD_DATA_REGISTER r24
    ld r24, Y+
	DO_LCD_DATA_REGISTER r24
    ld r24, Y+
	DO_LCD_DATA_REGISTER r24
    ld r24, Y+
	DO_LCD_DATA_REGISTER r24
    ld r24, Y+
	DO_LCD_DATA_REGISTER r24
    ld r24, Y+
	DO_LCD_DATA_REGISTER r24
	DATA_MEMORY_EPILOGUE
*/
    ret



