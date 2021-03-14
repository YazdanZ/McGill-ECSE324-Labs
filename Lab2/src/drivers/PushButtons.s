.data

.equ PUSH_BUTTON_DATA, 0xFF200050 

.text
.global PB_data_is_pressed_ASM
.global PB_edgecp_is_pressed_ASM
.global PB_clear_edgecp_ASM
.global read_PB_data_ASM
.global read_PB_edgecp_ASM
.global enable_PB_INT_ASM
.global disable_PB_INT_ASM


/*
* PushButton driver
* 
* returns the indices of the pressed 
* pushbuttons. Indices are encoded based 
* on a one-hot encoding scheme
*/
read_PB_data_ASM:
	LDR R0, =PUSH_BUTTON_DATA
	LDR R0, [R0] // read the value of the data register
	BX LR


/*
* PushButton driver
*
* receives pushbuttons indices and returns
* 0x00000001 when the corresponding push-
* button is pressed, 0 otherwise
*
*/
PB_data_is_pressed_ASM:
	PUSH {LR}
	BL read_PB_data_ASM // read pushbutton data
	AND R0, R0, R1 // AND the input and the PBdata
	CMP R0, R1
	MOVEQ R0, #1
	MOVNE R0, #0
	POP {LR}
	BX LR


/*
* PushButton driver
* 
* returns the indices of the PBs that
* have been pressed and then released
* (from the edgecapture register edgebit)
*/
read_PB_edgecp_ASM:
	LDR R0, =PUSH_BUTTON_DATA
	LDR R0, [R0, #12]
	BX LR


/*
* PushButton driver
*
* receives the pushbutton indices
* returns 0x00000001 when the corr-
* esponding pushbutton has been asserted
*/
PB_edgecp_is_pressed_ASM:
	PUSH {LR}
	BL read_PB_edgecp_ASM
	AND R0, R0, R1
	CMP R0, R1
	MOVEQ R0, #1
	MOVNE R0, #0
	POP {LR}
	BX LR


/*
* PushButton driver
*
* clear the PB edgecapture register
*/
PB_clear_edgecp_ASM:
	PUSH {R1, LR}
	BL read_PB_edgecp_ASM
	LDR R1, =PUSH_BUTTON_DATA
	STR R0, [R1, #12]
	POP {R1, LR}
	BX LR


/*
* PushButton driver
*
* receives PB indices as an arg
* and enables the interrupt fun-
* ction for the corresponding PBs
*/
enable_PB_INT_ASM: 
	PUSH {R2}
	LDR R2, =PUSH_BUTTON_DATA
	ADD R2, R2, #8 // interruptmask register
	LDR R0, [R2]
	ORR R0, R0, R1 // perform OR operation on the IMR
	STR R0, [R2]
	POP {R2}
	BX LR


/*
* PushButton driver
*
* receives PB indices as an arg
* and disables the interrupt fun-
* ction for the corresponding PBs
*/
disable_PB_INT_ASM:
	PUSH {R2}
	LDR R2, =PUSH_BUTTON_DATA
	ADD R2, R2, #8 // interruptmask register
	LDR R0, [R2]
	BIC R0, R0, R1 //perform bitclear operation on the IMR
	STR R0, [R2]
	POP {R2}
	BX LR