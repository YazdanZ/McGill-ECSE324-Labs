.data

.equ HEX_0_TO_3, 0xFF200020
.equ HEX_4_TO_5, 0xFF200030
DISPLAY_CODES: .byte 63, 6, 91, 79, 102, 109, 125, 7, 127, 103, 119, 127, 57, 63, 121, 113

.equ PUSH_BUTTON_DATA, 0xFF200050 
.equ A9_TIMER_LOAD, 0xFFFEC600

PB_int_flag:
	.word 0x0
TIM_int_flag:
	.word 0x0
	
.section .vectors, "ax"
B _start
B SERVICE_UND  // undefined instruction vector
B SERVICE_SVC  // software interrupt vector
B SERVICE_ABT_INST // aborted prefetch vector
B SERVICE_ABT_DATA // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ  // IRQ interrupt vector
B SERVICE_FIQ  // FIQ interrupt vector

.text
.global _start
_start:
	/* Set up stack pointers for IRQ and SVC processor modes */
	MOV R1, #0b11010010 // interrupts masked, MODE = IRQ
	MSR	CPSR_c, R1 // change to IRQ mode
	LDR	SP, =0xFFFFFFFF - 3 // set IRQ stack to A9 onchip memory

	/* Change to SVC (supervisor) mode with interrupts disabled */
	MOV R1, #0b11010011 // interrupts masked, MODE = SVC
	MSR CPSR, R1 // change to supervisor mode
	LDR SP, =0x3FFFFFFF - 3 // set SVC stack to top of DDR3 memory
	
	BL CONFIG_GIC // configure the ARM GIC

	// activate the interrupts for pushbutton
	MOV R1, #0XF
	BL enable_PB_INT_ASM
	
	// activate the interrupts for the A9 private timer
	LDR R0, =#2000000
	MOV R1, #6 // A=1, E=0, I=1
	LDR R2, =#0 // no prescaler
	BL ARM_TIM_config_ASM
	
	// enable IRQ interrupts in the processor
	MOV R0, #0b01010011 // IRQ unmasked, MODE = SVC
	MSR CPSR_c, R0

IDLE:
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
	
	B STOPWATCH

START_STOPWATCH:
	// we count in increments of 10ms
	LDR R0, =#2000000
	MOV R1, #7 // A=1, E=0, I=1
	LDR R2, =#0 // no prescaler
	BL ARM_TIM_config_ASM
	B STOPWATCH

STOP_STOPWATCH:
	// we count in increments of 10ms
	LDR R0, =#2000000
	MOV R1, #6 // A=1, E=0, I=1
	LDR R2, =#0 // no prescaler
	BL ARM_TIM_config_ASM
	
STOPWATCH:

	LDR R0, =PB_int_flag
	LDR R1, [R0]	
	MOV R2, #0
	
	// Start = PB0
	CMP R1, #1
	STREQ R2, [R0]
	BEQ START_STOPWATCH
	
	
	// Stop = PB1
	CMP R1, #2
	STREQ R2, [R0]
	BEQ STOP_STOPWATCH
	
	
	// Reset = PB2
	CMP R1, #4
	STREQ R2, [R0]
	BEQ RESET_STOPWATCH

	LDR R0, =TIM_int_flag
	LDR R1, [R0]
	CMP R1, #1
	STREQ R2, [R0]
	BEQ INC_STOPWATCH
	B STOPWATCH
	
INC_STOPWATCH:

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
	
	B STOPWATCH
	
/*--- Undefined instructions --------------------------------------*/
SERVICE_UND:
	B SERVICE_UND
/*--- Software interrupts ----------------------------------------*/
SERVICE_SVC:
	B SERVICE_SVC
/*--- Aborted data reads ------------------------------------------*/
SERVICE_ABT_DATA:
	B SERVICE_ABT_DATA
/*--- Aborted instruction fetch -----------------------------------*/
SERVICE_ABT_INST:
	B SERVICE_ABT_INST
	
