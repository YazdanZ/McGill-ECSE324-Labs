.data
.equ SW_MEMORY, 0xFF200040

.equ LED_MEMORY, 0xFF200000

.equ HEX_0_TO_3, 0xFF200020
.equ HEX_4_TO_5, 0xFF200030

DISPLAY_CODES: .byte 63, 6, 91, 79, 102, 109, 125, 7, 127, 103, 119, 127, 57, 63, 121, 113

.equ PUSH_BUTTON_DATA, 0xFF200050 

.text
.global _start

_start:
	B IOAPPLICATION

// Turn on LEDs corresponding to switches
// eg. 00000100 switches the 3rd LED on (index 2)
switch_to_LED:
	PUSH {LR}
	BL read_slider_switches_ASM
	BL write_LEDs_ASM
	POP {LR}
	BX LR

/*
* the state of the slider switches are
* mapped directly to the LEDs. Additionally, 
* the state of the last four slider switches
* SW3-SW0 are used to set the value of
* a number from 0-15. This number is displayed
* on a HEX display when the corresponding pushbutton
* is pressed. Slider switch SW9 clears all the HEX
* displays.
*/
IOAPPLICATION:
	// turns on LEDs based on switches
	BL switch_to_LED
	
	//create a constant-pool and load the value
	LDR R1, =#0x20F 
	AND R1, R0, R1 // isolate the 4 MSBs and SW9
		
	// turn on HEX4-HEX7
	MOV R0, #0xF0 // one-hot encoding for HEX4-HEX7
	BL HEX_flood_ASM // lightup HEX4-HEX7
		
	// turn HEX displays based on PBs and SWs
	BL read_PB_data_ASM
	BL HEX_write_ASM
	
	// clear HEX0-HEX3 if SW9 is on
	TST R1, #0x200 // check SW9
	MOVNE R0, #0xF // clear HEX0-HEX3
	BLNE HEX_clear_ASM
	
	B IOAPPLICATION 
	

/*
 * slider switches driver
 *
 * stores the values of the slider
 * switches in R0
 */
read_slider_switches_ASM:
	PUSH {R1} // calee-save convention
	LDR R1, =SW_MEMORY
	LDR R0, [R1]
	POP {R1}
	BX LR

/* LED driver
 * 
 * Write the value in R0 to
 * the memory location of the
 * LEDs to set the state (on/off)
 * of the LEDs
 *
 */
write_LEDs_ASM:
	PUSH {R1} // calee-save convention
	LDR R1, =LED_MEMORY
	STR R0, [R1]
	POP {R1}
	BX LR

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