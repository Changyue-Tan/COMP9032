.macro QUEUE_ACESSES_PROLOGUE
	push YL
	push YH
    push ZL
	push ZH
	push r16
    push r17
    push r24
    push r25
.endmacro

.macro QUEUE_ACESSES_EPILOGUE
    pop r25
	pop r24
    pop r17
    pop r16
    pop ZH
	pop ZL
	pop YH
	pop YL
.endmacro

