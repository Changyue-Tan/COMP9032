.include "m2560def.inc"

.include "patients_queue_macros.asm"
.include "data_memory_macros.asm"

.dseg

; for queue data structure
Patients_Queue:			.byte 2560		; max number of patients pay day: 255
Next_Patient:			.byte 2			; pointer to next patient
Last_Patient:			.byte 2			; pointer to last patient
Space_For_New_Patient:	.byte 2			; pointer to the next avaliable space to store newly enqueued patient
Next_Patient_Number:	.byte 1			; a number between 0 - 255
Last_Patient_Number:	.byte 1			; a number between 0 - 255

; the input from keypad is stored here
Patient_Name:			.byte 10		; a char array with length of 10

.cseg

start:
	rjmp main

.include "patients_queue_functions.asm"

main:
	rcall initialise_queue
	; ...
	; do something to get input from keypad
	; ...
	
	rcall enqueue 								; add patinet stored at Patient_Name to the end of the queue
	; Last_Patient_Number will be updated, can be used for the end of Entry Mode, when giving patient a number
	
	; ...
	; doctor is serving the next patient
	; ...

	rcall dequeue								; remove the next patient at the front of the queue
	; Next_Patient_Number will be updated, and can be used for display mode