/*--- IRQ ---------------------------------------------------------*/
SERVICE_IRQ:
	PUSH {R0-R7, LR}
	/* Read the ICCIAR from the CPU Interface */
	LDR R4, =0xFFFEC100
	LDR R5, [R4, #0x0C] // read from ICCIAR
	
Pushbutton_check:
	CMP R5, #73
	BNE Timer_check
	BL KEY_ISR
	B EXIT_IRQ
	
Timer_check:
	CMP R5, #29
UNEXPECTED:
	BNE UNEXPECTED 
	BL ARM_TIM_ISR
	
EXIT_IRQ:
	/* Write to the End of Interrupt Register (ICCEOIR) */
	STR R5, [R4, #0x10] // write to ICCEOIR
	POP {R0-R7, LR}
	SUBS PC, LR, #4

/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
	B SERVICE_FIQ

CONFIG_GIC:
	PUSH {LR}

	MOV R0, #73 // KEY port (Interrupt ID = 73)
	MOV R1, #1 // this field is a bit-mask; bit 0 target cpu0
	BL CONFIG_INTERRUPT

	MOV R0, #29 // Timer port (Interrupt ID = 29)
	MOV R1, #1 // this field is a bit-mask; bit 0 target cpu0
	BL CONFIG_INTERRUPT
	
	/* configure the GIC CPU Interface */
	LDR R0, =0xFFFEC100 // base address of CPU Interface
	/* Set Interrupt Priority Mask Register (ICCPMR) */
	LDR R1, =0xFFFF // enable interrupts of all priorities
	STR R1, [R0, #0x04]
	/* Set the enable bit in the CPU Interface Control Register (ICCICR).
	* This allows interrupts to be forwarded to the CPU(s) */
	MOV R1, #1
	STR R1, [R0]
	
	/* Set the enable bit in the Distributor Control Register (ICDDCR).
	* This enables forwarding of interrupts to the CPU Interface(s) */
	LDR R0, =0xFFFED000
	STR R1, [R0]
	POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default
(reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
	PUSH {R4-R5, LR}
	/* Configure Interrupt Set-Enable Registers (ICDISERn).
	* reg_offset = (integer_div(N / 32) * 4
	* value = 1 << (N mod 32) */
	LSR R4, R0, #3 // calculate reg_offset
	BIC R4, R4, #3 // R4 = reg_offset
	LDR R2, =0xFFFED100
	ADD R4, R2, R4 // R4 = address of ICDISER
	AND R2, R0, #0x1F // N mod 32
	MOV R5, #1 // enable
	LSL R2, R5, R2 // R2 = value

	/* Using the register address in R4 and the value in R2 set the
	* correct bit in the GIC register */
	LDR R3, [R4] // read current register value
	ORR R3, R3, R2 // set the enable bit
	STR R3, [R4] // store the new register value

	/* Configure Interrupt Processor Targets Register (ICDIPTRn)
	* reg_offset = integer_div(N / 4) * 4
	* index = N mod 4 */
	BIC R4, R0, #3 // R4 = reg_offset
	LDR R2, =0xFFFED800
	ADD R4, R2, R4 // R4 = word address of ICDIPTR
	AND R2, R0, #0x3 // N mod 4
	ADD R4, R2, R4 // R4 = byte address in ICDIPTR
	/* Using register address in R4 and the value in R2 write to
	* (only) the appropriate byte */
	STRB R1, [R4]
	POP {R4-R5, PC}
	
ARM_TIM_ISR:
	PUSH {LR}
	BL ARM_TIM_read_INT_ASM
	LDR R1, =TIM_int_flag
	TST R0, #1
	MOV R0, #0
	MOVNE R0, #1
	STR R0, [R1]
	BL ARM_TIM_clear_INT_ASM
	POP {LR}
	BX LR

KEY_ISR:
	PUSH {LR}
	BL read_PB_edgecp_ASM
	LDR R1, =PB_int_flag
	STR R0, [R1]
	BL PB_clear_edgecp_ASM
	POP {LR}
	BX LR

//----------------------------------------------------

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