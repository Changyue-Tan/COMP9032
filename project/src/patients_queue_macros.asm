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

; initilise the two pointers:
; Last_Patient              -> Patients_Queue
; Next_Patient              -> Patients_Queue + 10
; Space_For_New_Patient     -> Patients_Queue + 10
; Last_Patient_Number       = 0
; Next_Patient_Number       = 1
.macro INITIALISE_QUEUE
    QUEUE_ACESSES_PROLOGUE

    ; Last_Patient              -> Patients_Queue
    ldi YL, low(Patients_Queue) 
	ldi YH, high(Patients_Queue)
    ldi ZL, low(Last_Patient) 
	ldi ZH, high(Last_Patient)
    st Z+, YL
    st Z, YH
    ; Next_Patient              -> Patients_Queue + 10
    ldi ZL, low(Next_Patient) 
	ldi ZH, high(Next_Patient)
    adiw YH:YL, 10
    st Z+, YL
    st Z, YH
    ; Space_For_New_Patient     -> Patients_Queue + 10
    ldi ZL, low(Space_For_New_Patient) 
	ldi ZH, high(Space_For_New_Patient)
    st Z+, YL
    st Z, YH
    ; set last and next patient number
    CLEAR_ONE_BYTE_IN_DATA_MEMORY          Last_Patient_Number
    CLEAR_ONE_BYTE_IN_DATA_MEMORY          Next_Patient_Number
    INCREMENT_ONE_BYTE_IN_DATA_MEMORY      Next_Patient_Number

    QUEUE_ACESSES_EPILOGUE
.endmacro

; add patinet stored at Patient_Name to the end of the queue
.macro ENQUEUE 
    QUEUE_ACESSES_PROLOGUE
    ; initialise char counter to be 10, we only load 10 chars
    ldi r16, 10

    enqueue_start:
        ; if char counter is 0, we have loaded all chars
        cpi r16, 0
        breq enqueue_end
        ; load a char of the patient name to r17
        ldi ZL, low(Patient_Name) 
        ldi ZH, high(Patient_Name)
        ld r17, Z+
        ; load the address of the Space_For_New_Patient to Y
        ldi YL, low(Space_For_New_Patient) 
        ldi YH, high(Space_For_New_Patient)
        ; store that char to this address
        st  Y, r17
        ; decreament the char counter
        dec r16
        ; Last_Patient and Space_For_New_Patient will be incremented by 10 at the end of loop
        INCREMENT_TWO_BYTE_IN_DATA_MEMORY Last_Patient
        INCREMENT_TWO_BYTE_IN_DATA_MEMORY Space_For_New_Patient
        rjmp enqueue_start

    enqueue_end:
        INCREMENT_ONE_BYTE_IN_DATA_MEMORY Last_Patient_Number

    QUEUE_ACESSES_EPILOGUE

.endmacro
 
; remove the next patient at the front of the queue
.macro DEQUEUE 
    QUEUE_ACESSES_PROLOGUE
    ldi r16, 10

    dequeue_start: 
        cpi r16, 0
        breq dequeue_end
        dec r16
        ; Next_Patient will be incremented by 10 at the end of loop
        INCREMENT_TWO_BYTE_IN_DATA_MEMORY Next_Patient
        rjmp dequeue_start
    
    dequeue_end:
        INCREMENT_ONE_BYTE_IN_DATA_MEMORY Next_Patient_Number
    
    QUEUE_ACESSES_EPILOGUE
.endmacro
