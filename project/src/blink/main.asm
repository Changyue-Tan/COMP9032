.include "m2560def.inc"
.include "blink_defs_and_macro.asm"

start:
	push r16
	push r17
	push r18
	push r20
	push r21

	;;initial port
	ser temp
	out DDRC, temp
	out DDRG, temp
	sts DDRH, temp


	ldi OUTDATA, 0x00
	out PORTC, OUTDATA
	out PORTG, OUTDATA
	sts PORTH, OUTDATA

mode2:	
	LED3	;third mode: 3second on then off

flash:
	;three flash mode 0-2

	LED1	;first mode: 1 second on then 1 second off
	LED1
	LED1
	LED1
	LED1
	jmp loop

loop:
	LED2	;second mode: 0.5s on then 0.5s off
	jmp loop

final:
	pop r16
	pop r17
	pop r18
	pop r20
	pop r21


.include "sleep_functions.asm"
