.data
.equ SW_MEMORY, 0xFF200040

.text
.global read_slider_switches_ASM

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