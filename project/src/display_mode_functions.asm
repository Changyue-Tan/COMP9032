

/*
.equ MAX_NAME_LENGTH = 10             ; 姓名最大长度
.def temp_char = r16                   ; 临时字符寄存器
.def loop_counter = r17                ; 循环计数器寄存器
.def digit = r18                       ; 数字寄存器
.def temp_id = r19                     ; 临时ID寄存器
.def temp = r20                        ; 临时寄存器
.def leds = r21                        ; LED寄存器
*/
.macro DISPLAY_PATIENT_PROLOGUE
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
    push    ZL
    push    ZH
.endmacro 

.macro  DISPLAY_PATIENT_EPILOGUE
    pop     ZH
    pop     ZL
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


.macro DISPLAY_PATIENT_INFO
    ld      r16, Z+
    ld      r17, Z                      ; load address of next_patient
    mov     ZL, r16
    mov     ZH, r17
    ; 初始化循环计数器为10
    ldi     r17, 10  ; 循环计数10次

    display_name_loop_fixed:
        ld      r16, Z+                   ; 从 Next_Patient 指向的位置读取一个字符到 r16
        DO_LCD_DATA_REGISTER r16         ; 显示字符到LCD
        dec     r17                     ; 递减计数器
        brne    display_name_loop_fixed          ; 如果未完成10次，继续循环

        ; 添加3个空格用于分隔姓名和编号
        ldi     r17, 3                  ; 设置循环计数为3
    add_spaces_loop_fixed:
        cpi     r17, 0                  ; 检查是否完成3次
        breq    display_id_fixed                 ; 如果完成，跳转到显示ID
        ldi     r16, ' '                   ; 加载空格字符
        DO_LCD_DATA_REGISTER r16         ; 显示空格到LCD
        dec     r17                      ; 递减计数器
        rjmp    add_spaces_loop_fixed             ; 继续循环

    ; 显示患者编号
    display_id_fixed:
        nop
.endmacro


display_next_patient:
    DISPLAY_PATIENT_PROLOGUE

    REFRESH_LCD
    LCD_DISPLAY_STRING_FROM_PROGRAM_SPACE Display_Mode_Message
    DO_LCD_COMMAND 0xC0                  ; 设置DDRAM地址为0x40

    rcall strobe_on

    ldi     ZL, low(Next_Patient)
    ldi     ZH, high(Next_Patient)
    DISPLAY_PATIENT_INFO
    lds     r17, Next_Patient_Number          ; 从 Next_Patient_Number 读取ID到 r17
    rcall   LCD_display_1_byte_number_from_r17
    
    DISPLAY_PATIENT_EPILOGUE
    ret

display_last_patient:
    DISPLAY_PATIENT_PROLOGUE
    
    REFRESH_LCD
    LCD_DISPLAY_STRING_FROM_PROGRAM_SPACE Entry_Mode_Complete_Message
    DO_LCD_COMMAND 0xC0                  ; 设置DDRAM地址为0x40

    ldi     ZL, low(Last_Patient)
    ldi     ZH, high(Last_Patient)
    DISPLAY_PATIENT_INFO
    lds     r17, Last_Patient_Number          ; 从 Next_Patient_Number 读取ID到 r17
    rcall   LCD_display_1_byte_number_from_r17
    
    DISPLAY_PATIENT_EPILOGUE
    ret





