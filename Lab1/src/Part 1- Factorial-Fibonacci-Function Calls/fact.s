.data

// Find the factorial of 10 (= x375f00) 
IN: .word 10

.text
.global _start

_start:
	LDR R1, =IN
	LDR R1, [R1]
	BL FACT
	B END 	
	// Return value is stored in R0
	
FACT:
	CMP R1, #2 // R1 - 2 => CPSR
	BLT RETURN1
	B ELSE

RETURN1:
	MOV R0, #1
	BX LR

ELSE:
	PUSH {R1, LR} // store current N and LR
	SUB R1, R1, #1 // --N
	BL FACT
	POP {LR, R1}
	MUL R0, R0, R1
	BX LR

END:
	B END
	