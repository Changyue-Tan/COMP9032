; 九键输入名字，临时存储和永久存储功能

.include "m2560def.inc"

.include "data_memory_macros.asm"
.include "keypad_defs_and_macros.asm"
.include "lcd_defs_and_macros.asm"


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

start:
    rcall setup_keypad
    rcall setup_LCD
    rcall initialise_queue
    rjmp main

.include "sleep_functions.asm"
.include "keypad_functions.asm"
.include "lcd_functions.asm"
.include "patients_queue_functions.asm"
.include "display_mode_functions.asm"
.include "entry_mode_functions.asm"

; 键盘映射字母
; key_offsets中存储键的地址和对应的字母

Entry_Mode_Prompt:
    .db "Enter Name:", 0

Entry_Mode_Complete_Message:
    .db "Your Number Is:", 0

Display_Mode_Message:
    .db "Next Patient:", 0

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

main:
    rcall display_next_patient
    rcall take_keypad_input
    cpi r21, 'A'
    brne main
    rcall start_entry_mode
    rjmp main

 halt:   
    rjmp halt






