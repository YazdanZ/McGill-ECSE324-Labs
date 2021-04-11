.data
.equ PS2_DATA_REG, 0xFF200100
.equ PS2_CTR_REG, 0xFF200104

.text
.global read_PS2_data_ASM

/*
* PS/2 driver
*
* The subroutine will check the RVALID bit 
* in the PS/2 Data register. If valid, the 
* data from the register will be stored in 
* the pointer argument R0 and subroutine
* returns 1. If the RVALID bit is not set
* the subroutine returns 0.
*/
read_PS2_data_ASM:
	PUSH {R1, R2}
	LDR R1, =PS2_DATA_REG
	LDR R2, [R1]
	LDR R3, =0x8000 // 1 at the 15th bit
	ANDS R2, R3
	BEQ INVALID_read_PS2_data_ASM
	LDRB R2, [R1]
	STRB R2, [R0] // store in the pointer arg address
	MOV R0, #1
	B END_read_PS2_data_ASM
INVALID_read_PS2_data_ASM:
	MOV R0, #0
END_read_PS2_data_ASM:
	POP {R1, R2}
	BX LR