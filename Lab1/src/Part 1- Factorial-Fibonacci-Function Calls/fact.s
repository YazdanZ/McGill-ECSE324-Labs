.global _start

// data section starts 
// section .data

// code section starts 
// section .text
_start:
	// find the factorial of 5 (120 = x78) 
	MOV R1, #5
	BL fact
	B end 	// return value is stored in R0
	
fact:
	CMP R1, #2 // R1 - 2 => CPSR
	BLT return1
	B else

return1:
	MOV R0, #1
	BX LR

else:
	PUSH {R1} // store previous n
	SUB R1, R1, #1 // n = n - 1
	PUSH {LR}
	BL fact
	POP {LR}
	POP {R1}
	MUL R0, R0, R1
	BX LR

.end