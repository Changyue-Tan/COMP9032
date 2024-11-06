; keypad set up, executed only once
setup_keypad:
	push temp1
	ldi			temp1,			PORTLDIR				; 
	STS			DDRL,			temp1					; set high bits of port L to output, and low bits to input
	pop temp1
	ret

