.data

.equ HEX_0_TO_3, 0xFF200020
.equ HEX_4_TO_5, 0xFF200030

DISPLAY_CODES: .byte 63, 6, 91, 79, 102, 109, 125, 7, 127, 103, 119, 127, 57, 63, 121, 113

.equ PUSH_BUTTON_DATA, 0xFF200050 

.equ A9_TIMER_LOAD, 0xFFFEC600

.text
.global _start

_start:
	//B SIMPLECOUNTER
	B POLLING_STOPWATCH

/*
* POLLING BASED STOPWATCH
*
* Use PB0, PB1, and PB2 are used to 
* start, stop and reset the stopwatch, 
* respectively. The stopwatch counts in
* increments of 10ms. HEX4-5, HEX2-3, HEX0-1
* correspond to minutes, seconds, and 
* milliseconds respectively
*/
POLLING_STOPWATCH:

RESET_STOPWATCH:
	// set all the displays to 0
	MOV R0, #0xFF // all 8 displays
	BL HEX_zero_ASM
		
	// milliseconds: HEX0 (R3), HEX1 (R4)
	MOV R3, #0
	MOV R4, #0
	
	// seconds: HEX2 (R5), HEX3 (R6)
	MOV R5, #0
	MOV R6, #0
	
	// minutes: HEX4 (R7), HEX5 (R8)
	MOV R7, #0
	MOV R8, #0
	
	B POLL_STOPWATCH

START_STOPWATCH:
	// we count in increments of 10ms
	LDR R0, =#2000000
	MOV R1, #3 // A=1, E=1 (start), I=0
	LDR R2, =#0 // no prescaler
	BL ARM_TIM_config_ASM
	B POLL_STOPWATCH

STOP_STOPWATCH:
	// we count in increments of 10ms
	LDR R0, =#2000000
	MOV R1, #0 // A=0, E=0 (start), I=0
	LDR R2, =#0 // no prescaler
	BL ARM_TIM_config_ASM
	
POLL_STOPWATCH:
	// Start = PB0
	MOV R1, #1
	BL PB_edgecp_is_pressed_ASM
	CMP R0, #1
	BLEQ PB_clear_edgecp_ASM
	BEQ START_STOPWATCH
	
	
	// Stop = PB1
	MOV R1, #2
	BL PB_edgecp_is_pressed_ASM
	CMP R0, #1
	BLEQ PB_clear_edgecp_ASM
	BEQ STOP_STOPWATCH
	
	
	// Reset = PB2
	MOV R1, #4
	BL PB_edgecp_is_pressed_ASM
	CMP R0, #1
	BLEQ PB_clear_edgecp_ASM
	BEQ RESET_STOPWATCH

	BL ARM_TIM_read_INT_ASM	
	CMP R0, #1 // check the "F" bit
	BEQ INC_STOPWATCH
	B POLL_STOPWATCH
	
INC_STOPWATCH:
	// clear interrupt bit "F"
	BL ARM_TIM_clear_INT_ASM
	
	ADD R3, R3, #1
	CMP R3, #10
	MOVEQ R3, #0
	ADDEQ R4, R4, #1
	
	CMP R4, #10
	MOVEQ R4, #0
	ADDEQ R5, R5, #1
	
	CMP R5, #10
	MOVEQ R5, #0
	ADDEQ R6, R6, #1
	
	CMP R6, #6 //1min = 60s
	MOVEQ R6, #0
	ADDEQ R7, R7, #1
	
	CMP R7, #10
	MOVEQ R7, #0
	ADDEQ R8, R8, #1
	
	CMP R8, #6
	
	// if we reached 60 mins
	BEQ RESET_STOPWATCH
	
DISPLAY_STOPWATCH:
	
	MOV R0, #1
	MOV R1, R3
	BL HEX_write_ASM
	
	MOV R0, #2
	MOV R1, R4
	BL HEX_write_ASM
	
	MOV R0, #4
	MOV R1, R5
	BL HEX_write_ASM

	MOV R0, #8
	MOV R1, R6
	BL HEX_write_ASM
	
	MOV R0, #16
	MOV R1, R7
	BL HEX_write_ASM

	MOV R0, #32
	MOV R1, R8
	BL HEX_write_ASM
	
	B POLL_STOPWATCH
	

/*
* SIMPLE COUNTER
*
* Counter application that counts
* from 0 to 15 (F) by increments of
* 1 seconds and resets back to 0
* when 15 (F) is reached 
* 
*/
SIMPLECOUNTER:
	// (clk freq = 200Mhz)
	LDR R0, =#200000000 // initial count value
	MOV R1, #3 // A=1, E=1, I=0
	LDR R2, =#0 // no prescaler
	BL ARM_TIM_config_ASM
	MOV R1, #0 // count value

