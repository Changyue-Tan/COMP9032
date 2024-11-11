
.include "m2560def.inc"

.include "data_memory_macros.asm"
.include "keypad_defs_and_macros.asm"
.include "lcd_defs_and_macros.asm"
.include "blink_defs_and_macros.asm"


; --------------------------------------------------------------------------------------------------------------- 
; ---------------------------------------------- Data Memroy Space Variables --------------------------------------------- 
; --------------------------------------------------------------------------------------------------------------- 
.dseg

; the input from keypad is stored here
temp_name:              .byte 10
Patient_Name:			.byte 10		; a char array with length of 10

; for queue data structure
Patients_Queue:			.byte 2560		; max number of patients per day: 255
Next_Patient:			.byte 2			; pointer to next patient
Last_Patient:			.byte 2			; pointer to last patient
Space_For_New_Patient:	.byte 2			; pointer to the next avaliable space to store newly enqueued patient
Next_Patient_Number:	.byte 1			; a number between 0 - 255
Last_Patient_Number:	.byte 1			; a number between 0 - 255

; for stop watch
Temp_Counter:    		.byte 2 
Seconds_Counter:		.byte 2

.cseg

.org 0x0000
	rjmp RESET           

.org INT0addr
    rjmp EXT_INT0                ; INT0 ????

.org INT1addr
    rjmp EXT_INT1  

.org OVF0addr
	jmp Timer0OVF ; Jump to the interrupt handler for Timer0 overflow. 



.include "sleep_functions.asm"
.include "keypad_functions.asm"
.include "lcd_functions.asm"
.include "patients_queue_functions.asm"
.include "display_mode_functions.asm"
.include "entry_mode_functions.asm"

; --------------------------------------------------------------------------------------------------------------- 
; ---------------------------------------------- Program Memroy Constants --------------------------------------------- 
; --------------------------------------------------------------------------------------------------------------- 

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


; --------------------------------------------------------------------------------------------------------------- ;
; -----------------------------------------------  Interrupt Service Routine ------------------------------------ ;
; --------------------------------------------------------------------------------------------------------------- ;

RESET:
    CLEAR_TWO_BYTE_IN_DATA_MEMORY Temp_Counter ; Initialize the counter to 0
	CLEAR_TWO_BYTE_IN_DATA_MEMORY Seconds_Counter
	; CLEAR_TWO_BYTE_IN_DATA_MEMORY keypad_Input

    rcall interupt_setup
    rcall setup_keypad
    rcall setup_LCD
    rcall initialise_queue

    ; set up led
	ser r16 ; set Port C as output
	out DDRC, r16
	ldi r16, 0b10101010	
	out PORTC, r16
    
    rjmp main

EXT_INT0:
    rcall sleep_125ms
    push r16
    in r16, SREG
    push r16
    
    ldi r16, (2<<ISC10) ; set INT0 as falling edge triggered interrupt
	sts EICRA, r16 ; Store Direct to data space
	; enable INT1
    in r16, EIMSK 
	ori r16, (1<<INT1)
	out EIMSK, r16

    rcall display_next_patient
    ; sei

    clr    r16
    out    DDRD, r16
    ser    r16
    out    PORTD, r16

    pattern_a:
        sbis    PIND, 1
        rjmp    cancle_appointment
        ; LED1
        rjmp pattern_a
    
    cancle_appointment:
        rcall sleep_125ms
        rcall dequeue
        rcall display_next_patient
        rjmp  pattern_a

    ; disable INT1
    in r16, EIMSK
	ori r16, (0<<INT1)
	out EIMSK, r16

    pop r16
    out SREG, r16
    pop r16
    reti

EXT_INT1:
    rcall sleep_125ms
    push r16
    in r16, SREG
    push r16

    rcall dequeue

    rcall display_next_patient

    pop r16
    out SREG, r16
    pop r16
    reti

Timer0OVF: ; interrupt subroutine for Timer0
	push r16 ; Prologue starts.
	in r16, SREG
	push r16 

	INCREMENT_TWO_BYTE_IN_DATA_MEMORY Temp_Counter

    DATA_MEMORY_PROLOGUE
    ldi YL, low(Temp_Counter) 
	ldi YH, high(Temp_Counter)
	ld r24, Y+ 
	ld r25, Y

	cpi r24, low(1000) 
	brne continue_counting
	cpi r25, high(1000) 
	brne continue_counting
	
	INCREMENT_TWO_BYTE_IN_DATA_MEMORY Seconds_Counter

	; use the LED bars as a couner 
	DATA_MEMORY_PROLOGUE
	ldi YL, low(Seconds_Counter) 
	ldi YH, high(Seconds_Counter)
	ld r24, Y
	out PORTC, r24
	DATA_MEMORY_EPILOGUE

	; rcall show_Seconds_Counter_data
	
	; reset the counter that counts for 1 second
	CLEAR_TWO_BYTE_IN_DATA_MEMORY Temp_Counter 
	
	continue_counting:
		DATA_MEMORY_EPILOGUE
		pop r16
		out SREG, r16
		pop r16
		reti ; Return from the interrupt.


; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Main Program ------- ---------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;

main:
    rcall display_next_patient
    rcall take_keypad_input
    cpi r21, 'A'
    brne main
    rcall start_entry_mode
    rjmp main

 ; halt:   
    ; rjmp halt


; --------------------------------------------------------------------------------------------------------------- ;
; ------------------------------------------------------- Subrutines ------------------------------------------- ;
; --------------------------------------------------------------------------------------------------------------- ;
interupt_setup:
    ldi r16, 0b00000000
	out TCCR0A, r16
	ldi r16, 0b00000011
	out TCCR0B, r16 ; Prescaler value=64, counting 1024 us
	
	ldi r16, 1<<TOIE0
	sts TIMSK0, r16 ; T/C0 interrupt enable
	
	ldi r16, (2<<ISC00) ; set INT0 as falling edge triggered interrupt
	sts EICRA, r16 ; Store Direct to data space
	in r16, EIMSK ; enable INT0
	ori r16, (1<<INT0)
	out EIMSK, r16
	
	sei ; Enable global interrupt

    ret



