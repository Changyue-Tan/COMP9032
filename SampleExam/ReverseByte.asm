
.include "m2560def.inc"

.def    un_reversed_byte    = r16
.def    reversed_byte       = r17
.def    reverse_bit_counter = r18

.dseg
revserved_string:       .byte 6


.cseg
start:
    rjmp main

original_string:        .db "Hello", 0   ; Null-terminated string

main:
    ; Initialize pointer to constant string in program memory
    ldi   ZH, high(original_string<<1)   ; Load high byte of string address 
    ldi   ZL, low(original_string<<1)    ; Load low byte of string address
    ; left shift by 1 bit for byte addressing, as program memory is word (16bits) addressed

    ; Initialize pointer to empty string in data memory
    ldi   YH, high(revserved_string)   ; Load high byte of string address
    ldi   YL, low(revserved_string)    ; Load low byte of string address
    
    do_reverse_string:
        lpm   un_reversed_byte, Z+        ; Load the byte from program memory (pointed by Z)
        cpi   un_reversed_byte, 0        ; Check if we've reached the null terminator
        breq   reverse_string_finish         ; If zero byte (null terminator), exit loop
        
        rcall do_reverse_bits  ; Reverse bits of the current byte 
        
        st   Y+, reversed_byte        ; Store reversed byte to data memory
    
        rjmp  do_reverse_string  ; Repeat loop

reverse_string_finish:
    rjmp  reverse_string_finish         


; Reverse bits subroutine
do_reverse_bits:
    clr   reversed_byte
    ldi   reverse_bit_counter, 8        ; 8 bits to process

    reverse_bit_loop:
        lsr   un_reversed_byte           ; 0 -> b7...b0 -> C
        rol   reversed_byte             ; C_1 <- b7...b0 <- C_0
        dec   reverse_bit_counter                       ; Decrease the bit count
        brne  reverse_bit_loop          ; Continue until all bits processed
        ret