POLL_SIMPLECOUNTER:	
	// write to HEX0 display 
	MOV R0, #1
	BL HEX_write_ASM
	BL ARM_TIM_read_INT_ASM	
	CMP R0, #1
	BEQ INC_SIMPLECOUNTER
	B POLL_SIMPLECOUNTER

INC_SIMPLECOUNTER:
	// increment counter
	ADD R1, R1, #1
	
	// reset counter if =16
	CMP R1, #16
	MOVEQ R1, #0
	
	// clear interrupt bit "F"
	BL ARM_TIM_clear_INT_ASM
	B POLL_SIMPLECOUNTER

/*
* HEX display driver
* 
* the subroutine turns off all the 
* segments of the HEX displays passed
* in the argument (R0) 
*/
HEX_clear_ASM:
	PUSH {R2, LR}
	
	MOV R2, #0x00 // = All segments turned off
	BL FIND_DISP

	POP {R2, LR}
	BX LR

/*
* HEX display driver
* 
* the subroutine turns on all the
* segments of the HEX displays passed 
* in the argument (R0) 
*/
HEX_flood_ASM:
	PUSH {R2, LR}
	
	MOV R2, #0X7F // = 8 (All sigments lit up)
	BL FIND_DISP
	
	POP {R2, LR}
	BX LR

/*
* HEX display driver
* 
* the subroutine receives the HEX
* display indices and an integer value
* between 0-15 through R0 and R1 registers. 
* based on the second argument (R1) value, 
* the subroutine will display the 
* corresponding HEXadecimal digit
*/
HEX_write_ASM:
	PUSH {R2, R3, LR}
	
	LDR R3, =DISPLAY_CODES
	LDRB R2, [R3, R1] // get the hex code
	BL FIND_DISP
	
	POP {R2, R3, LR}
	BX LR

/*
* HEX display driver
* 
* the subroutine turns on all the
* the HEX displays passed in
* the argument (R0) to 0
*/
HEX_zero_ASM:
	PUSH {R2, LR}
	
	MOV R2, #63 // = 0
	BL FIND_DISP
	
	POP {R2, LR}
	BX LR


FIND_DISP:
	PUSH {R3, R4}
	MOV R3, #1
	MOV R4, #0 
	
FIND_DISP_LOOP:
	TST R3, R0 // find the 1 bits of the input R0
	
	PUSH {LR}
	BLNE WRITE_TO_DISP
	POP {LR}
	
	CMP R4, #7 // we have 8 displays
	ADD R4, R4, #1
	BEQ END_FIND_DISP // if all display bits were checked
	
	LSL R3, R3, #1 // check the next bit
	B FIND_DISP_LOOP // check other display bits
	
END_FIND_DISP:
	POP {R3, R4}
	BX LR
	
WRITE_TO_DISP:
	PUSH {R5, R6}
	
	// get the right HEX display base address
	CMP R4, #3
	LDRLE R5, =HEX_0_TO_3
	LDRGT R5, =HEX_4_TO_5

	// find offset
	CMP R4, #3
	MOVLE R6, R4
	MOVGT R6, R4
	SUBGT R6, #4
	
	STRB R2, [R5, R6]
	
	POP {R5, R6}
	BX LR

//--------------------------------------------------

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


/*
* ARM A9 Private Timer driver
*
* configure the A9 timer
*/
ARM_TIM_config_ASM:
	PUSH {R3, LR}
	LDR R3, =A9_TIMER_LOAD
	STR R0, [R3] // set the initial count value
	
	// write to the control register
	ADD R3, R3, #8
	STRB R2, [R3, #1]
	STRB R1, [R3]
	
	POP {R3, LR}
	BX LR

/*
* ARM A9 Private Timer driver
*
* returns the "F" value from the ARM
* A9 private time interrupt status 
* register
*/
ARM_TIM_read_INT_ASM:
	LDR R0, =A9_TIMER_LOAD
	LDRB R0, [R0, #12]
	BX LR

/*
* ARM A9 Private Timer driver
*
* clears the "F" value from the ARM
* A9 private time interrupt status 
* register
*/
ARM_TIM_clear_INT_ASM:
	PUSH {R0, R1, LR}
	BL ARM_TIM_read_INT_ASM
	LDR R1, =A9_TIMER_LOAD
	STRB R0, [R1, #12]
	POP {R0, R1, LR}
	BX LR

/*
* ARM A9 Private Timer driver
*
* read the current count value
*/
ARM_TIM_read_count_ASM:
	LDR R0, =A9_TIMER_LOAD
	LDR R0, [R0, #4] // read the counter register
	BX LR