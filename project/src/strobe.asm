strobe_off:
    push r16
    push r17

    clr r16
    out DDRA, r16
    in r17, PINA 
    andi r17, 0b11111101
    ser r16
    out DDRA, r16
    out PORTA, r17

    pop r17
    pop r16

    ret

strobe_on:
    push r16
    push r17

    clr r16
    out DDRA, r16
    in r17, PINA 
    ori r17, 0b00000010
    ser r16
    out DDRA, r16
    out PORTA, r17

    pop r17
    pop r16

    ret