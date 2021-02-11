.data

// Find the fibunacci of 25 (= x12511) 
IN: .word 25

.text
.global _start

_start:
	LDR R1, =IN
	LDR R1, [R1]
	BL FIB
	B END 	
	// Return value is stored in R0
	
FIB:
	CMP R1, #3 // R1 - 3 => CPSR
	BLT RETURN1
	B ELSE

RETURN1:
	MOV R0, #1
	BX LR

ELSE:
	PUSH {R1, LR} // Store LR and the current N 
	SUB R1, R1, #1 // --N
	BL FIB // stores FIB(n - 1) into R0
	PUSH {R0} // save the result onto the stack
	
	SUB R1, R1, #1 // N -= 2
	BL FIB // returns fib(n - 2) into R0
	
	POP {R1} // fib(n - 1) => R1
	ADD R0, R0, R1 // fib(n - 1) + fib(n - 2)
	POP {LR, R1}
	BX LR

END:
	B END