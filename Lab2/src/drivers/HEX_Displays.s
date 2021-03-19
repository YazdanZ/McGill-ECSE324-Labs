.data

.equ HEX_0_TO_3, 0xFF200020
.equ HEX_4_TO_5, 0xFF200030

DISPLAY_CODES: .byte 63, 6, 91, 79, 102, 109, 125, 7, 127, 103, 119, 127, 57, 63, 121, 113

.text
.global HEX_clear_ASM
.global HEX_flood_ASM
.global HEX_write_ASM
.global HEX_zero_ASM


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


/*
* HEX display driver
* 
* the subroutine receives the HEX
* display indices and an integer value
* between 0-15 through R1 and R2 registers. 
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

// -------------------------------------------------------

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