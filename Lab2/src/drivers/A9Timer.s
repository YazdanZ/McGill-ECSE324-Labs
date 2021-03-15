.data

.equ A9_TIMER_LOAD, 0xFFFEC600

.text

.global ARM_TIM_clear_INT_ASM
.global ARM_TIM_config_ASM
.global ARM_TIM_read_count_ASM
.global ARM_TIM_read_INT_ASM

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