.equ LCD_RS         =   7       ;   Register Select
.equ LCD_RW         =   5       ;   Signal to select Read or Write
.equ LCD_E          =   6       ;   Enable - Operation start signal for data read/write
.equ LCD_BF         =   7       ;   Busy Flag (DB7)

; RS		RW			Operation
; 0			0			Instruction Register Write
; 0			1			Busy flag(DB7) and Address Counter(DB6:DB0) read
; 1			0			Data Register Write
; 1			1			Data Register Read