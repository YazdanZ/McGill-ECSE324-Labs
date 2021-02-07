.global _start

// data section starts 
// section .data

// code section starts 
// section .text
_start:
	// find the fibunacci of 10 (55 = x37) 
	MOV R1, #10
	BL fib
	B end 	// return value is stored in R0
	
fib:
	CMP R1, #3 // R1 - 3 => CPSR
	BLT return1
	B else

return1:
	MOV R0, #1
	BX LR

else:
	PUSH {R1}
	
	SUB R1, R1, #1 // n = n - 1
	PUSH {LR}
	BL fib // returns fib(n - 1) into R0
	POP {LR}
	PUSH {R0} // save the result onto the stack
	
	SUB R1, R1, #1 // n = n - 2
	PUSH {LR}
	BL fib // returns fib(n - 2) into R0
	POP {LR}
	
	POP {R1} // fib(n - 1) => R1
	ADD R0, R0, R1 // fib(n - 1) + fib(n - 2)
	POP {R1}
	BX LR

.end