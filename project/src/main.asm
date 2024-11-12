
.include "m2560def.inc"

.include "data_memory_macros.asm"
.include "keypad_defs_and_macros.asm"
.include "lcd_defs_and_macros.asm"
; .include "blink_defs_and_macros.asm"


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

; for blink interval  
Blink_Timer:            .byte 1

; to determine if it is now entry mode
Entry_Mode_Flag:        .byte 1
Entry_Confirm_Flag:     .byte 1

.cseg

.org 0x0000
	rjmp RESET           

.org INT0addr
    rjmp EXT_INT0                
/*
.org INT1addr
    rjmp EXT_INT1  
*/

.org OVF0addr
	jmp Timer0OVF ; Jump to the interrupt handler for Timer0 overflow. 



.include "sleep_functions.asm"
.include "keypad_functions.asm"
.include "lcd_functions.asm"
.include "patients_queue_functions.asm"
.include "display_mode_functions.asm"
.include "entry_mode_functions.asm"
.include "blink_functions.asm"
.include "strobe.asm"

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
    CLEAR_ONE_BYTE_IN_DATA_MEMORY Entry_Mode_Flag
    CLEAR_ONE_BYTE_IN_DATA_MEMORY Entry_Confirm_Flag
	; CLEAR_TWO_BYTE_IN_DATA_MEMORY keypad_Input

    rcall interupt_setup
    rcall setup_keypad
    rcall setup_LCD
    rcall initialise_queue

    ; set up led
	ser r16 ; set Port C & G as output
	out DDRC, r16
    out DDRG, r16
	ldi r16, 0x00
	out PORTC, r16
    out PORTG, r16

    ; pull up for port D (push buttons)
    clr    r16
    out    DDRD, r16
    ser    r16
    out    PORTD, r16
    
    rjmp main

EXT_INT0:
    rcall   sleep_125ms
    push    r16
    in      r16,    SREG
    push    r16
    push    r17
    ; push    r2                 ; to store blink low/high
    DATA_MEMORY_PROLOGUE

    ; clr     r16
    ; mov     r2,     r16     
