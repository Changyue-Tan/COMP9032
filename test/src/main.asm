.include "m2560def.inc"
.include "lcd_defs.asm"
.include "lcd_macros.asm"
;.include "keypad_defs.asm"

;.include "main.asm"
start:
	rcall		setup_LCD



.include "lcd_functions.asm"
;.include "led_functions.asm"
;.include "keypad_functions.asm"
.include "sleep_functions.asm"
