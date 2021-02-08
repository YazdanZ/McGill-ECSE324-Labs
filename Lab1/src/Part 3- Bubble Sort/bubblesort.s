.data

ARRAY: .word -1, 23, 0, 12, -7
SIZE: .word 5

.text
.global bubblesort
.global _start

_start:
bubblesort:
	// save registers (callee-save convention)
	PUSH {R0-R7, LR}
	LDR R0, =SIZE
	LDR R0, [R0] // SIZE => R0
	LDR R1, =ARRAY // &ARRAY[0] => R1
	MOV R2, #0 // step => R2 

loop1: 
	MOV R3, #0 // i => R3 
	CMP R0, R2
	BLE end
	ADD R2, R2, #1
	
loop2: 
	SUB R4, R0, R2
	CMP R4, R3
	BLE iterate 
	ADD R7, R3, #1

	// *(ptr + i)
	LDR R4, [R1, R3, LSL#2]
	// *(ptr + i + 1)
	LDR R5, [R1, R7, LSL#2] 
	
	CMP R4, R5
	// swap if necessary 
	STRGT   R5,[R1,R3,LSL #2]   
    STRGT   R4,[R1,R7,LSL #2]  
	ADD R3, R3, #1
	B loop2
	
iterate:
	B loop1
	
end:
	// restore registers (callee-save convention)
	POP {R0-R7, PC}