/*
    ldi r16, (2<<ISC10) ; set INT1 as falling edge triggered interrupt
	sts EICRA, r16 ; Store Direct to data space
	; enable INT1
    in r16, EIMSK 
	ori r16, (1<<INT1)
	out EIMSK, r16
*/ 
    ; disable INT0, we dont want INT0 to be trigger again
    in r16, EIMSK
	andi r16, ~(1<<INT0)
	out EIMSK, r16
    sei                                     ; allow timer interrupt to continue

    check_if_there_is_next_patient:
        ldi YL, low(Next_Patient_Number) 
        ldi YH, high(Next_Patient_Number)
        ld r16, Y                          ; r16 = Next_Patient_Number
        ldi YL, low(Last_Patient_Number) 
        ldi YH, high(Last_Patient_Number)
        ld  r17, Y                          ; r17 = Last_Patient_Number
        ; if Last_Patient_Number < Next_Patient_Number, then no patient in queue
        cp r17, r16
        ; if no patient in queue, exit interupt
        brmi exit_INT0
        rjmp calling_next_patient

        exit_INT0:
            rjmp end_of_INT0

    calling_next_patient:
        rcall sleep_125ms
        rcall display_next_patient
        ; initilise blink_timer
        ; blink_timer counts in intervals of 0.5 seconds
        CLEAR_ONE_BYTE_IN_DATA_MEMORY Blink_Timer
        rjmp pattern_a

    cancle_appointment:
        rcall dequeue
        rcall display_next_patient
        rcall sleep_1000ms
        rjmp  pattern_c

    patient_arrives:
        rcall dequeue
        rcall display_next_patient
        rcall sleep_1000ms
        ; reset counter to count how many seconds has passed
        CLEAR_TWO_BYTE_IN_DATA_MEMORY Seconds_Counter
        rjmp  end_of_INT0

    start_check_cancle_a:
        rcall   sleep_1000ms
        ser     r16
        sbis    PIND, 1
        clr     r16
        cpi     r16, 0
        breq    cancle_appointment
        rjmp    finish_check_cancle_a

    start_check_cancle_b:
        rcall   sleep_1000ms
        ser     r16
        sbis    PIND, 1
        clr     r16
        cpi     r16, 0
        breq    cancle_appointment
        rjmp    finish_check_cancle_b

    start_check_next_patient_a:
        rcall   sleep_1000ms
        ser     r16
        sbis    PIND, 0
        clr     r16
        cpi     r16, 0
        breq    patient_arrives
        rjmp    finish_check_next_patient_a

    start_check_next_patient_b:
        rcall   sleep_1000ms
        ser     r16
        sbis    PIND, 0
        clr     r16
        cpi     r16, 0
        breq    patient_arrives
        rjmp    finish_check_next_patient_b
    
    pattern_a:
        sbis    PIND, 1
        rjmp    start_check_cancle_a
        finish_check_cancle_a:

        sbis    PIND, 0
        rjmp    start_check_next_patient_a
        finish_check_next_patient_a:

        ldi     YL, low(Blink_Timer) 
        ldi     YH, high(Blink_Timer)
        ld      r24, Y
        
        ; check if 10 seconds passed
        cpi     r24, 20
        breq    pattern_b

        mov     r16, r24
        andi    r16, 0b00000011       ; mask out all bits except the last two
        breq    multiples_of_4
        
        mov     r16, r24
        subi    r16, -2
        andi    r16, 0b00000011       ; mask out all bits except the last two       
        breq    multiples_of_4_plus_two   
        
        rjmp    pattern_a

        multiples_of_4:
            rcall   led_bell_low
            rjmp    pattern_a
        multiples_of_4_plus_two:  
            rcall   led_bell_high   
            rjmp    pattern_a

    pattern_b:
        ; sbis    PIND, 1
        ; rjmp    pattern_c
        sbis    PIND, 1
        rjmp    start_check_cancle_b
        finish_check_cancle_b:
        
        sbis    PIND, 0
        rjmp    start_check_next_patient_b
        finish_check_next_patient_b:

        ldi YL, low(Blink_Timer) 
        ldi YH, high(Blink_Timer)
        ld r24, Y

        ; sbrs to check if the LSB is set (if set, odd number)
        sbrc    r24, 0
        rjmp    timer_odd

        timer_even:
            rcall   led_bell_low
            rjmp    pattern_b
        timer_odd:  
            rcall   led_bell_high    
            rjmp    pattern_b
    
    pattern_c:
        ; rcall   sleep_125ms
        rcall   led_bell_high
        rcall   sleep_3000ms
        rjmp    calling_next_patient


    end_of_INT0:
        ; slience the bell
        rcall   led_bell_low
        
        ENTRY_MODE_PROLOGUE

        ; if in entry mode: 
        ldi YL, low(Entry_Mode_Flag) 
        ldi YH, high(Entry_Mode_Flag)
        ld r24, Y
        cpi r24, 1
        breq return_to_entry_mode

        ; if in entry confirm mode:
        ldi YL, low(Entry_Confirm_Flag) 
        ldi YH, high(Entry_Confirm_Flag)
        ld r24, Y
        cpi r24, 1
        breq return_to_entry_confirm_mode

        rjmp INT0_epilogue

        return_to_entry_mode:
            rcall sleep_5000ms
            rcall strobe_off
            REFRESH_LCD
            LCD_DISPLAY_STRING_FROM_PROGRAM_SPACE Entry_Mode_Prompt
            DO_LCD_COMMAND 0xC0

            ldi         YL, low(temp_name)
            ldi         YH, high(temp_name)

            print_entered_chars_to_LCD:
                ld         r16 , Y+
                cpi         r16, ' '
                breq        end_of_return_to_entry_mode
                DO_LCD_DATA_REGISTER r16
                rjmp print_entered_chars_to_LCD

            end_of_return_to_entry_mode:
                rjmp INT0_epilogue

        return_to_entry_confirm_mode:
            rcall sleep_5000ms
            rcall strobe_off
            REFRESH_LCD
            LCD_DISPLAY_STRING_FROM_PROGRAM_SPACE Entry_Mode_Complete_Message
            DO_LCD_COMMAND 0xC0  

            rcall display_last_patient  

            rjmp INT0_epilogue

    INT0_epilogue:
        ENTRY_MODE_EPILOGUE

        ; Clear the interrupt flag for INT0
        in   r16, EIFR
        ori  r16, (1 << INTF0)
        out  EIFR, r16

        ; Re-enable INT0 interrupt
        in   r16, EIMSK
        ori  r16, (1 << INT0)
        out  EIMSK, r16

        DATA_MEMORY_EPILOGUE
        ; pop r2
        pop r17
        pop r16
        out SREG, r16
        pop r16
        reti

