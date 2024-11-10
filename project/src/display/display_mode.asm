; displayMode.asm
; Subroutine to display "Next Patient:" on the first line
; and the 10-character name plus patient ID on the second line of the LCD.
; setup_LCD should be called in the main program
;.include "lcd_defs_and_macros.asm"
;.include "main.asm"

.include "lcd_defs_and_macros.asm"
;.include "main.asm"
.equ MAX_NAME_LENGTH = 10             ; 姓名最大长度
.def temp_char = r16                   ; 临时字符寄存器
.def loop_counter = r17                ; 循环计数器寄存器
.def digit = r18                       ; 数字寄存器
.def temp_id = r19                     ; 临时ID寄存器
.def temp = r20                        ; 临时寄存器
.def leds = r21                        ; LED寄存器


/*.cseg
start:
    rjmp main*/

.include "lcd_functions.asm"
;.include "sleep_functions.asm"

displayMode:
    ; 保存使用的寄存器
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

    ; 在第一行显示 "Next Patient:"
    DO_LCD_COMMAND 0x80                  ; 设置DDRAM地址为0x00
    ; 逐个发送字符到LCD
    ldi     r16, 'N'
    DO_LCD_DATA_REGISTER r16
    ldi     r16, 'e'
    DO_LCD_DATA_REGISTER r16
    ldi     r16, 'x'
    DO_LCD_DATA_REGISTER r16
    ldi     r16, 't'
    DO_LCD_DATA_REGISTER r16
    ldi     r16, ' '
    DO_LCD_DATA_REGISTER r16
    ldi     r16, 'P'
    DO_LCD_DATA_REGISTER r16
    ldi     r16, 'a'
    DO_LCD_DATA_REGISTER r16
    ldi     r16, 't'
    DO_LCD_DATA_REGISTER r16
    ldi     r16, 'i'
    DO_LCD_DATA_REGISTER r16
    ldi     r16, 'e'
    DO_LCD_DATA_REGISTER r16
    ldi     r16, 'n'
    DO_LCD_DATA_REGISTER r16
    ldi     r16, 't'
    DO_LCD_DATA_REGISTER r16
    ldi     r16, ':'
    DO_LCD_DATA_REGISTER r16

    ; 在第二行显示姓名和编号
    DO_LCD_COMMAND 0xC0                  ; 设置DDRAM地址为0x40

    ; 读取 Next_Patient 指针
    lds     r24, Next_Patient            ; 读取 Next_Patient 的低字节
    lds     r25, Next_Patient + 1        ; 读取 Next_Patient 的高字节

    ; 设置 Z 寄存器指向 Next_Patient 指向的姓名地址
    mov     ZL, r24
    mov     ZH, r25

    ; 初始化循环计数器为10
    ldi     loop_counter, MAX_NAME_LENGTH  ; 循环计数10次

display_name_loop_fixed:
    ld      temp_char, Z+                   ; 从 Next_Patient 指向的位置读取一个字符到 temp_char
    DO_LCD_DATA_REGISTER temp_char         ; 显示字符到LCD
    dec     loop_counter                     ; 递减计数器
    brne    display_name_loop_fixed          ; 如果未完成10次，继续循环

    ; 添加3个空格用于分隔姓名和编号
    ldi     loop_counter, 3                  ; 设置循环计数为3
add_spaces_loop_fixed:
    cpi     loop_counter, 0                  ; 检查是否完成3次
    breq    display_id_fixed                 ; 如果完成，跳转到显示ID
    ldi     temp_char, ' '                   ; 加载空格字符
    DO_LCD_DATA_REGISTER temp_char         ; 显示空格到LCD
    dec     loop_counter                      ; 递减计数器
    rjmp    add_spaces_loop_fixed             ; 继续循环

; 显示患者编号
display_id_fixed:
    ; 读取 Next_Patient_Number 到 r17
    lds     r17, Next_Patient_Number          ; 从 Next_Patient_Number 读取ID到 r17

    ; 调用新的显示子程序
    rcall   LCD_display_1_byte_number_from_r17

    ; 结束 displayMode 子程序
    jmp     end_displayMode

; 恢复寄存器并返回
end_displayMode:
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
    ret

