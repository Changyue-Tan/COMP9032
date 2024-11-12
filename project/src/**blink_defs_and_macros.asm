/*
.def func = r16	;function 0 flash	;function 1 waiting time show
.def mode = r17	;differnent mode in function0
.def time = r18	;waiting time in function1
.def temp = r20
.def OUTDATA = r21
*/

;first r17: 1 second on then 1 second off
.macro	LED1
	; ldi r21, 0x03	;0x0C
	; out PORTG, r21
	ser r21
	out PORTC, r21
	sts PORTH, r21	;montor

	rcall sleep_1000ms
	; on/off
	;ldi r21, 0x00
	;out PORTG, r21
	ldi r21, 0x00
	out PORTC, r21
	ldi r21, 0x00
	sts PORTH, r21

	rcall sleep_1000ms
.endmacro

;second r17: 0.5s on then 0.5s off
.macro LED2
	ldi r21, 0x03
	out PORTG, r21
	ser r21
	out PORTC, r21
	sts PORTH, r21
	rcall sleep_500ms
	; on/off
	ldi r21, 0x00
	out PORTG, r21
	ldi r21, 0x00
	out PORTC, r21
	ldi r21, 0x00
	sts PORTH, r21
	rcall sleep_500ms
.endmacro

;third r17: 3second on then off
.macro LED3
	ldi r21, 0x03
	out PORTG, r21
	ser r21
	out PORTC, r21
	sts PORTH, r21
	rcall sleep_3000ms
	; on/off
	ldi r21, 0x00
	out PORTG, r21
	ldi r21, 0x00
	out PORTC, r21
	ldi r21, 0x00
	sts PORTH, r21
	rcall sleep_3000ms
.endmacro