/*
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
*/

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
; /*
     update_blink_timer:
        cpi r24, low(500) 
        brne update_seconds_counter
        cpi r25, high(500) 
        brne update_seconds_counter
        INCREMENT_ONE_BYTE_IN_DATA_MEMORY Blink_Timer
; */
    update_seconds_counter:
        cpi r24, low(1000) 
        brne continue_counting
        cpi r25, high(1000) 
        brne continue_counting
        rcall update_timers
/*
	; use the LED bars as a couner 
	DATA_MEMORY_PROLOGUE
	ldi YL, low(Seconds_Counter) 
	ldi YH, high(Seconds_Counter)
	ld r24, Y
	out PORTC, r24
	DATA_MEMORY_EPILOGUE
*/
	; rcall show_Seconds_Counter_data
	
	; reset the counter that counts for 1 second
	CLEAR_TWO_BYTE_IN_DATA_MEMORY Temp_Counter 
	
	continue_counting:
		DATA_MEMORY_EPILOGUE
		pop r16
		out SREG, r16
		pop r16
		reti ; Return from the interrupt.

    update_timers:
        DATA_MEMORY_PROLOGUE
        push r18
        push r17
        push r0
        push r1

        rcall display_remaining_time

        INCREMENT_TWO_BYTE_IN_DATA_MEMORY Seconds_Counter
        INCREMENT_ONE_BYTE_IN_DATA_MEMORY Blink_Timer
        ; INCREMENT_ONE_BYTE_IN_DATA_MEMORY Button_Hold_Timer

        update_timers_end:
            pop r1
            pop r0
            pop r17
            pop r18
            DATA_MEMORY_EPILOGUE
            ret

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


display_remaining_time:
 ; every time seconds_timer is updated, update remaining time to LED
        ldi YL, low(Seconds_Counter) 
        ldi YH, high(Seconds_Counter)
        ld r24, Y
        
        cpi r24, 20                 ; if time elapsed >= 20 
        brsh time_is_up
        ; r24 < 20 from here

        ldi r16, 20
        sub r16, r24                ; r16 = remaining time 
        subi r16, -1                ; add 1 to account for first update to led happens at t = 1, not 0
        ldi r17, 10
        mul r16, r17                ; result in r1:r0
        mov r16, r0                 ; r16 = remaining time * 10

        ; out portc, r16

        clr r17                     ; store quotient
        ; implementation of r16 / 20
        keep_minus_20:
            cpi r16, 20          
            brlo divided_by_20_finish    
            
            continue_minus_20:
                subi r16, 20
                inc r17
                rjmp keep_minus_20

        divided_by_20_finish:

        mov r16, r17    ; r16 is now the quotient, number of leds to be on
        out portc, r16
; /*
        clr r17               ; display pattern for leds 0-7
        clr r18               ; display pattern for leds 8-9

        make_bit_loop_start:
            dec r16           ; Decrement r16
            brmi make_bit_loop_end         ; If r16 < 0, exit the loop
            lsl r17           ; Shift r17 left by 1 bit
            rol r18           ; Rotate left through carry into r18
            ori r17, 1        ; Set the least significant bit of r17
            rjmp make_bit_loop_start   ; Repeat the loop
        make_bit_loop_end:

        out PORTC, r17
        ; lsl r18                ; algin bits 
        out PORTG, r18

; */
        rjmp display_remaining_time_end

        time_is_up:
            rcall led_bell_low
        
        display_remaining_time_end:
            ret

