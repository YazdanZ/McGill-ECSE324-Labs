.data
.equ LED_MEMORY, 0xFF200000

.text
.global write_LEDs_ASM

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