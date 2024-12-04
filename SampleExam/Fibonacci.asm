.include "m2560def.inc"

.cseg
.org 0x0000
	rjmp RESET                          ; Reset Interrupt

.org INT0addr
    rjmp EXT_INT0                       ; External Interrupt 0

m:  .db 6, 0

RESET:
    rcall   interupt_setup
    rjmp    main

EXT_INT0:
    push   r16
    in     r16, SREG
    push   r16

    ; turn on leds
    ser    r16                         
	out    DDRC, r16                   ; set Port C as output for LED bar
	out    PORTC, r16                  ; turn on all LEDs

    sbi   PORTD, 0                    ; set PORT D bit 0 to end software interrupt

    pop    r16
    out    SREG, r16
    pop    r16

    reti                 

main:
    ldi ZL, low(m<<1)
    ldi ZH, high(m<<1)
    lpm r24, Z                  ; pass parameterr m through r24
    rcall fib                   ; call fib(m)

halt:   
    rjmp halt

; m = fib(m) : parameter and return value will both be stored in r24
fib:
    ;prologue
    push    r16
    push    YL
    push    YH
    in      YL, SPL             ; save the stack pointer before function call
    in      YH, SPH
    sbiw    Y, 1                ; Let Y point to the TOP of the stack frame
    out     SPH, YH             ; Update SP so that it points to the new stack top (top of stack frame)
    out     SPL, YL             ; (the old stack top will be used to place the following parameter)
    std     Y+1, r24            ; pass the parameter to delicated memory space (the old stack top) (stack frame of size 1)

    ;function body
    cpi     r24, 2              ; compare m with 2
    brsh    L2                  ; if m is not 0 or 1, do recursion
                                ; else, m == 0 or 1
    ldi     r24, 1              ; then fib(0) = 1 and fib(1) = 1
    rjmp    L1

L2: ; recurse
    ldd      r24, Y+1            ; load the paramter to r24
    subi    r24, 1              ; pass m-1 to recursive callee
    rcall   fib                 ; fib(m-1)

    mov    r16, r24            ; store the return value of the recursive call in r16

    ldd      r24, Y+1            ; load the paramter to r24
    subi    r24, 2              ; pass m-2 to recursive callee
    rcall   fib                 ; fib(m-1)

    add     r24, r16           ; r24 = fib(m-1) + fib(m-2)
    
    brvs    overflow_detected   ; branch if overflow flag is set

L1: ; return
    ; epilogue
    adiw    Y, 1                ; free the memory space allocated the parameter
    out     SPH, YH             ; restore the stack pointer to before the function call
    out     SPH, YL
    pop     YH
    pop     YL
    pop     r16
    ret

overflow_detected:
    ; trigger the interrupt by setting PORTD bit 0 as 0 (create falling edge)
    cbi     PORTD, 0            ; clear PORTD bit 0 to create falling edge, trigger INT0 request

    rjmp halt

interupt_setup:

    ldi     r16, 0b00000001
    out     DDRD, r16   ; set Port D bit 0 as output
    out     PORTD, r16  ; set Port D bit 0 to 1

	ldi     r16, (2<<ISC00)                      ; set INT0 as falling edge triggered interrupt
	sts     EICRA, r16                                                          
	
    in      r16, EIMSK                           ; read EIMSK and ori, keep other bits untouched
	ori     r16, (1<<INT0)                       ; enable INT0
	out     EIMSK, r16
	
	sei                                          ; Enable global interrupt

    ret