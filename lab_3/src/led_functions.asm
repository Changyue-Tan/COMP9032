setup_LED:
	ser			temp								; 
	out			DDRC,			temp					; set all bits of port C to output
	lsl			temp
	out			PORTC,			temp					
	ret

led_flash:
	com			r10
	out			PORTC,			r10
	rcall		sleep_625ms
	rjmp		led_flash