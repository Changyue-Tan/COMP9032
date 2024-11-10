.def func = r16	;function 0 flash	;function 1 waiting time show
.def mode = r17	;differnent mode in function0
.def time = r18	;waiting time in function1
.def temp = r20
.def OUTDATA = r21


;first mode: 1 second on then 1 second off
.macro	LED1
	ldi OUTDATA, 0x03	;0x0C
	out PORTG, OUTDATA
	ser OUTDATA
	out PORTC, OUTDATA
	sts PORTH, OUTDATA	;montor

	rcall sleep_1000ms
	; on/off
	ldi OUTDATA, 0x00
	out PORTG, OUTDATA
	ldi OUTDATA, 0x00
	out PORTC, OUTDATA
	ldi OUTDATA, 0x00
	sts PORTH, OUTDATA

	rcall sleep_1000ms
.endmacro

;second mode: 0.5s on then 0.5s off
.macro LED2
	ldi OUTDATA, 0x03
	out PORTG, OUTDATA
	ser OUTDATA
	out PORTC, OUTDATA
	sts PORTH, OUTDATA
	rcall sleep_500ms
	; on/off
	ldi OUTDATA, 0x00
	out PORTG, OUTDATA
	ldi OUTDATA, 0x00
	out PORTC, OUTDATA
	ldi OUTDATA, 0x00
	sts PORTH, OUTDATA
	rcall sleep_500ms
.endmacro

;third mode: 3second on then off
.macro LED3
	ldi OUTDATA, 0x03
	out PORTG, OUTDATA
	ser OUTDATA
	out PORTC, OUTDATA
	sts PORTH, OUTDATA
	rcall sleep_3000ms
	; on/off
	ldi OUTDATA, 0x00
	out PORTG, OUTDATA
	ldi OUTDATA, 0x00
	out PORTC, OUTDATA
	ldi OUTDATA, 0x00
	sts PORTH, OUTDATA
	rcall sleep_3000ms
.endmacro

/*
.macro wait
	;time = (remaining time/consultation time) ¡Á 10)
	mov temp, @0	;transfer the waiting time in
	lsr temp	;divide by 2

	;decide which case to access by calculate waiting time
	;number = how many LED ON
	cpi temp, 10
	breq LED_10	;10 LED is on
	cpi temp, 9
	breq LED_9	;9 LED is on
	cpi temp, 8
	breq LED_8
	cpi temp, 7
	breq LED_7
	cpi temp, 6
	breq LED_6
	cpi temp, 5
	breq LED_5
	cpi temp, 4
	breq LED_4
	cpi temp, 3
	breq LED_3
	cpi temp, 2
	breq LED_2
	cpi temp, 1
	breq LED_1
	;else none is turned on
	ldi OUTDATA, 0x00
	out PORTG, OUTDATA
	out PORTC, OUTDATA
	jmp final

LED_10:	;10 LED is on
	ldi OUTDATA, 0x03	;bit 2, 3 corresponding to LED0 and LED1
	out PORTG, OUTDATA
	ser OUTDATA	;8 bit corresponding to LED2-9
	out PORTC, OUTDATA
	jmp final
LED_9:	;9 LED is on
	ldi OUTDATA, 0x03
	out PORTG, OUTDATA
	ldi OUTDATA, 0xFE;0b11111110
	out PORTC, OUTDATA
	jmp final
LED_8:
	ldi OUTDATA, 0x03
	out PORTG, OUTDATA
	ldi OUTDATA, 0xFC
	out PORTC, OUTDATA
	jmp final
LED_7:
	ldi OUTDATA, 0x03
	out PORTG, OUTDATA
	ldi OUTDATA, 0xF8
	out PORTC, OUTDATA
	jmp final
LED_6:
	ldi OUTDATA, 0x03
	out PORTG, OUTDATA
	ldi OUTDATA, 0xF0
	out PORTC, OUTDATA
	jmp final
LED_5:
	ldi OUTDATA, 0x03
	out PORTG, OUTDATA
	ldi OUTDATA, 0xE0
	out PORTC, OUTDATA
	jmp final
LED_4:
	ldi OUTDATA, 0x03
	out PORTG, OUTDATA
	ldi OUTDATA, 0xC0
	out PORTC, OUTDATA
	jmp final
LED_3:
	ldi OUTDATA, 0x03
	out PORTG, OUTDATA
	ldi OUTDATA, 0x80
	out PORTC, OUTDATA
	jmp final
LED_2:
	ldi OUTDATA, 0x03
	out PORTG, OUTDATA
	ldi OUTDATA, 0x00
	out PORTC, OUTDATA
	jmp final
LED_1:
	ldi OUTDATA,0x02; bit 1 LED0
	out PORTG,OUTDATA
	ldi OUTDATA,0x00
	out PORTC,OUTDATA
	jmp final
.endmacro
*/